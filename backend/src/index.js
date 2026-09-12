const http = require('http');

const modules = [
  'auth', 'users', 'riders', 'drivers', 'vehicles', 'trips', 'dispatch',
  'pricing', 'payments', 'promotions', 'locations', 'notifications',
  'messaging', 'ratings', 'support', 'safety', 'admin',
];

const server = http.createServer((req, res) => {
  const requestId = Math.random().toString(16).slice(2);
  res.setHeader('Content-Type', 'application/json');
  res.setHeader('X-Request-Id', requestId);
  if (req.url === '/health') {
    res.end(JSON.stringify({ ok: true, requestId, modules }));
    return;
  }
  if (req.url === '/api/v1/quotes' && req.method === 'POST') {
    res.end(JSON.stringify({
      code: 'OK',
      requestId,
      quote: { id: 'q_demo', amountMinor: 19900, currency: 'SEK', expiresInSec: 120 },
    }));
    return;
  }
  res.statusCode = 404;
  res.end(JSON.stringify({
    code: 'NOT_FOUND',
    message: 'Unknown route',
    requestId,
  }));
});

const port = process.env.PORT || 8787;
server.listen(port, () => {
  console.log(`movera backend mock :${port}`);
});
