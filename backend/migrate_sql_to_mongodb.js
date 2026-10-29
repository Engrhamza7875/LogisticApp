const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '.env') });

const sql = require('mssql');
const { MongoClient } = require('mongodb');

function value(row, ...names) {
  const keys = Object.keys(row);
  for (const name of names) {
    const key = keys.find((candidate) => candidate.toLowerCase() === name.toLowerCase());
    if (key !== undefined) return row[key];
  }
  return undefined;
}

function parseJson(input, fallback) {
  if (input == null || input === '') return fallback;
  if (typeof input !== 'string') return input;
  try {
    return JSON.parse(input);
  } catch {
    return fallback;
  }
}

function bool(input, fallback = false) {
  return input == null ? fallback : Boolean(input);
}

function date(input) {
  return input ? new Date(input) : new Date();
}

function mapRow(row, table) {
  switch (table) {
    case 'Users':
      return {
        id: value(row, 'Id'),
        fullName: value(row, 'FullName', 'Name') || '',
        email: String(value(row, 'Email') || '').trim().toLowerCase(),
        phone: value(row, 'Phone') || '',
        pinHash: value(row, 'PinHash') || null,
        isVerified: bool(value(row, 'IsVerified')),
        photoBase64: value(row, 'PhotoBase64') || null,
        assignedOffice: value(row, 'AssignedOffice') || null,
        isActive: bool(value(row, 'IsActive'), true),
        createdAt: date(value(row, 'CreatedAt')),
      };
    case 'UserOtps':
      return {
        id: value(row, 'Id'),
        userId: value(row, 'UserId'),
        otpHash: value(row, 'OtpHash'),
        expiresAt: date(value(row, 'ExpiresAt')),
        used: bool(value(row, 'Used')),
        createdAt: date(value(row, 'CreatedAt')),
      };
    case 'Shipments':
      return {
        id: value(row, 'Id'),
        userId: value(row, 'UserId') ?? null,
        trackingNumber: value(row, 'TrackingNumber'),
        itemName: value(row, 'ItemName') || '',
        origin: value(row, 'Origin') || '',
        destination: value(row, 'Destination') || '',
        status: Number(value(row, 'Status') || 0),
        expectedDate: value(row, 'ExpectedDate') || '',
        weight: Number(value(row, 'Weight') || 0),
        type: value(row, 'Type') || '',
        senderName: value(row, 'SenderName') || '',
        receiverName: value(row, 'ReceiverName') || '',
        receiverPhone: value(row, 'ReceiverPhone') || '',
        totalAmount: Number(value(row, 'TotalAmount') || 0),
        steps: parseJson(value(row, 'StepsJson', 'Steps'), []),
        createdAt: date(value(row, 'CreatedAt')),
      };
    case 'Admins':
      return {
        id: String(value(row, 'Id') || ''),
        fullName: value(row, 'FullName') || '',
        email: String(value(row, 'Email') || '').trim().toLowerCase(),
        phone: value(row, 'Phone') || '',
        role: value(row, 'Role') || 'admin',
        branch: value(row, 'Branch') || '',
        isActive: bool(value(row, 'IsActive'), true),
        permissions: parseJson(value(row, 'PermissionsJson', 'Permissions'), []),
        createdAt: date(value(row, 'CreatedAt')),
      };
    case 'SystemSettings':
      return {
        key: value(row, 'SettingKey'),
        value: parseJson(value(row, 'SettingValue'), null),
        updatedAt: date(value(row, 'UpdatedAt')),
      };
    case 'SystemLogs':
      return {
        id: value(row, 'Id'),
        userEmail: value(row, 'UserEmail') || '',
        action: value(row, 'Action') || '',
        details: parseJson(value(row, 'Details'), value(row, 'Details') || ''),
        createdAt: date(value(row, 'CreatedAt')),
      };
    case 'Bookings':
      return {
        id: value(row, 'Id'),
        bookingId: value(row, 'BookingId'),
        userId: value(row, 'UserId') ?? null,
        itemName: value(row, 'ItemName') || '',
        cargoType: value(row, 'CargoType') || '',
        fromCity: value(row, 'FromCity') || '',
        toCity: value(row, 'ToCity') || '',
        senderName: value(row, 'SenderName') || '',
        receiverName: value(row, 'ReceiverName') || '',
        receiverPhone: value(row, 'ReceiverPhone') || '',
        weight: Number(value(row, 'Weight') || 0),
        total: Number(value(row, 'TotalAmount') || 0),
        createdAt: date(value(row, 'CreatedAt')),
      };
    case 'Services':
      return {
        id: value(row, 'Id'),
        name: value(row, 'ServiceName', 'Name') || '',
        description: value(row, 'Description') || '',
        iconCode: Number(value(row, 'IconCode') || 0),
        colorValue: Number(value(row, 'ColorValue') || 0),
        isActive: bool(value(row, 'IsActive'), true),
        createdAt: date(value(row, 'CreatedAt')),
      };
    case 'Notifications':
      return {
        id: value(row, 'Id'),
        title: value(row, 'Title') || '',
        body: value(row, 'Body') || '',
        sentBy: value(row, 'SentBy') || '',
        sentAt: date(value(row, 'SentAt')),
        targetRole: value(row, 'TargetRole') || 'All',
        targetUserEmail: value(row, 'TargetUserEmail') || null,
      };
    default:
      throw new Error(`Unsupported SQL table ${table}`);
  }
}

