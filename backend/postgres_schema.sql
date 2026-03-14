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
