const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '.env') });

const crypto = require('crypto');
const express = require('express');
const cors = require('cors');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const nodemailer = require('nodemailer');
const { connectDatabase, getDatabase, closeDatabase, getDbMode } = require('./database');

const app = express();
const PORT = Number(process.env.PORT || 5000);
const OTP_EXPIRY_MINUTES = 5;
const JWT_SECRET = process.env.JWT_SECRET || 'sabcargo_jwt_secure_key_2026_dev_prod_auth';

app.use(cors({
  origin: '*',
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'Accept'],
}));
app.options('*', cors());
app.use(express.json({ limit: '10mb' }));

const mailTransport =
  process.env.SMTP_HOST &&
  process.env.SMTP_PORT &&
  process.env.SMTP_USER &&
  process.env.SMTP_PASS
    ? nodemailer.createTransport({
        host: process.env.SMTP_HOST,
        port: Number(process.env.SMTP_PORT),
        secure: String(process.env.SMTP_SECURE || 'false').toLowerCase() === 'true',
        auth: { user: process.env.SMTP_USER, pass: process.env.SMTP_PASS },
      })
    : null;

const collection = (name) => getDatabase().collection(name);
const normalizeEmail = (email) => String(email || '').trim().toLowerCase();
const parseId = (id) => /^\d+$/.test(String(id)) ? Number(id) : String(id);
const publicDocument = ({ _id, ...document }) => document;

async function ensureIndexes() {
  await Promise.all([
    collection('users').createIndex({ email: 1 }, { unique: true, sparse: true }),
    collection('admins').createIndex({ email: 1 }, { unique: true, sparse: true }),
    collection('shipments').createIndex({ trackingNumber: 1 }, { unique: true }),
    collection('bookings').createIndex({ bookingId: 1 }, { unique: true, sparse: true }),
    collection('systemSettings').createIndex({ key: 1 }, { unique: true }),
    collection('userOtps').createIndex({ userId: 1, createdAt: -1 }),
    collection('systemLogs').createIndex({ createdAt: -1 }),
    collection('notifications').createIndex({ sentAt: -1 }),
  ]);
}

async function nextId(name) {
  const result = await collection('counters').findOneAndUpdate(
    { _id: name },
    { $inc: { value: 1 } },
    { upsert: true, returnDocument: 'after' },
  );
  const counter = result?.value && typeof result.value === 'object' ? result.value : result;
  if (!Number.isInteger(counter?.value)) {
    throw new Error(`Failed to allocate an ID for ${name}`);
  }
  return counter.value;
}

async function sendOtpEmail(toEmail, code, subject = 'Your SabCargo OTP Code') {
  console.log(`[AUTH] >>> ${subject} for ${toEmail}: ${code} <<<`);
  if (!mailTransport) {
    return;
  }

  try {
    const isOtp = subject.toLowerCase().includes('otp');
    const text = isOtp
      ? `Your verification code is: ${code}\n\nThis code expires in ${OTP_EXPIRY_MINUTES} minutes.`
      : `Your secure access PIN is: ${code}\n\nPlease store it safely.`;
    await mailTransport.sendMail({
      from: process.env.SMTP_FROM || process.env.SMTP_USER,
      to: toEmail,
      subject,
      text,
    });
    console.log(`[AUTH] Email successfully delivered to ${toEmail}`);
  } catch (error) {
    console.warn(`[AUTH] Warning: SMTP delivery failed (${error.message}). Code is logged above for testing.`);
  }
}

function generateOtp() {
  return String(crypto.randomInt(100000, 1000000));
}

function authenticateToken(req, res, next) {
  const authHeader = req.headers.authorization || '';
  const token = authHeader.startsWith('Bearer ') ? authHeader.slice(7) : '';
  if (!token) return res.status(401).json({ error: 'Authentication required' });

  if (process.env.NODE_ENV !== 'production') {
    if (token === 'mock_superadmin_token') {
      req.user = { sub: 0, email: 'dev@sabcargo.com', role: 'SuperAdmin' };
      return next();
    }
    if (token === 'mock_admin_token') {
      req.user = { sub: 0, email: 'admin@sabcargo.com', role: 'Admin' };
      return next();
    }
    if (token === 'mock_driver_token') {
      req.user = { sub: 0, email: 'driver@sabcargo.com', role: 'Driver' };
      return next();
    }
  }

  jwt.verify(token, JWT_SECRET, (error, user) => {
    if (error) return res.status(403).json({ error: 'Forbidden: Invalid token' });
    req.user = user;
    next();
  });
}

function requireRole(allowedRoles) {
  return (req, res, next) => {
    if (req.user?.role === 'SuperAdmin' || allowedRoles.includes(req.user?.role)) {
      return next();
    }
    return res.status(403).json({ error: 'Forbidden: Insufficient permissions for this action' });
  };
}

async function logAction(userEmail, action, details) {
  try {
    await collection('systemLogs').insertOne({
      id: await nextId('systemLogs'),
      userEmail: userEmail || 'Unknown',
      action,
      details,
      createdAt: new Date(),
    });
  } catch (error) {
    console.error('Audit log failed:', error.message);
  }
}

async function getAdminByEmail(email) {
  return collection('admins').findOne({ email: normalizeEmail(email) });
}

async function branchFilterFor(req) {
  if (req.user.role !== 'Admin') return null;
  const admin = await getAdminByEmail(req.user.email);
  if (!admin?.branch) return { _id: { $exists: false } };
  const city = String(admin.branch).split(' ')[0];
  return {
    $or: [
      { branchId: admin.branch },
      { origin: { $regex: city, $options: 'i' } },
      { destination: { $regex: city, $options: 'i' } },
    ],
  };
}

