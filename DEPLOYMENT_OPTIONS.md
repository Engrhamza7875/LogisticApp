# SabCargo deployment

## Architecture

- Flutter app calls the SabCargo Express API.
- The API connects to MongoDB Atlas using a server-side `MONGODB_URI`.
- The Flutter app must never connect directly to MongoDB or contain Atlas credentials.

## Configure Atlas

1. In Atlas, open the cluster shown in your project and use **Connect > Drivers** to create or rotate a database user and copy the Node.js connection string.
2. In `backend/.env` (create it from `backend/.env.example`), set:
   ```env
   MONGODB_URI=mongodb+srv://<database-user>:<password>@<cluster-host>/cargoApp?retryWrites=true&w=majority&appName=SabCargo
   MONGODB_DB=cargoApp
   JWT_SECRET=<long-random-secret>
   ```
3. Ensure Atlas Network Access allows the backend host. Prefer the host's fixed outbound IP; avoid opening access to every IP in production.
4. Keep `.env` out of source control.

## Migrate existing SQL records

The migration copies records from the old SQL Server into Atlas without deleting or changing the source:

```powershell
Set-Location backend
npm install
npm run migrate:sql-to-mongo
```

The migration also needs the legacy `DB_USER`, `DB_PASSWORD`, `DB_SERVER`, `DB_PORT`, and `DB_NAME` values in `backend/.env`. It stops if an unrelated record with the same ID already exists in the destination. Back up and reconcile conflicting Atlas data before retrying. The script is safe to rerun for records it already marked as imported.

## Start and deploy the API

```powershell
Set-Location backend
npm start
```

Check `http://localhost:5000/api/health`; it should report `"database":"connected"`. Deploy the backend to a public HTTPS host and configure the MongoDB and JWT environment variables in that host's secret settings.

## Point the Flutter app at the API

Set the API URL (not the Atlas URL) at build time:

```powershell
flutter build apk --release --dart-define=BASE_URL=https://your-api-host/api
```

For local Android emulator testing, the existing default is `http://10.0.2.2:5000/api`.
