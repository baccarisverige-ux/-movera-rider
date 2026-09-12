const crypto = require('crypto');

const preferences = new Map();
const pins = new Map();
const contacts = new Map();
const shares = new Map();
const events = [];
const recordings = [];

function now() {
  return new Date().toISOString();
}

function userIdFrom(req) {
  const header = req.headers.authorization || '';
  return header.replace(/^Bearer\s+/i, '') || 'rider-local';
}

function ensurePin(userId) {
  if (!pins.has(userId)) {
    pins.set(userId, {
      pinId: `pin_${Date.now()}`,
      userId,
      pin: String(Math.floor(Math.random() * 10000)).padStart(4, '0'),
      required: false,
      rotatedAt: now(),
      version: 1,
      serverAuthoritative: true,
    });
  }
  return pins.get(userId);
}

function ensurePrefs(userId) {
  if (!preferences.has(userId)) {
    preferences.set(userId, {
      userId,
      pinRequired: false,
      tripShareEnabled: false,
      tripShareMode: 'manual',
      tripShareContactIds: [],
      rideCheckEnabled: false,
      updatedAt: now(),
      version: 1,
    });
  }
  return preferences.get(userId);
}

function json(res, status, body, requestId) {
  res.statusCode = status;
  res.setHeader('Content-Type', 'application/json');
  res.setHeader('X-Request-Id', requestId);
  res.end(JSON.stringify({ ...body, requestId }));
}