function dateRange(startDate, endDate) {
  const start = startDate ? new Date(startDate) : new Date(Date.now() - 30 * 86400000);
  const end = endDate ? new Date(endDate) : new Date();
  if (Number.isNaN(start.getTime()) || Number.isNaN(end.getTime())) {
    throw new Error('Invalid analytics date range');
  }
  end.setHours(23, 59, 59, 999);
  return { start, end };
}

app.get('/', (_req, res) => res.json({ service: 'SabCargo Logistics API', database: 'MongoDB', engine: getDbMode() }));
app.get('/api/health', async (_req, res) => {
  try {
    await getDatabase().command({ ping: 1 });
    res.json({
      status: 'ok',
      database: 'connected',
      engine: getDbMode(),
      service: 'SabCargo Logistics API',
    });
  } catch (error) {
    res.status(503).json({ status: 'error', database: 'unavailable', message: error.message });
  }
});

app.post('/api/auth/register', async (req, res) => {
  const { name, email, phone } = req.body;
  const normalizedEmail = normalizeEmail(email);
  if (!name?.trim() || !normalizedEmail.includes('@') || !phone?.trim()) {
    return res.status(400).json({ error: 'Name, valid email, and phone are required' });
  }

  try {
    const users = collection('users');
    let user = await users.findOne({ email: normalizedEmail });
    if (user?.isVerified) {
      return res.status(400).json({ error: 'Account already exists for this email. Please use Reset PIN to recover access.' });
    }
    if (user) {
      await users.updateOne(
        { _id: user._id },
        { $set: { fullName: name.trim(), phone: phone.trim() } },
      );
    } else {
      user = {
        id: await nextId('users'),
        fullName: name.trim(),
        email: normalizedEmail,
        phone: phone.trim(),
        isVerified: false,
        isActive: true,
        createdAt: new Date(),
      };
      await users.insertOne(user);
    }

    const otp = generateOtp();
    await collection('userOtps').insertOne({
      id: await nextId('userOtps'),
      userId: user.id,
      otpHash: await bcrypt.hash(otp, 10),
      expiresAt: new Date(Date.now() + OTP_EXPIRY_MINUTES * 60000),
      used: false,
      createdAt: new Date(),
    });
    await logAction(normalizedEmail, 'USER_REGISTER_START', { name: name.trim(), phone: phone.trim() });
    await sendOtpEmail(normalizedEmail, otp, 'Your Permanent SabCargo Access PIN');
    return res.json({ success: true });
  } catch (error) {
    console.error('Registration error:', error);
    return res.status(500).json({ error: 'Registration failed' });
  }
});

app.post('/api/auth/verify-otp', async (req, res) => {
  const email = normalizeEmail(req.body.email);
  const { otp } = req.body;
  try {
    const user = await collection('users').findOne({ email });
    if (!user) return res.status(404).json({ error: 'User not found' });
    const row = await collection('userOtps').findOne(
      { userId: user.id, used: false, expiresAt: { $gt: new Date() } },
      { sort: { createdAt: -1 } },
    );
    if (!row || !(await bcrypt.compare(String(otp || ''), row.otpHash))) {
      return res.status(400).json({ error: 'Invalid or expired code' });
    }

    await collection('userOtps').updateOne({ _id: row._id }, { $set: { used: true } });
    await collection('users').updateOne(
      { _id: user._id },
      { $set: { isVerified: true, pinHash: row.otpHash } },
    );
    await logAction(email, 'VERIFY_ACCOUNT', { method: 'OTP' });
    return res.json({ success: true, message: 'Account verified and PIN set permanently' });
  } catch (error) {
    console.error('OTP verification error:', error);
    return res.status(500).json({ error: 'Verification failed' });
  }
});

app.post('/api/auth/set-pin', async (req, res) => {
  const email = normalizeEmail(req.body.email);
  const { pin } = req.body;
  if (!email.includes('@') || !/^\d{4,10}$/.test(String(pin || ''))) {
    return res.status(400).json({ error: 'A valid email and 4-10 digit PIN are required' });
  }
  try {
    const result = await collection('users').updateOne(
      { email, isVerified: true },
      { $set: { pinHash: await bcrypt.hash(String(pin), 10) } },
    );
    if (!result.matchedCount) return res.status(404).json({ error: 'Verified user not found' });
    await sendOtpEmail(email, pin, 'Your SabCargo Access PIN (Reminder)');
    return res.json({ success: true });
  } catch (error) {
    console.error('Set PIN error:', error);
    return res.status(500).json({ error: 'Failed to set PIN' });
  }
});

app.post('/api/verify-pin', async (req, res) => {
  const email = normalizeEmail(req.body.email);
  const { pin } = req.body;
  try {
    let user;
    if (email) {
      user = await collection('users').findOne({ email });
    } else {
      const candidates = collection('users').find({ pinHash: { $type: 'string' } });
      for await (const candidate of candidates) {
        if (await bcrypt.compare(String(pin || ''), candidate.pinHash)) {
          user = candidate;
          break;
        }
      }
    }
    if (!user || !user.pinHash || !(await bcrypt.compare(String(pin || ''), user.pinHash))) {
      return res.status(401).json({ valid: false, error: 'Incorrect Security PIN' });
    }
    if (!user.isVerified || user.isActive === false) {
      return res.status(403).json({ valid: false, error: 'Account is not active or verified' });
    }

    const admin = await getAdminByEmail(user.email);
    if (admin && !admin.isActive) {
      return res.status(403).json({ valid: false, error: 'Admin account is inactive' });
    }
    const role = admin
      ? (String(admin.role).toLowerCase() === 'superadmin' ? 'SuperAdmin' : 'Admin')
      : 'User';
    const token = jwt.sign(
      { sub: user.id, email: user.email, role },
      JWT_SECRET,
      { expiresIn: '7d' },
    );
    await logAction(user.email, 'LOGIN', { role });
    return res.json({
      valid: true,
      token,
      role,
      user: {
        id: user.id,
        fullName: user.fullName,
        email: user.email,
        branch: admin?.branch || null,
      },
    });
  } catch (error) {
    console.error('PIN verification error:', error);
    return res.status(500).json({ error: 'Internal Auth Error' });
  }
});

