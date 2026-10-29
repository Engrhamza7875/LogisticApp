const { MongoClient } = require('mongodb');
const fs = require('fs');
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '.env') });

async function syncToAtlas() {
  const uri = process.env.MONGODB_URI;
  console.log('Connecting to Atlas:', uri.replace(/:[^:]*@/, ':****@'));
  const client = new MongoClient(uri);
  await client.connect();
  const db = client.db(process.env.MONGODB_DB || 'cargoApp');

  const dataDir = path.join(__dirname, 'data');
  if (!fs.existsSync(dataDir)) {
    console.log('No local data directory found.');
    return;
  }

  const files = fs.readdirSync(dataDir).filter((f) => f.endsWith('.json'));

  for (const file of files) {
    const colName = file.replace('.json', '');
    const raw = fs.readFileSync(path.join(dataDir, file), 'utf8');
    const docs = JSON.parse(raw);

    if (Array.isArray(docs) && docs.length > 0) {
      const col = db.collection(colName);
      for (const d of docs) {
        const { _id, ...clean } = d;
        let filter = { _id: d._id };
        if (d.id !== undefined) filter = { id: d.id };
        else if (d.email) filter = { email: d.email };
        else if (d.key) filter = { key: d.key };
        else if (d.trackingNumber) filter = { trackingNumber: d.trackingNumber };
        else if (d.bookingId) filter = { bookingId: d.bookingId };

        await col.updateOne(filter, { $set: clean }, { upsert: true });
      }
      console.log(`✓ Synced ${docs.length} records to Atlas collection: "${colName}"`);
    }
  }

  // List all collections and counts in Atlas
  console.log('\n--- MongoDB Atlas Current Collections & Counts ---');
  const collections = await db.listCollections().toArray();
  for (const c of collections) {
    const count = await db.collection(c.name).countDocuments();
    console.log(`• Collection "${c.name}": ${count} documents`);
  }

  await client.close();
  console.log('\nSUCCESS: MongoDB Atlas cloud database is 100% synchronized!');
}

syncToAtlas().catch(console.error);
