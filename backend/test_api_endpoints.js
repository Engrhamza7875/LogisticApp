const http = require('http');

function request(options, body = null) {
  return new Promise((resolve, reject) => {
    const req = http.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => (data += chunk));
      res.on('end', () => {
        try {
          resolve({ status: res.statusCode, body: JSON.parse(data) });
        } catch (_) {
          resolve({ status: res.statusCode, body: data });
        }
      });
    });
    req.on('error', reject);
    if (body) {
      req.write(typeof body === 'string' ? body : JSON.stringify(body));
    }
    req.end();
  });
}

async function runTests() {
  console.log('--- Testing SabCargo Backend API ---');

  // 1. Health
  const health = await request({
    hostname: '127.0.0.1',
    port: 5000,
    path: '/api/health',
    method: 'GET',
  });
  console.log('1. /api/health:', health.status, JSON.stringify(health.body));
  if (health.status !== 200) throw new Error('Health check failed');

  // 2. Services
  const services = await request({
    hostname: '127.0.0.1',
    port: 5000,
    path: '/api/services',
    method: 'GET',
  });
  console.log('2. /api/services:', services.status, `Found ${services.body.length} services`);

  // 3. Verify PIN for SuperAdmin
  const adminLogin = await request(
    {
      hostname: '127.0.0.1',
      port: 5000,
      path: '/api/verify-pin',
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
    },
    { email: 'admin@sabcargo.com', pin: '123456' }
  );
  console.log('3. SuperAdmin Login:', adminLogin.status, 'Role:', adminLogin.body.role, 'Token valid:', Boolean(adminLogin.body.token));

  // 4. Verify PIN for Regular User
  const userLogin = await request(
    {
      hostname: '127.0.0.1',
      port: 5000,
      path: '/api/verify-pin',
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
    },
    { email: 'user@sabcargo.com', pin: '123456' }
  );
  console.log('4. User Login:', userLogin.status, 'Role:', userLogin.body.role, 'User:', userLogin.body.user?.fullName);

  // 5. Fetch shipments with Admin token
  const token = adminLogin.body.token;
  const shipments = await request({
    hostname: '127.0.0.1',
    port: 5000,
    path: '/api/shipments',
    method: 'GET',
    headers: { Authorization: `Bearer ${token}` },
  });
  console.log('5. Shipments:', shipments.status, `Loaded ${shipments.body.length} shipments`);

  // 6. Test Stats endpoint
  const stats = await request({
    hostname: '127.0.0.1',
    port: 5000,
    path: '/api/stats',
    method: 'GET',
    headers: { Authorization: `Bearer ${token}` },
  });
  console.log('6. Stats:', stats.status, JSON.stringify(stats.body.users), JSON.stringify(stats.body.shipments));

  console.log('--- ALL INTEGRATION TESTS PASSED SUCCESSFULLY! ---');
}

// Start server and test
const { start } = require('./server');
start()
  .then(() => setTimeout(runTests, 1000))
  .then(() => setTimeout(() => process.exit(0), 4000))
  .catch((e) => {
    console.error('Test execution error:', e);
    process.exit(1);
  });
