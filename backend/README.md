# Sync Backend

Minimal backend for the mobile sync flow.

## Run Test File Storage Backend

```powershell
node c:\Inventory\backend\server.js
```

Default URL:

```text
http://localhost:8080
```

## Run PostgreSQL Backend

1. Create a PostgreSQL database.
2. Apply the schema in:

`c:\Inventory\backend\postgres_schema.sql`

3. Install backend dependency:

```powershell
cd c:\Inventory\backend
npm install
```

4. Start the PostgreSQL server:

```powershell
$env:DATABASE_URL='postgresql://postgres:postgres@localhost:5432/inventory_sync'
node c:\Inventory\backend\server_postgres.js
```

## Endpoints

`GET /health`

Returns a simple health response.

`POST /api/mobile/sync/upload`

File-storage backend stores data in:

`c:\Inventory\backend\data\sync_store.json`

PostgreSQL backend stores data in:

- `sync_batches`
- `sync_records`

PDO monitoring endpoints:

- `GET /api/pdo/associations`
- `GET /api/pdo/associations/:serverId`
- `GET /api/pdo/activity`
- `GET /api/pdo/sync-status`
- `GET /api/pdo/session`
- `POST /api/pdo/login`
- `POST /api/pdo/logout`
- `GET /pdo/login`
- `GET /pdo`

Default PDO login:

- email: `pdo@inventory.local`
- password: `ChangeMe123!`

You can override these when starting the Postgres server:

```powershell
$env:PDO_DEFAULT_EMAIL='your@email.com'
$env:PDO_DEFAULT_PASSWORD='YourStrongPassword'
$env:PDO_DEFAULT_NAME='PDO Staff'
node c:\Inventory\backend\server_postgres.js
```

## Mobile App Config

Set this in:

`c:\Inventory\Inventory\lib\services\sync_backend_config.dart`

```dart
static const String baseUrl = 'http://10.0.2.2:8080';
```

Use `10.0.2.2` for Android emulator, or your PC LAN IP for a real phone.

## Response Shape

```json
{
  "success": true,
  "message": "Sync upload accepted.",
  "synced_ids_by_table": {
    "product": [1, 2]
  },
  "server_ids_by_table": {
    "product": {
      "1": "product_1",
      "2": "product_2"
    }
  },
  "synced_at": "2026-03-14T00:00:00.000Z"
}
```
