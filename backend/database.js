const path = require('path');
const fs = require('fs');
const dns = require('dns');
const bcrypt = require('bcryptjs');
const { MongoClient } = require('mongodb');

// Ensure environment variables are loaded
require('dotenv').config({ path: path.join(__dirname, '.env') });

// Use Google and Cloudflare DNS to avoid local ISP blocks on SRV records
try {
  dns.setServers(['8.8.8.8', '1.1.1.1', '8.8.4.4']);
} catch (e) {
  // Non-fatal if system prevents setting custom DNS
}

let client;
let database;
let dbMode = 'uninitialized'; // 'mongodb-atlas' | 'local-fallback'

// Directory for local persistent storage fallback
const DATA_DIR = path.join(__dirname, 'data');
if (!fs.existsSync(DATA_DIR)) {
  fs.mkdirSync(DATA_DIR, { recursive: true });
}

// ==========================================
// Embedded Local MongoDB-compatible Engine
// ==========================================
class LocalCollection {
  constructor(name) {
    this.name = name;
    this.filePath = path.join(DATA_DIR, `${name}.json`);
    this.data = this._load();
  }

  _load() {
    try {
      if (fs.existsSync(this.filePath)) {
        const raw = fs.readFileSync(this.filePath, 'utf8');
        return JSON.parse(raw);
      }
    } catch (e) {
      console.warn(`[LocalDB] Error reading ${this.name}.json: ${e.message}`);
    }
    return [];
  }

  _save() {
    try {
      fs.writeFileSync(this.filePath, JSON.stringify(this.data, null, 2), 'utf8');
    } catch (e) {
      console.error(`[LocalDB] Error saving ${this.name}.json: ${e.message}`);
    }
  }

  _matches(doc, filter) {
    if (!filter || Object.keys(filter).length === 0) return true;

    for (const [key, expected] of Object.entries(filter)) {
      if (key === '$or' && Array.isArray(expected)) {
        if (!expected.some((subFilter) => this._matches(doc, subFilter))) return false;
        continue;
      }
      if (key === '$and' && Array.isArray(expected)) {
        if (!expected.every((subFilter) => this._matches(doc, subFilter))) return false;
        continue;
      }

      const val = doc[key];

      if (expected && typeof expected === 'object' && !(expected instanceof RegExp) && !(expected instanceof Date)) {
        for (const [op, opVal] of Object.entries(expected)) {
          if (op === '$eq' && val !== opVal) return false;
          if (op === '$ne' && val === opVal) return false;
          if (op === '$gt') {
            const v = val instanceof Date ? val.getTime() : (typeof val === 'string' && !isNaN(Date.parse(val)) ? Date.parse(val) : val);
            const target = opVal instanceof Date ? opVal.getTime() : (typeof opVal === 'string' && !isNaN(Date.parse(opVal)) ? Date.parse(opVal) : opVal);
            if (!(v > target)) return false;
          }
          if (op === '$gte') {
            const v = val instanceof Date ? val.getTime() : (typeof val === 'string' && !isNaN(Date.parse(val)) ? Date.parse(val) : val);
            const target = opVal instanceof Date ? opVal.getTime() : (typeof opVal === 'string' && !isNaN(Date.parse(opVal)) ? Date.parse(opVal) : opVal);
            if (!(v >= target)) return false;
          }
          if (op === '$lt') {
            const v = val instanceof Date ? val.getTime() : (typeof val === 'string' && !isNaN(Date.parse(val)) ? Date.parse(val) : val);
            const target = opVal instanceof Date ? opVal.getTime() : (typeof opVal === 'string' && !isNaN(Date.parse(opVal)) ? Date.parse(opVal) : opVal);
            if (!(v < target)) return false;
          }
          if (op === '$lte') {
            const v = val instanceof Date ? val.getTime() : (typeof val === 'string' && !isNaN(Date.parse(val)) ? Date.parse(val) : val);
            const target = opVal instanceof Date ? opVal.getTime() : (typeof opVal === 'string' && !isNaN(Date.parse(opVal)) ? Date.parse(opVal) : opVal);
            if (!(v <= target)) return false;
          }
          if (op === '$in' && Array.isArray(opVal) && !opVal.includes(val)) return false;
          if (op === '$nin' && Array.isArray(opVal) && opVal.includes(val)) return false;
          if (op === '$exists') {
            const exists = val !== undefined;
            if (exists !== Boolean(opVal)) return false;
          }
          if (op === '$regex') {
            const regex = new RegExp(opVal, expected.$options || '');
            if (!regex.test(String(val || ''))) return false;
          }
          if (op === '$type') {
            if (opVal === 'string' && typeof val !== 'string') return false;
            if (opVal === 'number' && typeof val !== 'number') return false;
          }
        }
      } else if (expected instanceof RegExp) {
        if (!expected.test(String(val || ''))) return false;
      } else {
        if (String(val) !== String(expected) && val !== expected) return false;
      }
    }
    return true;
  }

