const http = require('http');
const crypto = require('crypto');
const fs = require('fs');
const path = require('path');
const { Pool } = require('pg');

const PORT = process.env.PORT || 8080;
const DATABASE_URL =
  process.env.DATABASE_URL ||
  'postgresql://postgres:postgres@localhost:5432/inventory_sync';

const pool = new Pool({
  connectionString: DATABASE_URL,
});

const DASHBOARD_FILE = path.join(__dirname, 'public', 'pdo_dashboard.html');
const LOGIN_FILE = path.join(__dirname, 'public', 'pdo_login.html');
const SESSION_COOKIE = 'pdo_session';
const SESSION_TTL_MS = 1000 * 60 * 60 * 12;
const sessions = new Map();

function sendJson(res, statusCode, payload) {
  const body = JSON.stringify(payload);
  res.writeHead(statusCode, {
    'Content-Type': 'application/json',
    'Content-Length': Buffer.byteLength(body),
  });
  res.end(body);
}

function redirect(res, location) {
  res.writeHead(302, { Location: location });
  res.end();
}

function readBody(req) {
  return new Promise((resolve, reject) => {
    let body = '';
    req.on('data', (chunk) => {
      body += chunk;
      if (body.length > 10 * 1024 * 1024) {
        reject(new Error('Request body too large'));
        req.destroy();
      }
    });
    req.on('end', () => resolve(body));
    req.on('error', reject);
  });
}

function sendHtml(res, statusCode, html) {
  const body = Buffer.from(html, 'utf8');
  res.writeHead(statusCode, {
    'Content-Type': 'text/html; charset=utf-8',
    'Content-Length': body.length,
  });
  res.end(body);
}

function readDashboardHtml() {
  return fs.readFileSync(DASHBOARD_FILE, 'utf8');
}

function readLoginHtml() {
  return fs.readFileSync(LOGIN_FILE, 'utf8');
}

function parseCookies(req) {
  const raw = req.headers.cookie || '';
  return raw.split(';').reduce((acc, part) => {
    const [key, ...rest] = part.trim().split('=');
    if (!key) return acc;
    acc[key] = decodeURIComponent(rest.join('='));
    return acc;
  }, {});
}

function setSessionCookie(res, token) {
  res.setHeader(
    'Set-Cookie',
    `${SESSION_COOKIE}=${encodeURIComponent(token)}; HttpOnly; Path=/; SameSite=Lax; Max-Age=${SESSION_TTL_MS / 1000}`,
  );
}

function clearSessionCookie(res) {
  res.setHeader(
    'Set-Cookie',
    `${SESSION_COOKIE}=; HttpOnly; Path=/; SameSite=Lax; Max-Age=0`,
  );
}

function isObject(value) {
  return value !== null && typeof value === 'object' && !Array.isArray(value);
}

function validatePayload(payload) {
  if (!isObject(payload)) return 'Payload must be a JSON object.';
  if (typeof payload.generated_at !== 'string') return 'Missing generated_at.';
  if (!isObject(payload.tables)) return 'Missing tables object.';
  if (!isObject(payload.counts)) return 'Missing counts object.';
  if (typeof payload.total_records !== 'number') return 'Missing total_records.';
  return null;
}

function hashPassword(password, salt = crypto.randomBytes(16).toString('hex')) {
  const derivedKey = crypto.scryptSync(password, salt, 64).toString('hex');
  return { salt, hash: derivedKey };
}

function verifyPassword(password, salt, expectedHash) {
  const { hash } = hashPassword(password, salt);
  const expected = Buffer.from(expectedHash, 'hex');
  const actual = Buffer.from(hash, 'hex');
  if (expected.length !== actual.length) return false;
  return crypto.timingSafeEqual(expected, actual);
}

function createSession(user) {
  const token = crypto.randomBytes(32).toString('hex');
  sessions.set(token, {
    userId: user.id,
    email: user.email,
    role: user.role,
    fullName: user.full_name,
    expiresAt: Date.now() + SESSION_TTL_MS,
  });
  return token;
}