async function readCollection(source, table, collectionName) {
  const result = await source.request().query(`SELECT * FROM [${table}]`);
  const documents = result.recordset
    .map((row) => mapRow(row, table))
    .filter((document) => document.id != null || document.key != null);
  return {
    table,
    collectionName,
    key: table === 'SystemSettings' ? 'key' : 'id',
    documents,
  };
}

async function main() {
  if (!process.env.MONGODB_URI) {
    throw new Error('Set MONGODB_URI in backend/.env before running migration.');
  }
  const source = await sql.connect({
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    server: process.env.DB_SERVER,
    database: process.env.DB_NAME || 'SabCargoDB',
    port: Number(process.env.DB_PORT || 1433),
    options: {
      encrypt: String(process.env.DB_ENCRYPT || 'false').toLowerCase() === 'true',
      trustServerCertificate: true,
    },
  });
  const client = new MongoClient(process.env.MONGODB_URI);

  try {
    await client.connect();
    const database = client.db(process.env.MONGODB_DB || undefined);
    const tables = [
      ['Users', 'users'],
      ['UserOtps', 'userOtps'],
      ['Shipments', 'shipments'],
      ['Admins', 'admins'],
      ['SystemSettings', 'systemSettings'],
      ['SystemLogs', 'systemLogs'],
      ['Bookings', 'bookings'],
      ['Services', 'services'],
      ['Notifications', 'notifications'],
    ];

    const batches = [];
    for (const [table, collectionName] of tables) {
      batches.push(await readCollection(source, table, collectionName));
    }

    const users = batches.find((batch) => batch.table === 'Users')?.documents || [];
    const userEmails = new Map(
      users
        .map((user) => [String(user.id), user.email]),
    );
    for (const shipment of batches.find((batch) => batch.table === 'Shipments').documents) {
      shipment.userEmail = userEmails.get(String(shipment.userId)) || null;
    }

    for (const batch of batches) {
      const target = database.collection(batch.collectionName);
      for (const document of batch.documents) {
        const existing = await target.findOne({ [batch.key]: document[batch.key] });
        if (existing && existing.migrationSource !== 'legacy-sql') {
          throw new Error(
            `MongoDB collection "${batch.collectionName}" already has a conflicting record. ` +
            'Back up and reconcile existing data before running the migration.',
          );
        }
      }
    }

    for (const batch of batches) {
      if (batch.documents.length === 0) {
        console.log(`${batch.table}: no rows to migrate`);
        continue;
      }
      await database.collection(batch.collectionName).bulkWrite(
        batch.documents.map((document) => ({
          replaceOne: {
            filter: { [batch.key]: document[batch.key] },
            replacement: { ...document, migrationSource: 'legacy-sql' },
            upsert: true,
          },
        })),
        { ordered: false },
      );
      console.log(`${batch.table}: migrated ${batch.documents.length} rows`);
    }

    for (const name of ['users', 'userOtps', 'systemLogs', 'services', 'notifications']) {
      const maximum = await database.collection(name).find().sort({ id: -1 }).limit(1).next();
      if (maximum?.id) {
        await database.collection('counters').updateOne(
          { _id: name },
          { $max: { value: Number(maximum.id) } },
          { upsert: true },
        );
      }
    }
    console.log('SQL-to-MongoDB migration complete. Source SQL data was not modified.');
  } finally {
    await client.close();
    await source.close();
  }
}

main().catch((error) => {
  console.error('Migration failed:', error.message);
  process.exitCode = 1;
});