  find(filter = {}, options = {}) {
    let results = this.data.filter((doc) => this._matches(doc, filter)).map((d) => ({ ...d }));

    const cursor = {
      _results: results,
      sort(sortObj) {
        if (sortObj) {
          const [key, order] = Object.entries(sortObj)[0] || [];
          if (key) {
            cursor._results.sort((a, b) => {
              const valA = a[key];
              const valB = b[key];
              if (valA < valB) return order === -1 ? 1 : -1;
              if (valA > valB) return order === -1 ? -1 : 1;
              return 0;
            });
          }
        }
        return cursor;
      },
      limit(n) {
        if (typeof n === 'number' && n > 0) {
          cursor._results = cursor._results.slice(0, n);
        }
        return cursor;
      },
      skip(n) {
        if (typeof n === 'number' && n > 0) {
          cursor._results = cursor._results.slice(n);
        }
        return cursor;
      },
      async toArray() {
        return cursor._results;
      },
      async next() {
        return cursor._results.shift() || null;
      },
      async *[Symbol.asyncIterator]() {
        for (const item of cursor._results) {
          yield item;
        }
      },
    };
    return cursor;
  }

  async findOne(filter = {}, options = {}) {
    const doc = this.data.find((d) => this._matches(d, filter));
    return doc ? { ...doc } : null;
  }

  async insertOne(doc) {
    const toInsert = {
      _id: doc._id || `id_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`,
      ...doc,
    };
    this.data.push(toInsert);
    this._save();
    return { acknowledged: true, insertedId: toInsert._id };
  }

  async insertMany(docs) {
    const insertedIds = {};
    const toInsert = docs.map((doc, idx) => {
      const item = {
        _id: doc._id || `id_${Date.now()}_${idx}_${Math.random().toString(36).substring(2, 7)}`,
        ...doc,
      };
      insertedIds[idx] = item._id;
      return item;
    });
    this.data.push(...toInsert);
    this._save();
    return { acknowledged: true, insertedCount: toInsert.length, insertedIds };
  }

  _applyUpdate(target, update) {
    if (update.$set) {
      Object.assign(target, update.$set);
    }
    if (update.$inc) {
      for (const [k, v] of Object.entries(update.$inc)) {
        target[k] = (Number(target[k]) || 0) + Number(v);
      }
    }
    if (update.$setOnInsert && target._isNew) {
      delete target._isNew;
      Object.assign(target, update.$setOnInsert);
    }
    // Simple update without operators
    if (!update.$set && !update.$inc && !update.$setOnInsert) {
      Object.assign(target, update);
    }
  }

  async updateOne(filter, update, options = {}) {
    let index = this.data.findIndex((d) => this._matches(d, filter));
    if (index !== -1) {
      this._applyUpdate(this.data[index], update);
      this._save();
      return { acknowledged: true, matchedCount: 1, modifiedCount: 1, upsertedCount: 0 };
    }
    if (options.upsert) {
      const newDoc = {
        _id: `id_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`,
        ...filter,
        _isNew: true,
      };
      this._applyUpdate(newDoc, update);
      delete newDoc._isNew;
      this.data.push(newDoc);
      this._save();
      return { acknowledged: true, matchedCount: 0, modifiedCount: 0, upsertedCount: 1, upsertedId: newDoc._id };
    }
    return { acknowledged: true, matchedCount: 0, modifiedCount: 0, upsertedCount: 0 };
  }

  async replaceOne(filter, replacement, options = {}) {
    let index = this.data.findIndex((d) => this._matches(d, filter));
    if (index !== -1) {
      const _id = this.data[index]._id;
      this.data[index] = { _id, ...replacement };
      this._save();
      return { acknowledged: true, matchedCount: 1, modifiedCount: 1 };
    }
    if (options.upsert) {
      const newDoc = {
        _id: `id_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`,
        ...replacement,
      };
      this.data.push(newDoc);
      this._save();
      return { acknowledged: true, matchedCount: 0, modifiedCount: 0, upsertedCount: 1, upsertedId: newDoc._id };
    }
    return { acknowledged: true, matchedCount: 0, modifiedCount: 0 };
  }

