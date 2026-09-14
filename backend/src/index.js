const http = require('http');
const { quote } = require('./modules/pricing');
const safety = require('./modules/safety');

const idempotency = new Map();
const rides = new Map();

function send(res, status, body, requestId) {
  res.statusCode = status;
  res.setHeader('Content-Type', 'application/json');
  res.setHeader('X-Request-Id', requestId);
  res.setHeader('X-Api-Version', 'v1');
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

function nearby(ride) {
  const lat = ride && typeof ride.pickupLat === 'number' ? ride.pickupLat : null;
  const lng = ride && typeof ride.pickupLng === 'number' ? ride.pickupLng : null;
  if (lat == null || lng == null) return [];
  return [
    { id: 'veh_a', lat: lat + 0.0021, lng: lng - 0.0014, bearing: 42 },
    { id: 'veh_b', lat: lat - 0.0016, lng: lng + 0.0022, bearing: 210 },
    { id: 'veh_c', lat: lat + 0.0008, lng: lng + 0.0018, bearing: 128 },
  ];
}

const server = http.createServer(async (req, res) => {
  const requestId =
    req.headers['x-request-id'] || Math.random().toString(16).slice(2);
  const url = req.url.split('?')[0];
  const method = (req.method || 'GET').toUpperCase();
  const key = req.headers['idempotency-key'];

  if (key && idempotency.has(key)) {
    send(res, 200, idempotency.get(key), requestId);
    return;
  }

  if (url === '/health' && method === 'GET') {
    send(res, 200, { ok: true }, requestId);
    return;
  }

  if (url === '/api/v1/quotes' && method === 'POST') {
    const body = await readBody(req);
    const payload = { code: 'OK', quote: quote(body) };
    if (key) idempotency.set(key, payload);
    send(res, 200, payload, requestId);
    return;
  }

  if (url === '/api/v1/rides' && method === 'POST') {
    const body = await readBody(req);
    const ride = {
      id: `ride_${Date.now()}`,
      status: body.scheduledAt ? 'bookingRequested' : 'findingDriver',
      rideType: body.rideType || 'movera',
      price: body.price,
      paymentMethod: body.paymentMethod,
      pickupAddress: body.pickupAddress,
      destinationAddress: body.destinationAddress,
      pickupLat: body.pickupLat,
      pickupLng: body.pickupLng,
      destinationLat: body.destinationLat,
      destinationLng: body.destinationLng,
      scheduledAt: body.scheduledAt,
    };
    rides.set(ride.id, ride);
    const payload = { code: 'OK', ride };
    if (key) idempotency.set(key, payload);
    send(res, 200, payload, requestId);
    return;
  }

  const parts = url.split('/').filter(Boolean);
  // /api/v1/rides/:id/...
  if (parts[0] === 'api' && parts[1] === 'v1' && parts[2] === 'rides' && parts[3]) {
    const id = parts[3];
    const ride = rides.get(id);

    if (parts.length === 4 && method === 'GET') {
      if (!ride) {
        send(res, 404, { code: 'NOT_FOUND', message: 'Ride not found' }, requestId);
        return;
      }
      send(res, 200, { code: 'OK', ride }, requestId);
      return;
    }

    if (parts[4] === 'cancel' && method === 'POST') {
      const body = await readBody(req);
      if (!ride) {
        send(res, 404, { code: 'NOT_FOUND' }, requestId);
        return;
      }
      if (ride.status !== 'cancelledByRider') {
        ride.status = 'cancelledByRider';
        if (typeof body.reason === 'string') ride.cancellationReason = body.reason;
      }
      const payload = { code: 'OK', ride };
      if (key) idempotency.set(key, payload);
      send(res, 200, payload, requestId);
      return;
    }

    if (parts[4] === 'nearby' && method === 'GET') {
      send(res, 200, { code: 'OK', vehicles: nearby(ride) }, requestId);
      return;
    }

    if (parts[4] === 'status' && method === 'POST') {
      const body = await readBody(req);
      const next = ride || { id };
      next.status = body.status || next.status;
      if (body.driver) next.driver = body.driver;
      if (body.lat != null) next.driverLat = body.lat;
      if (body.lng != null) next.driverLng = body.lng;
      rides.set(id, next);
      const payload = { code: 'OK', ride: next };
      if (key) idempotency.set(key, payload);
      send(res, 200, payload, requestId);
      return;
    }

    if (parts.length === 4 && method === 'PATCH') {
      const body = await readBody(req);
      if (!ride) {
        send(res, 404, { code: 'NOT_FOUND' }, requestId);
        return;
      }
      if (body.price != null) ride.price = body.price;
      if (body.offerIncreaseKr != null) ride.offerIncreaseKr = body.offerIncreaseKr;
      ride.status = 'findingDriver';
      const payload = { code: 'OK', ride };
      if (key) idempotency.set(key, payload);
      send(res, 200, payload, requestId);
      return;
    }
  }

  if (url === '/api/v1/payments' && method === 'POST') {
    const body = await readBody(req);
    const payload = {
      code: 'OK',
      intent: {
        id: `pi_${requestId}`,
        status: 'succeeded',
        amountMinor: body.amountMinor || 0,
      },
    };
    if (key) idempotency.set(key, payload);
    send(res, 200, payload, requestId);
    return;
  }

  if (url === '/api/v1/wallet/topup' && method === 'POST') {
    const body = await readBody(req);
    const payload = {
      code: 'OK',
      status: 'succeeded',
      amountMinor: body.amountMinor || 0,
    };
    if (key) idempotency.set(key, payload);
    send(res, 200, payload, requestId);
    return;
  }

  const body = await readBody(req);
  const handled = await safety.handle(req, res, requestId, body);
  if (handled === false) {
    send(res, 404, { code: 'NOT_FOUND', message: 'Unknown route' }, requestId);
  }
});

const port = process.env.PORT || 8787;
server.listen(port, () => console.log(`movera backend mock :${port}`));
