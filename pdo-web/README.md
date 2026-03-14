# PDO React Web App

This is the new React frontend for the PDO monitoring portal.

## Run locally

1. Install dependencies
```powershell
cd c:\Inventory\backend\pdo-web
npm install
```

2. Start the Node/Postgres backend separately
```powershell
cd c:\Inventory\backend
node .\server_postgres.js
```

3. Start the React app
```powershell
cd c:\Inventory\backend\pdo-web
npm run dev
```

The Vite dev server proxies `/api/*` to `http://localhost:8080`.