  async updateMany(filter, update) {
    let modified = 0;
    for (const doc of this.data) {
      if (this._matches(doc, filter)) {
        this._applyUpdate(doc, update);
        modified++;
      }
    }
    if (modified > 0) this._save();
    return { acknowledged: true, matchedCount: modified, modifiedCount: modified };
  }

  async deleteOne(filter) {
    const index = this.data.findIndex((d) => this._matches(d, filter));
    if (index !== -1) {
      this.data.splice(index, 1);
      this._save();
      return { acknowledged: true, deletedCount: 1 };
    }
    return { acknowledged: true, deletedCount: 0 };
  }

  async deleteMany(filter) {
    const initialLen = this.data.length;
    this.data = this.data.filter((d) => !this._matches(d, filter));
    const deletedCount = initialLen - this.data.length;
    if (deletedCount > 0) this._save();
    return { acknowledged: true, deletedCount };
  }

  async findOneAndUpdate(filter, update, options = {}) {
    let index = this.data.findIndex((d) => this._matches(d, filter));
    if (index !== -1) {
      this._applyUpdate(this.data[index], update);
      this._save();
      return { value: { ...this.data[index] } };
    }
    if (options.upsert) {
      const newDoc = {
        _id: filter._id || `id_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`,
        ...filter,
        _isNew: true,
      };
      this._applyUpdate(newDoc, update);
      delete newDoc._isNew;
      this.data.push(newDoc);
      this._save();
      return { value: { ...newDoc } };
    }
    return { value: null };
  }

  async countDocuments(filter = {}) {
    return this.data.filter((d) => this._matches(d, filter)).length;
  }

  async distinct(field, filter = {}) {
    const matched = this.data.filter((d) => this._matches(d, filter));
    const unique = new Set();
    for (const doc of matched) {
      if (doc[field] !== undefined && doc[field] !== null && doc[field] !== '') {
        unique.add(doc[field]);
      }
    }
    return Array.from(unique);
  }

  aggregate(pipeline = []) {
    let current = [...this.data];
    for (const stage of pipeline) {
      if (stage.$match) {
        current = current.filter((d) => this._matches(d, stage.$match));
      } else if (stage.$group) {
        const idExpr = stage.$group._id;
        const groups = {};
        for (const item of current) {
          let groupId;
          if (idExpr && typeof idExpr === 'object' && idExpr.$dateToString) {
            const dateVal = item[idExpr.$dateToString.date.replace('$', '')];
            const d = dateVal ? new Date(dateVal) : new Date();
            groupId = d.toISOString().split('T')[0];
          } else if (typeof idExpr === 'string' && idExpr.startsWith('$')) {
            groupId = item[idExpr.slice(1)];
          } else {
            groupId = idExpr;
          }
          const groupKey = String(groupId);
          if (!groups[groupKey]) {
            groups[groupKey] = { _id: groupId, count: 0 };
          }
          groups[groupKey].count++;
        }
        current = Object.values(groups);
      } else if (stage.$sort) {
        const [field, dir] = Object.entries(stage.$sort)[0] || [];
        if (field) {
          current.sort((a, b) => (dir === -1 ? (a[field] < b[field] ? 1 : -1) : (a[field] > b[field] ? 1 : -1)));
        }
      }
    }
    return {
      async toArray() {
        return current;
      },
    };
  }

  async createIndex() {
    return 'index_created';
  }
}

class LocalDatabase {
  constructor(name = 'cargoApp') {
    this.databaseName = name;
    this.collections = new Map();
  }

  collection(name) {
    if (!this.collections.has(name)) {
      this.collections.set(name, new LocalCollection(name));
    }
    return this.collections.get(name);
  }

  async command(cmd) {
    if (cmd.ping) return { ok: 1 };
    return { ok: 1 };
  }

  getMode() {
    return 'local-fallback';
  }
}