app.get('/api/auth/me', authenticateToken, async (req, res) => {
  try {
    const admin = await getAdminByEmail(req.user.email);
    const role = admin
      ? (String(admin.role).toLowerCase() === 'superadmin' ? 'SuperAdmin' : 'Admin')
      : 'User';
    const token = jwt.sign(
      { sub: req.user.sub, email: req.user.email, role },
      JWT_SECRET,
      { expiresIn: '7d' },
    );
    return res.json({ token, role });
  } catch (error) {
    console.error('Auth sync error:', error);
    return res.status(500).json({ error: 'Failed to sync role' });
  }
});

app.post('/api/auth/request-pin-reset', async (req, res) => {
  const email = normalizeEmail(req.body.email);
  try {
    const user = await collection('users').findOne({ email });
    if (!user) return res.status(404).json({ error: 'Email not found in our records' });
    const pin = generateOtp();
    await collection('users').updateOne(
      { _id: user._id },
      { $set: { pinHash: await bcrypt.hash(pin, 10) } },
    );
    await sendOtpEmail(email, pin, 'Your Permanent SabCargo Access PIN');
    return res.json({ success: true });
  } catch (error) {
    console.error('PIN reset error:', error);
    return res.status(500).json({ error: 'Failed to reset PIN' });
  }
});

app.get('/api/admins', authenticateToken, requireRole(['SuperAdmin']), async (_req, res) => {
  try {
    const admins = await collection('admins').find().sort({ createdAt: -1 }).toArray();
    return res.json(admins.map((admin) => ({
      id: admin.id,
      name: admin.fullName || '',
      email: admin.email || '',
      phoneNumber: admin.phone || '',
      role: String(admin.role).toLowerCase() === 'superadmin' ? 1 : 0,
      branchName: admin.branch || '',
      isActive: admin.isActive !== false,
      permissions: Array.isArray(admin.permissions) ? admin.permissions : [],
    })));
  } catch (error) {
    console.error('Fetch admins error:', error);
    return res.status(500).json({ error: 'Failed to fetch admins' });
  }
});

app.post('/api/admins', authenticateToken, requireRole(['SuperAdmin']), async (req, res) => {
  const { id, name, email, phoneNumber, role, branchName, isActive, permissions } = req.body;
  const normalizedEmail = normalizeEmail(email);
  if (!id || !name?.trim() || !normalizedEmail.includes('@')) {
    return res.status(400).json({ error: 'Admin ID, name, and valid email are required' });
  }
  try {
    const admin = {
      id: String(id),
      fullName: name.trim(),
      email: normalizedEmail,
      phone: phoneNumber || '',
      role: role === 1 ? 'superAdmin' : 'admin',
      branch: branchName || '',
      isActive: Boolean(isActive),
      permissions: Array.isArray(permissions) ? permissions : [],
      createdAt: new Date(),
    };
    await collection('admins').replaceOne({ id: admin.id }, admin, { upsert: true });

    await collection('users').updateOne(
      { email: normalizedEmail },
      {
        $set: {
          fullName: admin.fullName,
          phone: admin.phone,
          isActive: admin.isActive,
          isVerified: true,
          updatedAt: new Date(),
        },
        $setOnInsert: {
          id: await nextId('users'),
          email: normalizedEmail,
          createdAt: new Date(),
        },
      },
      { upsert: true },
    );
    return res.json({ success: true });
  } catch (error) {
    console.error('Add admin error:', error);
    return res.status(500).json({ error: 'Failed to add admin' });
  }
});

app.delete('/api/admins/:id', authenticateToken, requireRole(['SuperAdmin']), async (req, res) => {
  try {
    await collection('admins').deleteOne({ id: req.params.id });
    return res.json({ success: true });
  } catch (error) {
    console.error('Delete admin error:', error);
    return res.status(500).json({ error: 'Failed to delete admin' });
  }
});

app.patch('/api/admins/:id/toggle-active', authenticateToken, requireRole(['SuperAdmin']), async (req, res) => {
  try {
    const admins = collection('admins');
    const admin = await admins.findOne({ id: req.params.id });
    if (!admin) return res.status(404).json({ error: 'Admin not found' });
    const isActive = admin.isActive === false;
    await admins.updateOne({ _id: admin._id }, { $set: { isActive } });
    await collection('users').updateOne({ email: admin.email }, { $set: { isActive } });
    await logAction(req.user.email, isActive ? 'ENABLE_ADMIN' : 'DISABLE_ADMIN', { adminId: req.params.id });
    return res.json({ success: true, isActive });
  } catch (error) {
    console.error('Toggle admin error:', error);
    return res.status(500).json({ error: 'Failed to toggle admin' });
  }
});