function getSession(req) {
  const cookies = parseCookies(req);
  const token = cookies[SESSION_COOKIE];
  if (!token) return null;
  const session = sessions.get(token);
  if (!session) return null;
  if (session.expiresAt < Date.now()) {
    sessions.delete(token);
    return null;
  }
  session.expiresAt = Date.now() + SESSION_TTL_MS;
  return { token, ...session };
}

function requireAuth(req, res) {
  const session = getSession(req);
  if (!session) {
    sendJson(res, 401, {
      success: false,
      message: 'Authentication required.',
    });
    return null;
  }
  return session;
}

async function ensureSchema() {
  const schemaSql = `
    CREATE TABLE IF NOT EXISTS sync_batches (
      id BIGSERIAL PRIMARY KEY,
      generated_at TIMESTAMPTZ NOT NULL,
      received_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
      counts JSONB NOT NULL DEFAULT '{}'::jsonb,
      total_records INTEGER NOT NULL DEFAULT 0
    );

    CREATE TABLE IF NOT EXISTS sync_records (
      id BIGSERIAL PRIMARY KEY,
      batch_id BIGINT NOT NULL REFERENCES sync_batches(id) ON DELETE CASCADE,
      table_name TEXT NOT NULL,
      local_id BIGINT NOT NULL,
      server_id TEXT NOT NULL,
      row_data JSONB NOT NULL,
      synced_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
      UNIQUE (table_name, server_id)
    );

    CREATE INDEX IF NOT EXISTS idx_sync_records_table_name
      ON sync_records(table_name);

    CREATE INDEX IF NOT EXISTS idx_sync_records_local_id
      ON sync_records(table_name, local_id);

    CREATE TABLE IF NOT EXISTS pdo_users (
      id BIGSERIAL PRIMARY KEY,
      email TEXT NOT NULL UNIQUE,
      full_name TEXT NOT NULL,
      password_hash TEXT NOT NULL,
      password_salt TEXT NOT NULL,
      role TEXT NOT NULL DEFAULT 'pdo',
      is_active BOOLEAN NOT NULL DEFAULT TRUE,
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    );
  `;

  await pool.query(schemaSql);
  await ensureDefaultPdoUser();
}

async function ensureDefaultPdoUser() {
  const email = process.env.PDO_DEFAULT_EMAIL || 'pdo@inventory.local';
  const password = process.env.PDO_DEFAULT_PASSWORD || 'ChangeMe123!';
  const fullName = process.env.PDO_DEFAULT_NAME || 'PDO Staff';

  const existing = await pool.query(
    'SELECT id FROM pdo_users WHERE email = $1 LIMIT 1',
    [email],
  );
  if (existing.rows.length > 0) return;

  const credentials = hashPassword(password);
  await pool.query(
    `
    INSERT INTO pdo_users (email, full_name, password_hash, password_salt, role)
    VALUES ($1, $2, $3, $4, 'pdo')
    `,
    [email, fullName, credentials.hash, credentials.salt],
  );

  console.log('Created default PDO user:');
  console.log(`  email: ${email}`);
  console.log(`  password: ${password}`);
  console.log('Change these credentials for production use.');
}