// ==========================================
// Default Seeds Generator
// ==========================================
async function seedDefaultData(db) {
  try {
    const usersCol = db.collection('users');
    const adminsCol = db.collection('admins');
    const servicesCol = db.collection('services');
    const shipmentsCol = db.collection('shipments');
    const settingsCol = db.collection('systemSettings');
    const countersCol = db.collection('counters');

    const defaultPinHash = await bcrypt.hash('123456', 10);

    // 1. SuperAdmin User & Admin
    const superAdminEmail = 'admin@sabcargo.com';
    const existingAdmin = await adminsCol.findOne({ email: superAdminEmail });
    if (!existingAdmin) {
      await adminsCol.insertOne({
        id: '1',
        fullName: 'Super Admin',
        email: superAdminEmail,
        phone: '+971 50 123 4567',
        role: 'superAdmin',
        branch: 'Dubai Central',
        isActive: true,
        permissions: ['all', 'manage_admins', 'manage_shipments', 'manage_users', 'view_analytics'],
        createdAt: new Date(),
      });
      await usersCol.updateOne(
        { email: superAdminEmail },
        {
          $set: {
            id: 1,
            fullName: 'Super Admin',
            email: superAdminEmail,
            phone: '+971 50 123 4567',
            pinHash: defaultPinHash,
            isVerified: true,
            isActive: true,
            role: 'SuperAdmin',
            assignedOffice: 'Dubai Central',
            updatedAt: new Date(),
          },
          $setOnInsert: { createdAt: new Date() },
        },
        { upsert: true }
      );
      console.log('✓ Seeded default Super Admin (admin@sabcargo.com / PIN: 123456)');
    }

    // 2. Office Admins
    const officeAdmins = [
      { id: '2', name: 'Karachi Hub Admin', email: 'karachi@sabcargo.com', branch: 'Karachi Port', phone: '+92 21 3456 7890' },
      { id: '3', name: 'London Hub Admin', email: 'london@sabcargo.com', branch: 'London Heathrow', phone: '+44 20 7946 0912' },
      { id: '4', name: 'Dubai Branch Admin', email: 'office@sabcargo.com', branch: 'Dubai Central', phone: '+971 4 222 3344' },
    ];
    for (const oa of officeAdmins) {
      const exists = await adminsCol.findOne({ email: oa.email });
      if (!exists) {
        await adminsCol.insertOne({
          id: oa.id,
          fullName: oa.name,
          email: oa.email,
          phone: oa.phone,
          role: 'admin',
          branch: oa.branch,
          isActive: true,
          permissions: ['manage_shipments', 'manage_users'],
          createdAt: new Date(),
        });
        await usersCol.updateOne(
          { email: oa.email },
          {
            $set: {
              id: Number(oa.id),
              fullName: oa.name,
              email: oa.email,
              phone: oa.phone,
              pinHash: defaultPinHash,
              isVerified: true,
              isActive: true,
              role: 'Admin',
              assignedOffice: oa.branch,
              updatedAt: new Date(),
            },
            $setOnInsert: { createdAt: new Date() },
          },
          { upsert: true }
        );
      }
    }

    // 3. Demo Driver & Regular User
    const demoUser = await usersCol.findOne({ email: 'user@sabcargo.com' });
    if (!demoUser) {
      await usersCol.insertOne({
        id: 10,
        fullName: 'Hamza Ahmad',
        email: 'user@sabcargo.com',
        phone: '+92 300 9876543',
        pinHash: defaultPinHash,
        isVerified: true,
        isActive: true,
        role: 'User',
        assignedOffice: 'Dubai Central',
        createdAt: new Date(),
      });
      console.log('✓ Seeded demo user (user@sabcargo.com / PIN: 123456)');
    }

    const demoDriver = await usersCol.findOne({ email: 'driver@sabcargo.com' });
    if (!demoDriver) {
      await usersCol.insertOne({
        id: 11,
        fullName: 'Rashid Driver',
        email: 'driver@sabcargo.com',
        phone: '+971 55 987 6543',
        pinHash: defaultPinHash,
        isVerified: true,
        isActive: true,
        role: 'Driver',
        assignedOffice: 'Dubai Central',
        createdAt: new Date(),
      });
    }

    // 4. Default Cargo Services
    const serviceCount = await servicesCol.countDocuments();
    if (serviceCount === 0) {
      const defaultServices = [
        { id: 1, name: 'Air Cargo', description: 'Fast priority air transport for urgent freight', iconCode: 0xe060, colorValue: 0xFF4F46E5, isActive: true },
        { id: 2, name: 'Ocean Freight', description: 'Cost-effective global sea container shipping', iconCode: 0xe1fa, colorValue: 0xFF0284C7, isActive: true },
        { id: 3, name: 'Road Express', description: 'Overland interstate freight & parcel delivery', iconCode: 0xe3e3, colorValue: 0xFF059669, isActive: true },
        { id: 4, name: 'Warehousing & Storage', description: 'Secure temperature-controlled logistics storage', iconCode: 0xe6e0, colorValue: 0xFFD97706, isActive: true },
        { id: 5, name: 'Door-to-Door Courier', description: 'Last-mile express direct to receiver address', iconCode: 0xe566, colorValue: 0xFFDC2626, isActive: true },
      ];
      await servicesCol.insertMany(defaultServices.map((s) => ({ ...s, createdAt: new Date() })));
      console.log('✓ Seeded default Cargo Services');
    }

    // 5. Default System Settings
    const officesSetting = await settingsCol.findOne({ key: 'officeLocations' });
    if (!officesSetting) {
      await settingsCol.insertOne({
        key: 'officeLocations',
        value: ['Dubai Central', 'London Heathrow', 'Karachi Port', 'New York Hub', 'Riyadh Express'],
        updatedAt: new Date(),
      });
    }

    const rulesSetting = await settingsCol.findOne({ key: 'globalRules' });
    if (!rulesSetting) {
      await settingsCol.insertOne({
        key: 'globalRules',
        value: { maxWeightKg: 1000, expressSurcharge: 15.0, standardInsurancePct: 2.5 },
        updatedAt: new Date(),
      });
    }

    // 6. Sample Shipments
    const shipmentCount = await shipmentsCol.countDocuments();
    if (shipmentCount === 0) {
      const now = new Date();
      const sampleShipments = [
        {
          id: 'SAB-78210',
          trackingNumber: 'SAB-78210',
          userId: 10,
          userEmail: 'user@sabcargo.com',
          itemName: 'Precision Electronic Sensors',
          origin: 'Dubai Central',
          destination: 'London Heathrow',
          status: 2, // In Transit
          expectedDate: new Date(now.getTime() + 3 * 86400000).toLocaleDateString('en-GB'),
          weight: 14.5,
          type: 'Air Cargo',
          senderName: 'SabCargo Tech Ltd',
          receiverName: 'UK Robotics Corp',
          receiverPhone: '+44 20 7123 4567',
          totalAmount: 480.0,
          branchId: 'Dubai Central',
          steps: [
            { title: 'Booking Confirmed', subtitle: 'Shipment registered in Dubai Hub', time: '18/10/2026, 09:30', isCompleted: true, isCurrent: false },
            { title: 'Processed at Facility', subtitle: 'Security scan and customs clearance verified', time: '19/10/2026, 14:15', isCompleted: true, isCurrent: false },
            { title: 'In Transit', subtitle: 'Flight departing DXB to LHR', time: '20/10/2026, 04:00', isCompleted: true, isCurrent: true },
            { title: 'Out For Delivery', subtitle: 'Courier scheduled for local drop', time: 'Estimated: 24/10/2026', isCompleted: false, isCurrent: false },
            { title: 'Delivered', subtitle: 'Signed by recipient', time: 'Pending', isCompleted: false, isCurrent: false },
          ],
          createdAt: now,
        },
        {
          id: 'SAB-44912',
          trackingNumber: 'SAB-44912',
          userId: 10,
          userEmail: 'user@sabcargo.com',
          itemName: 'Medical Diagnostic Test Kits',
          origin: 'Karachi Port',
          destination: 'Dubai Central',
          status: 3, // Out for delivery
          expectedDate: new Date(now.getTime() + 1 * 86400000).toLocaleDateString('en-GB'),
          weight: 8.2,
          type: 'Door-to-Door Courier',
          senderName: 'BioHealth Labs Karachi',
          receiverName: 'Emirates Hospital Supply',
          receiverPhone: '+971 4 333 4444',
          totalAmount: 195.0,
          branchId: 'Karachi Port',
          steps: [
            { title: 'Booking Confirmed', subtitle: 'Picked up from facility in Karachi', time: '17/10/2026, 11:00', isCompleted: true, isCurrent: false },
            { title: 'Processed at Hub', subtitle: 'Customs cleared & sorted', time: '18/10/2026, 16:30', isCompleted: true, isCurrent: false },
            { title: 'In Transit', subtitle: 'Arrived at Dubai Distribution Center', time: '19/10/2026, 22:45', isCompleted: true, isCurrent: false },
            { title: 'Out For Delivery', subtitle: 'Assigned to courier van #12', time: '21/10/2026, 08:00', isCompleted: true, isCurrent: true },
            { title: 'Delivered', subtitle: 'Package handed over', time: 'Pending', isCompleted: false, isCurrent: false },
          ],
          createdAt: now,
        },
        {
          id: 'SAB-11029',
          trackingNumber: 'SAB-11029',
          userId: 10,
          userEmail: 'user@sabcargo.com',
          itemName: 'High-Grade Organic Textiles',
          origin: 'London Heathrow',
          destination: 'New York Hub',
          status: 5, // Delivered
          expectedDate: new Date(now.getTime() - 2 * 86400000).toLocaleDateString('en-GB'),
          weight: 45.0,
          type: 'Ocean Freight',
          senderName: 'Couture Textiles UK',
          receiverName: 'Fifth Ave Apparel NYC',
          receiverPhone: '+1 212 555 0199',
          totalAmount: 620.0,
          branchId: 'London Heathrow',
          steps: [
            { title: 'Booking Confirmed', subtitle: 'Container loaded at London Gateway', time: '05/10/2026', isCompleted: true, isCurrent: false },
            { title: 'Vessel in Transit', subtitle: 'Atlantic voyage completed', time: '15/10/2026', isCompleted: true, isCurrent: false },
            { title: 'Customs Cleared', subtitle: 'Port of NY inspection passed', time: '18/10/2026', isCompleted: true, isCurrent: false },
            { title: 'Delivered', subtitle: 'Delivered to warehouse dock 4. Signed by M. Vance', time: '19/10/2026, 14:20', isCompleted: true, isCurrent: true },
          ],
          createdAt: now,
        },
      ];
      await shipmentsCol.insertMany(sampleShipments);
      console.log('✓ Seeded sample tracking shipments');
    }

    // 7. Ensure counter values
    const counters = [
      { name: 'users', min: 20 },
      { name: 'services', min: 10 },
      { name: 'systemLogs', min: 50 },
      { name: 'notifications', min: 10 },
      { name: 'userOtps', min: 10 },
    ];
    for (const c of counters) {
      await countersCol.updateOne(
        { _id: c.name },
        { $max: { value: c.min } },
        { upsert: true }
      );
    }
  } catch (err) {
    console.error('Seed execution warning:', err.message);
  }
}