app.post('/api/admins/:id/reset-pin', authenticateToken, requireRole(['SuperAdmin']), async (req, res) => {
  try {
    const admin = await collection('admins').findOne({ id: req.params.id });
    if (!admin) return res.status(404).json({ error: 'Admin not found' });
    const pin = generateOtp();
    await collection('users').updateOne(
      { email: admin.email },
      { $set: { pinHash: await bcrypt.hash(pin, 10) } },
    );
    await sendOtpEmail(admin.email, pin, 'Your SabCargo Admin PIN Has Been Reset');
    await logAction(req.user.email, 'RESET_ADMIN_PIN', { adminId: req.params.id });
    return res.json({ success: true });
  } catch (error) {
    console.error('Reset admin PIN error:', error);
    return res.status(500).json({ error: 'Failed to reset admin PIN' });
  }
});

app.get('/api/settings/:key', async (req, res) => {
  try {
    const setting = await collection('systemSettings').findOne({ key: req.params.key });
    if (!setting) return res.status(404).json({ error: 'Settings not found' });
    return res.json(setting.value);
  } catch (error) {
    console.error('Fetch settings error:', error);
    return res.status(500).json({ error: 'Failed to fetch settings' });
  }
});

app.post('/api/settings', authenticateToken, requireRole(['SuperAdmin']), async (req, res) => {
  const { key, value } = req.body;
  if (!key) return res.status(400).json({ error: 'Setting key is required' });
  try {
    await collection('systemSettings').updateOne(
      { key: String(key) },
      { $set: { value, updatedAt: new Date() } },
      { upsert: true },
    );
    return res.json({ success: true });
  } catch (error) {
    console.error('Save settings error:', error);
    return res.status(500).json({ error: 'Failed to save settings' });
  }
});

app.get('/api/shipments', authenticateToken, async (req, res) => {
  try {
    const query = {};
    let adminBranch;
    if (req.user.role === 'User') {
      query.userId = parseId(req.user.sub);
    } else if (req.user.role === 'Driver') {
      query.driverId = String(req.user.sub);
    } else if (req.user.role === 'Admin') {
      Object.assign(query, await branchFilterFor(req));
      adminBranch = (await getAdminByEmail(req.user.email))?.branch;
    }
    const shipments = await collection('shipments').find(query).sort({ createdAt: -1, id: -1 }).toArray();
    return res.json(shipments.map((shipment) => ({
      ...publicDocument(shipment),
      ...(req.user.role === 'Admin' && adminBranch && !shipment.branchId
        ? { branchId: adminBranch }
        : {}),
    })));
  } catch (error) {
    console.error('Fetch shipments error:', error);
    return res.status(500).json({ error: 'Failed to fetch shipments' });
  }
});

app.post('/api/bookings', authenticateToken, async (req, res) => {
  const {
    bookingId, itemName, cargoType, fromCity, toCity, senderName,
    receiverName, receiverPhone, weight, total, branchId,
  } = req.body;
  if (!bookingId || !itemName || !fromCity || !toCity) {
    return res.status(400).json({ error: 'Booking ID, item, origin, and destination are required' });
  }
  try {
    const userId = parseId(req.user.sub);
    const now = new Date();
    const steps = [{
      title: 'Booking Confirmed',
      subtitle: 'Package being prepared for pickup',
      time: now.toLocaleString('en-GB'),
      isCompleted: true,
      isCurrent: true,
    }];
    const shipment = {
      id: String(bookingId),
      userId,
      userEmail: normalizeEmail(req.user.email),
      trackingNumber: String(bookingId),
      itemName: String(itemName),
      origin: String(fromCity),
      destination: String(toCity),
      status: 0,
      expectedDate: new Date(now.getTime() + 7 * 86400000).toLocaleDateString('en-GB'),
      weight: Number(weight) || 0,
      type: cargoType || '',
      senderName: senderName || '',
      receiverName: receiverName || '',
      receiverPhone: receiverPhone || '',
      totalAmount: Number(total) || 0,
      branchId: branchId || null,
      steps,
      createdAt: now,
    };
    await collection('shipments').updateOne(
      { trackingNumber: shipment.trackingNumber },
      { $set: shipment },
      { upsert: true },
    );
    await collection('bookings').updateOne(
      { bookingId: String(bookingId) },
      {
        $set: {
          bookingId: String(bookingId),
          userId,
          itemName: shipment.itemName,
          cargoType: shipment.type,
          fromCity: shipment.origin,
          toCity: shipment.destination,
          senderName: shipment.senderName,
          receiverName: shipment.receiverName,
          receiverPhone: shipment.receiverPhone,
          weight: shipment.weight,
          total: shipment.totalAmount,
          createdAt: now,
        },
      },
      { upsert: true },
    );
    await logAction(req.user.email, 'NEW_BOOKING', { trackingNumber: bookingId, itemName });
    return res.json({ success: true, bookingId });
  } catch (error) {
    console.error('Booking error:', error);
    return res.status(500).json({ error: 'Booking failed' });
  }
});