async function handle(req, res, requestId, body = {}) {
  const url = req.url.split('?')[0];
  const method = req.method.toUpperCase();
  const userId = userIdFrom(req);

  if (url === '/api/v1/safety/preferences' && method === 'GET') {
    return json(res, 200, { code: 'OK', preferences: ensurePrefs(userId) }, requestId);
  }
  if (url === '/api/v1/safety/preferences' && method === 'PATCH') {
    const prefs = Object.assign(ensurePrefs(userId), body, { userId, updatedAt: now() });
    preferences.set(userId, prefs);
    const pin = ensurePin(userId);
    pin.required = prefs.pinRequired === true;
    return json(res, 200, { code: 'OK', preferences: prefs }, requestId);
  }
  if (url === '/api/v1/safety/pin' && method === 'GET') {
    return json(res, 200, { code: 'OK', pin: ensurePin(userId) }, requestId);
  }
  if (url === '/api/v1/safety/pin/rotate' && method === 'POST') {
    const pin = ensurePin(userId);
    pin.pin = String(Math.floor(Math.random() * 10000)).padStart(4, '0');
    pin.pinId = `pin_${Date.now()}`;
    pin.rotatedAt = now();
    pin.version += 1;
    return json(res, 200, { code: 'OK', pin }, requestId);
  }
  const verify = url.match(/^\/api\/v1\/rides\/([^/]+)\/pin\/verify$/);
  if (verify && method === 'POST') {
    const pin = ensurePin(userId);
    const valid = String(body.pin || '') === pin.pin;
    if (pin.required && !valid) {
      return json(res, 409, { code: 'PIN_INVALID', valid: false, rideId: verify[1], serverAuthoritative: true }, requestId);
    }
    return json(res, 200, { code: 'OK', valid, rideId: verify[1] }, requestId);
  }
  if (url === '/api/v1/safety/contacts' && method === 'GET') {
    const list = [...contacts.values()].filter((c) => c.userId === userId);
    return json(res, 200, { code: 'OK', contacts: list }, requestId);
  }
  if (url === '/api/v1/safety/contacts' && method === 'POST') {
    const list = [...contacts.values()].filter((c) => c.userId === userId);
    if (list.length >= 5) return json(res, 409, { code: 'CONTACT_LIMIT' }, requestId);
    const row = {
      id: body.id || `ec_${crypto.randomUUID()}`,
      userId,
      name: body.name,
      phoneE164: body.phoneE164,
      relationship: body.relationship || 'Other',
      isPrimary: list.length === 0 || body.isPrimary === true,
      shareTrips: body.shareTrips === true,
      isEnabled: body.isEnabled !== false,
      createdAt: now(),
      updatedAt: now(),
    };
    contacts.set(row.id, row);
    return json(res, 200, { code: 'OK', contact: row }, requestId);
  }
  const contact = url.match(/^\/api\/v1\/safety\/contacts\/([^/]+)$/);
  if (contact && method === 'PATCH') {
    const row = contacts.get(contact[1]);
    if (!row || row.userId !== userId) return json(res, 404, { code: 'NOT_FOUND' }, requestId);
    Object.assign(row, body, { id: row.id, userId, updatedAt: now() });
    return json(res, 200, { code: 'OK', contact: row }, requestId);
  }
  if (contact && method === 'DELETE') {
    const row = contacts.get(contact[1]);
    if (row && row.userId === userId) contacts.delete(contact[1]);
    return json(res, 200, { code: 'OK' }, requestId);
  }
  const primary = url.match(/^\/api\/v1\/safety\/contacts\/([^/]+)\/primary$/);
  if (primary && method === 'POST') {
    for (const row of contacts.values()) {
      if (row.userId === userId) row.isPrimary = row.id === primary[1];
    }
    const list = [...contacts.values()].filter((c) => c.userId === userId);
    return json(res, 200, { code: 'OK', contacts: list }, requestId);
  }
  const share = url.match(/^\/api\/v1\/rides\/([^/]+)\/share$/);
  if (share) {
    const rideId = share[1];
    if (method === 'POST') {
      const row = {
        shareId: `share_${rideId}`,
        rideId,
        userId,
        contactIds: body.contactIds || [],
        shareToken: `tok_${crypto.randomUUID()}`,
        isActive: true,
        startedAt: now(),
        expiresAt: new Date(Date.now() + 6 * 3600 * 1000).toISOString(),
        serverAuthoritative: true,
      };
      shares.set(rideId, row);
      return json(res, 200, { code: 'OK', share: row }, requestId);
    }
    if (method === 'GET') {
      const row = shares.get(rideId);
      if (!row) return json(res, 404, { code: 'NOT_FOUND' }, requestId);
      return json(res, 200, { code: 'OK', share: row }, requestId);
    }
    if (method === 'PATCH') {
      const row = Object.assign({}, shares.get(rideId) || {}, body, { rideId, userId });
      shares.set(rideId, row);
      return json(res, 200, { code: 'OK', share: row }, requestId);
    }
    if (method === 'DELETE') {
      const row = shares.get(rideId);
      if (row) row.isActive = false;
      return json(res, 200, { code: 'OK' }, requestId);
    }
  }
  if (url === '/api/v1/safety/ridecheck/preferences' && method === 'GET') {
    const prefs = ensurePrefs(userId);
    return json(res, 200, { code: 'OK', policy: { enabled: prefs.rideCheckEnabled, userId } }, requestId);
  }
  if (url === '/api/v1/safety/ridecheck/preferences' && method === 'PATCH') {
    const prefs = ensurePrefs(userId);
    prefs.rideCheckEnabled = body.enabled === true;
    prefs.updatedAt = now();
    return json(res, 200, { code: 'OK', policy: { enabled: prefs.rideCheckEnabled, userId, updatedAt: prefs.updatedAt } }, requestId);
  }
  const safetyEvents = url.match(/^\/api\/v1\/rides\/([^/]+)\/safety-events$/);
  if (safetyEvents && method === 'POST') {
    const event = {
      eventId: body.eventId || `ev_${crypto.randomUUID()}`,
      rideId: safetyEvents[1],
      userId,
      type: body.type,
      status: body.status || 'pending',
      at: body.at || now(),
      payload: body.payload || {},
      serverAuthoritative: true,
    };
    const dup = events.find((e) => e.eventId === event.eventId);
    if (dup) return json(res, 200, { code: 'OK', event: dup }, requestId);
    events.push(event);
    return json(res, 200, { code: 'OK', event }, requestId);
  }
  if (safetyEvents && method === 'GET') {
    return json(res, 200, { code: 'OK', events: events.filter((e) => e.rideId === safetyEvents[1]) }, requestId);
  }
  const respond = url.match(/^\/api\/v1\/rides\/([^/]+)\/safety-events\/([^/]+)\/respond$/);
  if (respond && method === 'POST') {
    const event = events.find((e) => e.eventId === respond[2]);
    if (!event) return json(res, 404, { code: 'NOT_FOUND' }, requestId);
    event.status = body.action === 'resolved' ? 'resolved' : 'acknowledged';
    return json(res, 200, { code: 'OK', event }, requestId);
  }
  const audioInit = url.match(/^\/api\/v1\/rides\/([^/]+)\/safety-audio\/init$/);
  if (audioInit && method === 'POST') {
    const rec = {
      id: `aud_${crypto.randomUUID()}`,
      rideId: audioInit[1],
      createdAt: now(),
      uploadStatus: 'localOnly',
      encryptionState: 'local',
      durationMs: 0,
    };
    recordings.push(rec);
    return json(res, 200, { code: 'OK', recording: rec }, requestId);
  }
  const audio = url.match(/^\/api\/v1\/rides\/([^/]+)\/safety-audio\/([^/]+)(\/complete)?$/);
  if (audio && method === 'POST' && audio[3]) {
    const rec = recordings.find((r) => r.id === audio[2]);
    if (!rec) return json(res, 404, { code: 'NOT_FOUND' }, requestId);
    rec.endedAt = now();
    rec.durationMs = body.durationMs || 0;
    return json(res, 200, { code: 'OK', recording: rec }, requestId);
  }
  if (audio && method === 'DELETE') {
    const idx = recordings.findIndex((r) => r.id === audio[2]);
    if (idx >= 0) recordings.splice(idx, 1);
    return json(res, 200, { code: 'OK' }, requestId);
  }
  return false;
}

module.exports = { handle, preferences, pins, contacts, shares, events, recordings };