// ==========================================
// Database Connection Manager
// ==========================================
async function connectDatabase() {
  const uri = process.env.MONGODB_URI;

  if (uri && uri.trim() !== '') {
    try {
      console.log(`[MongoDB] Connecting to MongoDB Atlas cluster...`);
      client = new MongoClient(uri, {
        serverSelectionTimeoutMS: 5000,
        connectTimeoutMS: 5000,
      });
      await client.connect();
      database = client.db(process.env.MONGODB_DB || undefined);
      await database.command({ ping: 1 });
      dbMode = 'mongodb-atlas';
      database.getMode = () => 'mongodb-atlas';
      console.log(`[MongoDB] ✓ Successfully connected to MongoDB Atlas database "${database.databaseName}"`);
      await seedDefaultData(database);
      return database;
    } catch (error) {
      console.warn(`[MongoDB] Atlas connection failed (${error.message}).`);
      if (client) {
        try { await client.close(); } catch (_) {}
        client = undefined;
      }
      // If Atlas was explicitly configured, never accept writes into the local
      // JSON fallback. That can make the API report success while Atlas stays empty.
      database = undefined;
      dbMode = 'uninitialized';
      throw new Error('MongoDB Atlas connection failed; refusing local fallback. Check the URI, database user, and Atlas network access.');
    }
  } else {
    console.log(`[MongoDB] No MONGODB_URI set in backend/.env. Using resilient local MongoDB storage engine.`);
  }

  // Fallback to local MongoDB engine
  database = new LocalDatabase(process.env.MONGODB_DB || 'cargoApp');
  dbMode = 'local-fallback';
  console.log(`[MongoDB] ✓ Local MongoDB storage engine active (stored at backend/data/).`);
  await seedDefaultData(database);
  return database;
}

function getDatabase() {
  if (!database) {
    // If not connected yet, initialize local engine synchronously
    database = new LocalDatabase(process.env.MONGODB_DB || 'cargoApp');
    dbMode = 'local-fallback';
  }
  return database;
}

function getDbMode() {
  return dbMode;
}

async function closeDatabase() {
  if (client) {
    await client.close();
    client = undefined;
  }
  database = undefined;
  dbMode = 'uninitialized';
}

module.exports = {
  connectDatabase,
  getDatabase,
  closeDatabase,
  getDbMode,
  seedDefaultData,
};