app.post('/api/shipments', authenticateToken, requireRole(['Admin', 'SuperAdmin']), async (req, res) => {
  const { trackingNumber, itemName, origin, destination, status, expectedDate, weight, type, steps, userEmail, branchId, driverId } = req.body;
  if (!trackingNumber || !itemName) {
    return res.status(400).json({ error: 'Tracking number and item name are required' });
  }
  try {
    const owner = userEmail
      ? await collection('users').findOne({ email: normalizeEmail(userEmail) })
      : null;
    const shipment = {
      id: String(req.body.id || trackingNumber),
      trackingNumber: String(trackingNumber),
      userId: owner?.id ?? req.body.userId ?? null,
      userEmail: owner?.email || normalizeEmail(userEmail) || null,
      itemName: String(itemName),
      origin: origin || '',
      destination: destination || '',
      status: Number(status) || 0,
      expectedDate: expectedDate || '',
      weight: Number(weight) || 0,
      type: type || '',
      branchId: branchId || null,
      driverId: driverId || null,
      steps: Array.isArray(steps) ? steps : [],
      createdAt: new Date(),
    };
    await collection('shipments').updateOne(
      { trackingNumber: shipment.trackingNumber },
      {
        $set: shipment,
        $setOnInsert: { createdAt: new Date() },
      },
      { upsert: true },
    );
    await logAction(req.user.email, 'UPSERT_SHIPMENT', { trackingNumber, status: shipment.status });
    return res.status(201).json({ success: true });
  } catch (error) {
    console.error('Shipment save error:', error);
    return res.status(500).json({ error: 'Failed to save shipment' });
  }
});

app.patch('/api/shipments/:trackingNumber/steps', authenticateToken, requireRole(['Admin', 'SuperAdmin']), async (req, res) => {
  const { newStep, status } = req.body;
  if (!newStep || typeof newStep !== 'object') {
    return res.status(400).json({ error: 'A tracking step is required' });
  }
  try {
    const shipments = collection('shipments');
    const accessQuery = req.user.role === 'Admin' ? await branchFilterFor(req) : {};
    const shipment = await shipments.findOne({
      trackingNumber: req.params.trackingNumber,
      ...accessQuery,
    });
    if (!shipment) return res.status(404).json({ error: 'Shipment not found' });

    const steps = (Array.isArray(shipment.steps) ? shipment.steps : []).map((step) => ({
      ...step,
      isCurrent: false,
    }));
    steps.push({ ...newStep, isCurrent: true, isCompleted: true });
    const update = { steps };
    const numericStatus = Number(status);
    if (Number.isInteger(numericStatus) && numericStatus >= 0 && numericStatus <= 6) {
      update.status = numericStatus;
    }
    await shipments.updateOne({ _id: shipment._id }, { $set: update });
    await logAction(req.user.email, 'UPDATE_TRACKING', {
      trackingNumber: req.params.trackingNumber,
      newStatus: update.status,
    });
    return res.json({ success: true, steps });
  } catch (error) {
    console.error('Step update error:', error);
    return res.status(500).json({ error: 'Failed to update tracking steps' });
  }
});

app.delete('/api/shipments/:trackingNumber', authenticateToken, requireRole(['Admin', 'SuperAdmin']), async (req, res) => {
  try {
    const result = await collection('shipments').deleteOne({ trackingNumber: req.params.trackingNumber });
    if (!result.deletedCount) return res.status(404).json({ error: 'Shipment not found' });
    await logAction(req.user.email, 'CANCEL_SHIPMENT', { trackingNumber: req.params.trackingNumber });
    return res.json({ success: true });
  } catch (error) {
    console.error('Cancel shipment error:', error);
    return res.status(500).json({ error: 'Failed to cancel shipment' });
  }
});

app.post('/api/users', authenticateToken, requireRole(['Admin', 'SuperAdmin']), async (req, res) => {
  const { name, email, phone, pin } = req.body;
  const normalizedEmail = normalizeEmail(email);
  if (!name?.trim() || !normalizedEmail.includes('@') || !pin) {
    return res.status(400).json({ error: 'Name, valid email, and PIN are required' });
  }
  try {
    const user = {
      id: await nextId('users'),
      fullName: name.trim(),
      email: normalizedEmail,
      phone: phone || '',
      pinHash: await bcrypt.hash(String(pin), 10),
      isVerified: true,
      isActive: true,
      createdAt: new Date(),
    };
    await collection('users').insertOne(user);
    return res.status(201).json({ id: user.id, name: user.fullName, email: user.email });
  } catch (error) {
    console.error('Create user error:', error);
    return res.status(500).json({ error: 'Failed to create user' });
  }
});

app.get('/api/users', authenticateToken, requireRole(['Admin', 'SuperAdmin']), async (req, res) => {
  try {
    const query = {};
    if (req.user.role === 'Admin') {
      const admin = await getAdminByEmail(req.user.email);
      if (!admin?.branch) return res.json([]);
      query.assignedOffice = admin.branch;
    }
    const users = await collection('users').find(query).sort({ createdAt: -1 }).toArray();
    return res.json(users.map((user) => ({
      id: user.id,
      name: user.fullName || '',
      email: user.email || '',
      phone: user.phone || '',
      isVerified: Boolean(user.isVerified),
      isActive: user.isActive !== false,
      assignedOffice: user.assignedOffice || '',
      hasPin: Boolean(user.pinHash),
    })));
  } catch (error) {
    console.error('Fetch users error:', error);
    return res.status(500).json({ error: 'Failed to fetch users' });
  }
});

app.put('/api/users/:id', authenticateToken, requireRole(['Admin', 'SuperAdmin']), async (req, res) => {
  const { name, email, phone, assignedOffice } = req.body;
  try {
    if (req.user.role === 'Admin') {
      const admin = await getAdminByEmail(req.user.email);
      if (!admin?.branch || (assignedOffice && assignedOffice !== admin.branch)) {
        return res.status(403).json({ error: 'Cannot assign users to other branches' });
      }
    }
    const result = await collection('users').updateOne(
      { id: parseId(req.params.id) },
      { $set: {
        fullName: name,
        email: normalizeEmail(email),
        phone: phone || '',
        assignedOffice: assignedOffice || null,
      } },
    );
    if (!result.matchedCount) return res.status(404).json({ error: 'User not found' });
    await logAction(req.user.email, 'EDIT_USER', { userId: req.params.id, email });
    return res.json({ success: true });
  } catch (error) {
    console.error('Edit user error:', error);
    return res.status(500).json({ error: 'Failed to update user' });
  }
});