async function applySync(payload) {
  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    const batchResult = await client.query(
      `
      INSERT INTO sync_batches (generated_at, counts, total_records)
      VALUES ($1, $2::jsonb, $3)
      RETURNING id, received_at
      `,
      [
        payload.generated_at,
        JSON.stringify(payload.counts ?? {}),
        payload.total_records ?? 0,
      ],
    );

    const batch = batchResult.rows[0];
    const syncedIdsByTable = {};
    const serverIdsByTable = {};

    for (const [tableName, rows] of Object.entries(payload.tables)) {
      if (!Array.isArray(rows)) continue;

      syncedIdsByTable[tableName] = [];
      serverIdsByTable[tableName] = {};

      for (const row of rows) {
        if (!isObject(row) || typeof row.id !== 'number') continue;

        const localId = row.id;
        const serverId =
          typeof row.server_id === 'string' && row.server_id.trim()
            ? row.server_id.trim()
            : `${tableName}_${localId}`;

        const rowData = {
          ...row,
          server_id: serverId,
          synced_at: new Date().toISOString(),
        };

        await client.query(
          `
          INSERT INTO sync_records (
            batch_id,
            table_name,
            local_id,
            server_id,
            row_data
          )
          VALUES ($1, $2, $3, $4, $5::jsonb)
          ON CONFLICT (table_name, server_id)
          DO UPDATE SET
            batch_id = EXCLUDED.batch_id,
            local_id = EXCLUDED.local_id,
            row_data = EXCLUDED.row_data,
            synced_at = NOW()
          `,
          [
            batch.id,
            tableName,
            localId,
            serverId,
            JSON.stringify(rowData),
          ],
        );

        syncedIdsByTable[tableName].push(localId);
        serverIdsByTable[tableName][String(localId)] = serverId;
      }
    }

    await client.query('COMMIT');

    return {
      success: true,
      message: 'Sync upload accepted.',
      synced_ids_by_table: syncedIdsByTable,
      server_ids_by_table: serverIdsByTable,
      synced_at: batch.received_at.toISOString(),
    };
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
}

async function getAssociationSummaries() {
  const query = `
    WITH latest_accounts AS (
      SELECT DISTINCT ON (server_id)
        server_id,
        row_data,
        synced_at
      FROM sync_records
      WHERE table_name = 'account'
      ORDER BY server_id, synced_at DESC, id DESC
    ),
    member_counts AS (
      SELECT
        row_data->>'account_id' AS account_id,
        COUNT(*)::int AS member_count
      FROM sync_records
      WHERE table_name = 'slpa_member'
        AND COALESCE((row_data->>'is_deleted')::int, 0) = 0
      GROUP BY row_data->>'account_id'
    )
    SELECT
      COALESCE(NULLIF(la.row_data->>'slpa_name', ''), 'Unnamed SLPA') AS slpa_name,
      (la.row_data->>'id')::int AS local_id,
      la.server_id,
      COALESCE(mc.member_count, 0) AS member_count,
      la.synced_at,
      la.row_data->>'mobile_number' AS mobile_number
    FROM latest_accounts la
    LEFT JOIN member_counts mc
      ON mc.account_id = la.row_data->>'id'
    WHERE COALESCE((la.row_data->>'is_deleted')::int, 0) = 0
    ORDER BY la.synced_at DESC, slpa_name ASC
  `;

  const result = await pool.query(query);
  return result.rows;
}

async function getAssociationDetails(serverId) {
  const accountResult = await pool.query(
    `
    SELECT server_id, row_data, synced_at
    FROM sync_records
    WHERE table_name = 'account' AND server_id = $1
    LIMIT 1
    `,
    [serverId],
  );

  if (accountResult.rows.length === 0) {
    return null;
  }

  const association = accountResult.rows[0];
  const accountLocalId = String(association.row_data.id);

  const [membersResult, activityResult] = await Promise.all([
    pool.query(
      `
      SELECT server_id, row_data, synced_at
      FROM sync_records
      WHERE table_name = 'slpa_member'
        AND row_data->>'account_id' = $1
        AND COALESCE((row_data->>'is_deleted')::int, 0) = 0
      ORDER BY synced_at DESC, id DESC
      `,
      [accountLocalId],
    ),
    pool.query(
      `
      SELECT server_id, row_data, synced_at
      FROM sync_records
      WHERE table_name = 'audit_log'
        AND row_data->>'account_id' = $1
      ORDER BY synced_at DESC, id DESC
      LIMIT 50
      `,
      [accountLocalId],
    ),
  ]);

  return {
    association,
    members: membersResult.rows,
    recent_activity: activityResult.rows,
  };
}

