# SabCargo SQL-to-MongoDB migration

The running SabCargo API uses MongoDB Atlas. SQL Server is required only as the source for a one-time migration of existing records.

## Configure the Atlas destination

Create `backend/.env` from `backend/.env.example`. Set `MONGODB_URI` from Atlas **Connect > Drivers**, `MONGODB_DB=cargoApp`, and a strong `JWT_SECRET`. Keep the connection URI out of Flutter and source control.

## Configure the legacy SQL source

Set `DB_USER`, `DB_PASSWORD`, `DB_SERVER`, `DB_PORT`, and `DB_NAME` in `backend/.env`. These variables are used only by the migration script.

## Run the migration

Back up the SQL database first, then run:

```powershell
Set-Location backend
npm install
npm run migrate:sql-to-mongo
```

The script copies users, OTP records, shipments, admins, settings, logs, bookings, services, and notifications. It does not change or delete the SQL source. Before writing, it checks Atlas for conflicting records and stops rather than overwriting unrelated data. Imported records are marked so a migration can be safely rerun.

## Start and verify the API

```powershell
Set-Location backend
npm start
```

Open `http://localhost:5000/api/health`; it should report `"database":"connected"`. Startup requires a reachable Atlas cluster and valid MongoDB configuration.

## Atlas access checklist

- Use a dedicated database user with access only to `cargoApp`.
- Restrict Atlas Network Access to the backend host's outbound IP.
- Store `MONGODB_URI` and `JWT_SECRET` in backend environment or secret settings.
- Rotate any MongoDB credentials that were previously embedded in Flutter source.