app.delete('/api/users/:id', authenticateToken, requireRole(['SuperAdmin']), async (req, res) => {
  try {
    const id = parseId(req.params.id);
    await collection('userOtps').deleteMany({ userId: id });
    const result = await collection('users').deleteOne({ id });
    if (!result.deletedCount) return res.status(404).json({ error: 'User not found' });
    await logAction(req.user.email, 'DELETE_USER', { userId: id });
    return res.json({ success: true });
  } catch (error) {
    console.error('Delete user error:', error);
    return res.status(500).json({ error: 'Failed to delete user' });
  }
});

app.delete('/api/users/:id/delete-account', authenticateToken, async (req, res) => {
  try {
    const id = parseId(req.params.id);
    if (req.user.email !== normalizeEmail(req.body.email) || String(req.user.sub) !== String(id)) {
      return res.status(403).json({ error: 'Unauthorized: You can only delete your own account.' });
    }
    const result = await collection('users').updateOne(
      { id, email: normalizeEmail(req.user.email) },
      { $set: { isActive: false, pinHash: null, fullName: 'Deleted User', phone: null } },
    );
    if (!result.matchedCount) return res.status(404).json({ error: 'User not found' });
    await logAction(req.user.email, 'SELF_DELETE_ACCOUNT', { userId: id });
    return res.json({ success: true, message: 'Account deleted successfully' });
  } catch (error) {
    console.error('Account delete error:', error);
    return res.status(500).json({ error: 'Failed to delete account' });
  }
});

app.put('/api/profile', authenticateToken, async (req, res) => {
  try {
    const result = await collection('users').updateOne(
      { email: normalizeEmail(req.user.email) },
      { $set: {
        fullName: req.body.name,
        phone: req.body.phone,
        photoBase64: req.body.photo || null,
      } },
    );
    if (!result.matchedCount) return res.status(404).json({ error: 'User not found' });
    return res.json({ success: true });
  } catch (error) {
    console.error('Update profile error:', error);
    return res.status(500).json({ error: 'Failed to update profile' });
  }
});

app.patch('/api/users/:id/toggle-active', authenticateToken, requireRole(['SuperAdmin']), async (req, res) => {
  try {
    const users = collection('users');
    const user = await users.findOne({ id: parseId(req.params.id) });
    if (!user) return res.status(404).json({ error: 'User not found' });
    const isActive = user.isActive === false;
    await users.updateOne({ _id: user._id }, { $set: { isActive } });
    await logAction(req.user.email, isActive ? 'ENABLE_USER' : 'DISABLE_USER', { userId: user.id });
    return res.json({ success: true, isActive });
  } catch (error) {
    console.error('Toggle user error:', error);
    return res.status(500).json({ error: 'Failed to toggle user' });
  }
});

app.post('/api/users/:id/force-logout', authenticateToken, requireRole(['SuperAdmin']), async (req, res) => {
  try {
    await collection('userOtps').updateMany({ userId: parseId(req.params.id) }, { $set: { used: true } });
    await logAction(req.user.email, 'FORCE_LOGOUT', { userId: req.params.id });
    return res.json({ success: true, message: 'OTP sessions invalidated; existing JWT tokens expire normally.' });
  } catch (error) {
    console.error('Force logout error:', error);
    return res.status(500).json({ error: 'Failed to force logout' });
  }
});

app.post('/api/users/:id/lock', authenticateToken, requireRole(['SuperAdmin']), async (req, res) => {
  try {
    const result = await collection('users').updateOne(
      { id: parseId(req.params.id) },
      { $set: { isActive: false, isVerified: false } },
    );
    if (!result.matchedCount) return res.status(404).json({ error: 'User not found' });
    await logAction(req.user.email, 'LOCK_USER', { userId: req.params.id });
    return res.json({ success: true });
  } catch (error) {
    console.error('Lock user error:', error);
    return res.status(500).json({ error: 'Failed to lock user' });
  }
});

app.post('/api/users/:id/reset-pin', authenticateToken, requireRole(['Admin', 'SuperAdmin']), async (req, res) => {
  try {
    const user = await collection('users').findOne({ id: parseId(req.params.id) });
    if (!user) return res.status(404).json({ error: 'User not found' });
    if (req.user.role === 'Admin') {
      const admin = await getAdminByEmail(req.user.email);
      if (!admin?.branch || user.assignedOffice !== admin.branch) {
        return res.status(403).json({ error: 'Cannot reset PIN for a user outside your branch' });
      }
    }
    const pin = generateOtp();
    await collection('users').updateOne(
      { _id: user._id },
      { $set: { pinHash: await bcrypt.hash(pin, 10) } },
    );
    await sendOtpEmail(user.email, pin, 'Your SabCargo PIN Has Been Reset By Admin');
    await logAction(req.user.email, 'RESET_USER_PIN', { userId: user.id });
    return res.json({ success: true });
  } catch (error) {
    console.error('Reset user PIN error:', error);
    return res.status(500).json({ error: 'Failed to reset user PIN' });
  }
});