async function getMemberSummaries() {
  const query = `
    WITH latest_members AS (
      SELECT DISTINCT ON (server_id)
        server_id,
        row_data,
        synced_at
      FROM sync_records
      WHERE table_name = 'slpa_member'
      ORDER BY server_id, synced_at DESC, id DESC
    ),
    latest_accounts AS (
      SELECT DISTINCT ON ((row_data->>'id'))
        row_data->>'id' AS local_account_id,
        row_data->>'slpa_name' AS slpa_name
      FROM sync_records
      WHERE table_name = 'account'
      ORDER BY (row_data->>'id'), synced_at DESC, id DESC
    )
    SELECT
      lm.server_id,
      lm.row_data,
      lm.synced_at,
      COALESCE(NULLIF(la.slpa_name, ''), 'Unnamed SLPA') AS slpa_name
    FROM latest_members lm
    LEFT JOIN latest_accounts la
      ON la.local_account_id = lm.row_data->>'account_id'
    WHERE COALESCE((lm.row_data->>'is_deleted')::int, 0) = 0
    ORDER BY lm.synced_at DESC, lm.server_id ASC
  `;

  const result = await pool.query(query);
  return result.rows;
}

async function getRecentActivity(limit = 30) {
  const result = await pool.query(
    `
    SELECT server_id, row_data, synced_at
    FROM sync_records
    WHERE table_name = 'audit_log'
    ORDER BY synced_at DESC, id DESC
    LIMIT $1
    `,
    [limit],
  );

  return result.rows;
}

async function getSyncStatusSummary() {
  const [batchesResult, totalsResult] = await Promise.all([
    pool.query(
      `
      SELECT id, generated_at, received_at, counts, total_records
      FROM sync_batches
      ORDER BY received_at DESC, id DESC
      LIMIT 20
      `,
    ),
    pool.query(
      `
      SELECT
        table_name,
        COUNT(*)::int AS record_count,
        MAX(synced_at) AS last_synced_at
      FROM sync_records
      GROUP BY table_name
      ORDER BY table_name ASC
      `,
    ),
  ]);

  return {
    recent_batches: batchesResult.rows,
    table_totals: totalsResult.rows,
  };
}

