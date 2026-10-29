# SabCargo MongoDB Atlas deployment

SabCargo uses this connection path:

```text
Flutter app -> HTTPS Express API -> MongoDB Atlas
```

Do not put an Atlas URI or database password in Flutter, source control, or a public tunnel. The API owns the Atlas connection.

## 1. Configure the Atlas database

In MongoDB Atlas:

1. Select the cluster in the supplied project.
2. Create or rotate a database user with access to the `cargoApp` database.
3. Allow the deployed API host's outbound IP in Network Access.
4. Copy the Node.js driver URI from **Connect > Drivers**.

Create `backend/.env` from `backend/.env.example`, then set `MONGODB_URI`, `MONGODB_DB=cargoApp`, and a strong `JWT_SECRET`. Set SMTP values if the app needs email verification. Do not commit this file.

## 2. Copy the old SQL records

First back up the legacy SQL database. Add its connection values to `backend/.env`, then run:

```powershell
Set-Location backend
npm install
npm run migrate:sql-to-mongo
```

The migration copies users, OTPs, shipments, bookings, admins, settings, logs, services, and notifications. It does not delete or modify the SQL source. It stops on conflicting destination records rather than overwriting them.

## 3. Run and check the API

```powershell
Set-Location backend
npm start
```

Open `http://localhost:5000/api/health`. The API only starts when Atlas is reachable and the configured Mongo database responds to a ping.

## 4. Deploy and build

Deploy the backend to a host with HTTPS and set `MONGODB_URI`, `MONGODB_DB`, `JWT_SECRET`, and email settings through the host's secret/environment configuration.

Build the mobile app with the public API URL:

```powershell
flutter build apk --release --dart-define=BASE_URL=https://your-api-host/api
```

Never use the Atlas URI as `BASE_URL`; the app connects to the backend, not directly to the database.
