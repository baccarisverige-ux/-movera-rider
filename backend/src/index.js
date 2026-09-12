const http = require('http');
const { quote } = require('./modules/pricing');

const idempotency = new Map();
const rides = new Map();

function send(res, status, body, requestId) {
  res.statusCode = status;
  res.setHeader('Content-Type', 'application/json');
  res.setHeader('X-Request-Id', requestId);
  res.end(JSON.stringify({ ...body, requestId }));
}

function readBody(req) {
  return new Promise((resolve) => {
    let raw = '';
    req.on('data', (c) => (raw += c));
    req.on('end', () => {
      try {
        resolve(raw ? JSON.parse(raw) : {});
      } catch {
        resolve({});
      }
    });
  });
}

const server = http.createServer(async (req, res) => {
  const requestId = Math.random().toString(16).slice(2);
  const url = req.url.split('?')[0];
  if (url === '/health') {
    send(res, 200, { ok: true, modules: ['auth', 'trips', 'pricing', 'payments', 'admin'] }, requestId);
    return;
  }
  if (url === '/api/v1/quotes' && req.method === 'POST') {
    const body = await readBody(req);
    send(res, 200, { code: 'OK', quote: quote(body) }, requestId);
    return;
  }
  if (url === '/api/v1/rides' && req.method === 'POST') {
    const key = req.headers['idempotency-key'];
    if (key && idempotency.has(key)) {
      send(res, 200, idempotency.get(key), requestId);
      return;
    }
    const ride = { id: `ride_${Date.now()}`, status: 'findingDriver' };
    rides.set(ride.id, ride);
    const payload = { code: 'OK', ride };
    if (key) idempotency.set(key, payload);
    send(res, 200, payload, requestId);
    return;
  }
  if (url.startsWith('/api/v1/rides/') && req.method === 'GET') {
    const id = url.split('/').pop();
    const ride = rides.get(id);
    if (!ride) {
      send(res, 404, { code: 'RIDE_NOT_FOUND', message: 'Ride not found' }, requestId);
      return;
    }
    send(res, 200, { code: 'OK', ride }, requestId);
    return;
  }
  send(res, 404, { code: 'NOT_FOUND', message: 'Unknown route' }, requestId);
});

const port = process.env.PORT || 8787;
server.listen(port, () => console.log(`movera backend mock :${port}`));
