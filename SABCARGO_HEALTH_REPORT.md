# SabCargo database migration status

## Target architecture

The application uses MongoDB Atlas through the Node.js API. The Flutter client does not connect to Atlas directly. The backend requires `MONGODB_URI`, `MONGODB_DB`, and `JWT_SECRET` in its environment.

## Data migration

`backend/migrate_sql_to_mongodb.js` copies the legacy SQL collections into MongoDB collections, including users, OTPs, shipments, bookings, admins, settings, logs, services, and notifications. It leaves the source SQL database unchanged and refuses to overwrite unrelated records with matching IDs.

Run it only after a backup and after configuring both the legacy SQL connection settings and the Atlas URI in `backend/.env`:

```powershell
Set-Location backend
npm run migrate:sql-to-mongo
```

## Deployment checks

- Configure a rotated MongoDB database user's URI in backend secret settings; do not place credentials in the Flutter app or repository.
- Allow only the backend host's outbound IP in Atlas Network Access.
- Start the backend and verify `/api/health` reports a connected database.
- Configure the Flutter build with the backend's HTTPS API URL.
- Run the Flutter analyzer/tests and verify registration, sign-in, shipment booking, tracking events, and role-based shipment filtering against the configured Atlas database before release.

The Atlas connection and end-to-end migration have not been verified from this workspace because no new Atlas URI or legacy SQL connection was configured here.
