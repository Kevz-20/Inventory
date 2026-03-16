const fs = require('fs');
const path = require('path');
const http = require('http');

const PORT = process.env.PORT || 8080;
const DATA_DIR = path.join(__dirname, 'data');
const DATA_FILE = path.join(DATA_DIR, 'sync_store.json');

function ensureStore() {
  if (!fs.existsSync(DATA_DIR)) {
    fs.mkdirSync(DATA_DIR, { recursive: true });
  }

  if (!fs.existsSync(DATA_FILE)) {
    fs.writeFileSync(
      DATA_FILE,
      JSON.stringify({ records: {}, received_batches: [] }, null, 2),
      'utf8',
    );
  }
}

function loadStore() {
  ensureStore();
  return JSON.parse(fs.readFileSync(DATA_FILE, 'utf8'));
}

function saveStore(store) {
  fs.writeFileSync(DATA_FILE, JSON.stringify(store, null, 2), 'utf8');
}

function sendJson(res, statusCode, payload) {
  const body = JSON.stringify(payload);
  res.writeHead(statusCode, {
    'Content-Type': 'application/json',
    'Content-Length': Buffer.byteLength(body),
  });
  res.end(body);
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

function isObject(value) {
  return value !== null && typeof value === 'object' && !Array.isArray(value);
}

function validatePayload(payload) {
  if (!isObject(payload)) return 'Payload must be a JSON object.';
  if (typeof payload.generated_at !== 'string') {
    return 'Missing generated_at.';
  }
  if (!isObject(payload.tables)) {
    return 'Missing tables object.';
  }
  if (!isObject(payload.counts)) {
    return 'Missing counts object.';
  }
  if (typeof payload.total_records !== 'number') {
    return 'Missing total_records.';
  }
  return null;
}

function applySync(payload) {
  const store = loadStore();
  const syncedIdsByTable = {};
  const serverIdsByTable = {};
  const batchSummary = {
    generated_at: payload.generated_at,
    received_at: new Date().toISOString(),
    counts: payload.counts,
    total_records: payload.total_records,
  };

  for (const [tableName, rows] of Object.entries(payload.tables)) {
    if (!Array.isArray(rows)) continue;

    if (!store.records[tableName]) {
      store.records[tableName] = {};
    }

    syncedIdsByTable[tableName] = [];
    serverIdsByTable[tableName] = {};

    for (const row of rows) {
      if (!isObject(row) || typeof row.id !== 'number') {
        continue;
      }

      const localId = row.id;
      const serverId =
        typeof row.server_id === 'string' && row.server_id.trim()
          ? row.server_id.trim()
          : `${tableName}_${localId}`;

      store.records[tableName][serverId] = {
        ...row,
        server_id: serverId,
        synced_at: new Date().toISOString(),
      };

      syncedIdsByTable[tableName].push(localId);
      serverIdsByTable[tableName][String(localId)] = serverId;
    }
  }

  store.received_batches.push(batchSummary);
  saveStore(store);

  return {
    success: true,
    message: 'Sync upload accepted.',
    synced_ids_by_table: syncedIdsByTable,
    server_ids_by_table: serverIdsByTable,
    synced_at: new Date().toISOString(),
  };
}

const server = http.createServer(async (req, res) => {
  try {
    if (req.method === 'GET' && req.url === '/health') {
      sendJson(res, 200, { ok: true, service: 'inventory-sync-backend' });
      return;
    }

    if (req.method === 'POST' && req.url === '/api/mobile/sync/upload') {
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

      const response = applySync(payload);
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

server.listen(PORT, () => {
  ensureStore();
  console.log(`Sync backend listening on http://localhost:${PORT}`);
});