async function resetSyncedTestData() {
  const client = await pool.connect();

  try {
    await client.query('BEGIN');
    await client.query('DELETE FROM sync_records');
    await client.query('DELETE FROM sync_batches');
    await client.query('COMMIT');
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
}

async function authenticatePdoUser(email, password) {
  const result = await pool.query(
    `
    SELECT id, email, full_name, password_hash, password_salt, role, is_active
    FROM pdo_users
    WHERE email = $1
    LIMIT 1
    `,
    [email.trim().toLowerCase()],
  );

  if (result.rows.length === 0) return null;
  const user = result.rows[0];
  if (!user.is_active) return null;
  if (!verifyPassword(password, user.password_salt, user.password_hash)) {
    return null;
  }
  return user;
}

const server = http.createServer(async (req, res) => {
  try {
    const url = new URL(req.url, `http://${req.headers.host || 'localhost'}`);

    if (req.method === 'GET' && url.pathname === '/health') {
      await pool.query('SELECT 1');
      sendJson(res, 200, {
        ok: true,
        service: 'inventory-sync-backend-postgres',
      });
      return;
    }

    if (req.method === 'GET' && url.pathname === '/pdo') {
      const session = getSession(req);
      if (!session) {
        redirect(res, '/pdo/login');
        return;
      }
      sendHtml(res, 200, readDashboardHtml());
      return;
    }

    if (req.method === 'GET' && url.pathname === '/pdo/login') {
      const session = getSession(req);
      if (session) {
        redirect(res, '/pdo');
        return;
      }
      sendHtml(res, 200, readLoginHtml());
      return;
    }

    if (req.method === 'GET' && url.pathname === '/api/pdo/session') {
      const session = getSession(req);
      sendJson(res, 200, {
        success: true,
        authenticated: Boolean(session),
        user: session
          ? {
              email: session.email,
              role: session.role,
              full_name: session.fullName,
            }
          : null,
      });
      return;
    }

    if (req.method === 'POST' && url.pathname === '/api/pdo/login') {
      const rawBody = await readBody(req);
      let payload;

      try {
        payload = JSON.parse(rawBody);
      } catch (_) {
        sendJson(res, 400, {
          success: false,
          message: 'Invalid JSON body.',
        });
        return;
      }

      const email = payload?.email?.toString() || '';
      const password = payload?.password?.toString() || '';
      if (!email.trim() || !password) {
        sendJson(res, 400, {
          success: false,
          message: 'Email and password are required.',
        });
        return;
      }

      const user = await authenticatePdoUser(email, password);
      if (!user) {
        sendJson(res, 401, {
          success: false,
          message: 'Invalid credentials.',
        });
        return;
      }

      const token = createSession(user);
      setSessionCookie(res, token);
      sendJson(res, 200, {
        success: true,
        user: {
          email: user.email,
          role: user.role,
          full_name: user.full_name,
        },
      });
      return;
    }

    if (req.method === 'POST' && url.pathname === '/api/pdo/logout') {
      const session = getSession(req);
      if (session) {
        sessions.delete(session.token);
      }
      clearSessionCookie(res);
      sendJson(res, 200, { success: true });
      return;
    }

    if (req.method === 'GET' && url.pathname === '/api/pdo/associations') {
      const session = requireAuth(req, res);
      if (!session) return;
      const associations = await getAssociationSummaries();
      sendJson(res, 200, { success: true, associations });
      return;
    }

    if (
      req.method === 'GET' &&
      url.pathname.startsWith('/api/pdo/associations/')
    ) {
      const session = requireAuth(req, res);
      if (!session) return;
      const serverId = decodeURIComponent(
        url.pathname.replace('/api/pdo/associations/', ''),
      );
      const details = await getAssociationDetails(serverId);

      if (!details) {
        sendJson(res, 404, {
          success: false,
          message: 'Association not found.',
        });
        return;
      }

      sendJson(res, 200, { success: true, ...details });
      return;
    }

    if (req.method === 'GET' && url.pathname === '/api/pdo/activity') {
      const session = requireAuth(req, res);
      if (!session) return;
      const rawLimit = Number(url.searchParams.get('limit') || '30');
      const limit = Number.isFinite(rawLimit)
        ? Math.max(1, Math.min(rawLimit, 500))
        : 30;
      const activity = await getRecentActivity(limit);
      sendJson(res, 200, { success: true, activity });
      return;
    }

    if (req.method === 'GET' && url.pathname === '/api/pdo/members') {
      const session = requireAuth(req, res);
      if (!session) return;
      const members = await getMemberSummaries();
      sendJson(res, 200, { success: true, members });
      return;
    }

    if (req.method === 'GET' && url.pathname === '/api/pdo/sync-status') {
      const session = requireAuth(req, res);
      if (!session) return;
      const summary = await getSyncStatusSummary();
      sendJson(res, 200, { success: true, ...summary });
      return;
    }

    if (
      req.method === 'POST' &&
      url.pathname === '/api/pdo/testing/reset-sync-data'
    ) {
      const session = requireAuth(req, res);
      if (!session) return;

      await resetSyncedTestData();
      sendJson(res, 200, {
        success: true,
        message: 'Synced testing data cleared.',
      });
      return;
    }

    if (req.method === 'POST' && url.pathname === '/api/mobile/sync/upload') {
      const rawBody = await readBody(req);
      let payload;

      try {
        payload = JSON.parse(rawBody);
      } catch (_) {
        sendJson(res, 400, {
          success: false,
          message: 'Invalid JSON body.',
        });
        return;
      }

      const validationError = validatePayload(payload);
      if (validationError) {
        sendJson(res, 400, {
          success: false,
          message: validationError,
        });
        return;
      }

      const response = await applySync(payload);
      sendJson(res, 200, response);
      return;
    }

    sendJson(res, 404, {
      success: false,
      message: 'Route not found.',
    });
  } catch (error) {
    sendJson(res, 500, {
      success: false,
      message: error.message || 'Internal server error.',
    });
  }
});

ensureSchema()
  .then(() => {
    server.listen(PORT, () => {
      console.log(`Postgres sync backend listening on http://localhost:${PORT}`);
      console.log(`PDO dashboard available at http://localhost:${PORT}/pdo`);
    });
  })
  .catch((error) => {
    console.error('Failed to start Postgres sync backend:', error);
    process.exit(1);
  });