app.get('/api/stats', authenticateToken, requireRole(['Admin', 'SuperAdmin']), async (req, res) => {
  try {
    const query = req.user.role === 'Admin' ? await branchFilterFor(req) : {};
    const [totalUsers, activeUsers, admins, shipments, statusBreakdown, dailyTrends] = await Promise.all([
      collection('users').countDocuments(),
      collection('users').countDocuments({ isActive: { $ne: false } }),
      collection('admins').countDocuments({ isActive: { $ne: false } }),
      collection('shipments').find(query).toArray(),
      collection('shipments').aggregate([
        { $match: query },
        { $group: { _id: '$status', count: { $sum: 1 } } },
        { $sort: { _id: 1 } },
      ]).toArray(),
      collection('shipments').aggregate([
        { $match: { ...query, createdAt: { $gte: new Date(Date.now() - 7 * 86400000) } } },
        { $group: { _id: { $dateToString: { format: '%Y-%m-%d', date: '$createdAt' } }, count: { $sum: 1 } } },
        { $sort: { _id: 1 } },
      ]).toArray(),
    ]);
    const statuses = shipments.map((shipment) => Number(shipment.status) || 0);
    return res.json({
      users: { total: totalUsers, active: activeUsers },
      shipments: {
        total: shipments.length,
        pending: statuses.filter((status) => status === 0).length,
        delivered: statuses.filter((status) => status === 5).length,
        inTransit: statuses.filter((status) => status >= 1 && status <= 4).length,
      },
      admins: { total: admins },
      charts: {
        statusBreakdown: statusBreakdown.map(({ _id, count }) => ({ Status: _id, count })),
        dailyTrends: dailyTrends.map(({ _id, count }) => ({ date: _id, count })),
      },
    });
  } catch (error) {
    console.error('Stats error:', error);
    return res.status(500).json({ error: 'Failed to fetch stats' });
  }
});

app.get('/api/analytics', authenticateToken, requireRole(['Admin', 'SuperAdmin']), async (req, res) => {
  try {
    const { start, end } = dateRange(req.query.startDate, req.query.endDate);
    const shipmentQuery = req.user.role === 'Admin' ? await branchFilterFor(req) : {};
    const filter = { ...shipmentQuery, createdAt: { $gte: start, $lte: end } };
    const allShipments = await collection('shipments').find(shipmentQuery).toArray();
    const currentShipments = allShipments.filter((shipment) => {
      const created = shipment.createdAt ? new Date(shipment.createdAt) : new Date(0);
      return created >= start && created <= end;
    });
    const statuses = currentShipments.map((shipment) => Number(shipment.status) || 0);
    const dailyTrends = await collection('shipments').aggregate([
      { $match: filter },
      { $group: { _id: { $dateToString: { format: '%Y-%m-%d', date: '$createdAt' } }, count: { $sum: 1 } } },
      { $sort: { _id: 1 } },
    ]).toArray();
    const statusBreakdown = await collection('shipments').aggregate([
      { $match: filter },
      { $group: { _id: '$status', count: { $sum: 1 } } },
      { $sort: { _id: 1 } },
    ]).toArray();
    const bookingTrends = await collection('bookings').aggregate([
      { $match: { createdAt: { $gte: start, $lte: end } } },
      { $group: { _id: { $dateToString: { format: '%Y-%m-%d', date: '$createdAt' } }, count: { $sum: 1 } } },
      { $sort: { _id: 1 } },
    ]).toArray();
    const logs = await collection('systemLogs').find({ createdAt: { $gte: start, $lte: end } })
      .sort({ createdAt: -1 }).limit(10).toArray();
    const userQuery = req.user.role === 'Admin'
      ? { assignedOffice: (await getAdminByEmail(req.user.email))?.branch || '__no_branch__' }
      : {};
    const [userTotal, totalAdmins, totalOfficeAdmins, totalOffices] = await Promise.all([
      collection('users').countDocuments(userQuery),
      req.user.role === 'SuperAdmin' ? collection('admins').countDocuments() : 0,
      req.user.role === 'SuperAdmin' ? collection('admins').countDocuments({ role: { $ne: 'superAdmin' } }) : 0,
      req.user.role === 'SuperAdmin'
        ? collection('admins').distinct('branch', { branch: { $nin: [null, ''] } }).then((values) => values.length)
        : 0,
    ]);
    return res.json({
      kpis: {
        totalShipments: currentShipments.length,
        delivered: statuses.filter((status) => status === 5).length,
        pending: statuses.filter((status) => status === 0).length,
        inTransit: statuses.filter((status) => status >= 1 && status <= 4).length,
      },
      charts: {
        statusBreakdown: statusBreakdown.map(({ _id, count }) => ({ Status: _id, count })),
        dailyTrends: dailyTrends.map(({ _id, count }) => ({ date: _id, count })),
        dailyBookings: bookingTrends.map(({ _id, count }) => ({ date: _id, count })),
      },
      activity: logs.map((log) => ({
        action: log.action,
        userEmail: log.userEmail,
        createdAt: log.createdAt,
      })),
      users: { total: userTotal },
      admins: { totalAdmins, totalOfficeAdmins },
      offices: { totalOffices },
    });
  } catch (error) {
    console.error('Analytics error:', error);
    return res.status(500).json({ error: 'Failed to fetch analytics' });
  }
});

app.get('/api/logs', authenticateToken, requireRole(['SuperAdmin']), async (req, res) => {
  try {
    const limit = Math.min(Math.max(Number.parseInt(req.query.limit, 10) || 100, 1), 500);
    const logs = await collection('systemLogs').find().sort({ createdAt: -1 }).limit(limit).toArray();
    return res.json(logs.map(publicDocument));
  } catch (error) {
    console.error('Logs error:', error);
    return res.status(500).json({ error: 'Failed to fetch logs' });
  }
});

app.get('/api/services', async (_req, res) => {
  try {
    const services = await collection('services').find().sort({ id: 1 }).toArray();
    return res.json(services.map(publicDocument));
  } catch (error) {
    console.error('Fetch services error:', error);
    return res.status(500).json({ error: 'Failed to fetch services' });
  }
});

app.post('/api/services', authenticateToken, requireRole(['Admin', 'SuperAdmin']), async (req, res) => {
  const { name, description, iconCode, colorValue } = req.body;
  try {
    await collection('services').insertOne({
      id: await nextId('services'),
      name,
      description: description || '',
      iconCode: Number(iconCode) || 0,
      colorValue: Number(colorValue) || 0,
      isActive: true,
      createdAt: new Date(),
    });
    await logAction(req.user.email, 'ADD_SERVICE', { name });
    return res.status(201).json({ success: true });
  } catch (error) {
    console.error('Add service error:', error);
    return res.status(500).json({ error: 'Failed to add service' });
  }
});

app.put('/api/services/:id', authenticateToken, requireRole(['Admin', 'SuperAdmin']), async (req, res) => {
  try {
    const result = await collection('services').updateOne(
      { id: parseId(req.params.id) },
      { $set: {
        name: req.body.name,
        description: req.body.description || '',
        iconCode: Number(req.body.iconCode) || 0,
        colorValue: Number(req.body.colorValue) || 0,
        isActive: Boolean(req.body.isActive),
      } },
    );
    if (!result.matchedCount) return res.status(404).json({ error: 'Service not found' });
    await logAction(req.user.email, 'UPDATE_SERVICE', { id: req.params.id, name: req.body.name });
    return res.json({ success: true });
  } catch (error) {
    console.error('Update service error:', error);
    return res.status(500).json({ error: 'Failed to update service' });
  }
});

app.delete('/api/services/:id', authenticateToken, requireRole(['Admin', 'SuperAdmin']), async (req, res) => {
  try {
    const result = await collection('services').deleteOne({ id: parseId(req.params.id) });
    if (!result.deletedCount) return res.status(404).json({ error: 'Service not found' });
    await logAction(req.user.email, 'DELETE_SERVICE', { id: req.params.id });
    return res.json({ success: true });
  } catch (error) {
    console.error('Delete service error:', error);
    return res.status(500).json({ error: 'Failed to delete service' });
  }
});

app.patch('/api/services/:id/toggle', authenticateToken, requireRole(['Admin', 'SuperAdmin']), async (req, res) => {
  try {
    const services = collection('services');
    const service = await services.findOne({ id: parseId(req.params.id) });
    if (!service) return res.status(404).json({ error: 'Service not found' });
    const isActive = service.isActive === false;
    await services.updateOne({ _id: service._id }, { $set: { isActive } });
    return res.json({ success: true, isActive });
  } catch (error) {
    console.error('Toggle service error:', error);
    return res.status(500).json({ error: 'Failed to toggle service' });
  }
});

app.post('/api/notifications/broadcast', authenticateToken, requireRole(['Admin', 'SuperAdmin']), async (req, res) => {
  const { title, body, targetRole, targetEmail } = req.body;
  try {
    await collection('notifications').insertOne({
      id: await nextId('notifications'),
      title,
      body,
      sentBy: req.user.email || 'Unknown',
      sentAt: new Date(),
      targetRole: targetRole || (targetEmail ? 'User' : 'All'),
      targetUserEmail: targetEmail ? normalizeEmail(targetEmail) : null,
    });
    await logAction(req.user.email, 'SEND_NOTIFICATION', { title, targetRole, targetEmail });
    return res.json({ success: true });
  } catch (error) {
    console.error('Broadcast error:', error);
    return res.status(500).json({ error: 'Failed to send notification' });
  }
});

app.get('/api/notifications/user', authenticateToken, async (req, res) => {
  try {
    const notifications = await collection('notifications').find({
      $or: [
        { targetUserEmail: normalizeEmail(req.user.email) },
        { targetRole: 'All' },
        { targetRole: req.user.role },
      ],
    }).sort({ sentAt: -1 }).toArray();
    return res.json(notifications.map(({ id, title, body, sentAt }) => ({ id, title, body, sentAt })));
  } catch (error) {
    console.error('Fetch user notifications error:', error);
    return res.status(500).json({ error: 'Failed to fetch user notifications' });
  }
});

app.get('/api/notifications', authenticateToken, requireRole(['Admin', 'SuperAdmin']), async (_req, res) => {
  try {
    const notifications = await collection('notifications').find().sort({ sentAt: -1 }).limit(50).toArray();
    return res.json(notifications.map(publicDocument));
  } catch (error) {
    console.error('Fetch notifications error:', error);
    return res.status(500).json({ error: 'Failed to fetch notifications' });
  }
});

async function start() {
  if (!JWT_SECRET) {
    throw new Error('JWT_SECRET is required. Configure it in backend/.env.');
  }
  await connectDatabase();
  await ensureIndexes();
  const server = app.listen(PORT, () => console.log(`SabCargo API running on port ${PORT}`));

  const shutdown = async () => {
    server.close(async () => {
      await closeDatabase();
      process.exit(0);
    });
  };
  process.once('SIGINT', shutdown);
  process.once('SIGTERM', shutdown);
}

if (require.main === module) {
  start().catch((error) => {
    console.error('MongoDB startup failed:', error.message);
    process.exitCode = 1;
  });
}

module.exports = { app, start };
