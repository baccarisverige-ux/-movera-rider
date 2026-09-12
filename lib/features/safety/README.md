# Movera Safety

Phase 1: Profile / Side menu → Safety Hub.

No in-ride map Safety button in this phase. Home, Select Ride, Finding, and Waiting are unchanged.

## Swap to a real backend

Keep these:

- Safety Hub, PIN, contacts, share trip, RideCheck, tips screens
- `SafetyController` and domain models
- repository interfaces and DTOs

Replace only:

- `ApiSafetyRemoteDataSource` transport (`ApiClient` → live HTTPS)
- `InProcessMockClient` / `backend/src/modules/safety.js` with production handlers
- PIN hashing and share-token issuance on the server

Server-authoritative fields:

- PIN verification and ride-start PIN status
- RideCheck events and timestamps
- TripShare access / `shareToken`
- safety event status
- future audio-upload authorization

## HTTP contracts

```
GET/PATCH  /api/v1/safety/preferences
GET        /api/v1/safety/pin
POST       /api/v1/safety/pin/rotate
POST       /api/v1/rides/{rideId}/pin/verify
GET/POST   /api/v1/safety/contacts
PATCH/DELETE /api/v1/safety/contacts/{id}
POST       /api/v1/safety/contacts/{id}/primary
POST/GET/PATCH/DELETE /api/v1/rides/{rideId}/share
GET/PATCH  /api/v1/safety/ridecheck/preferences
POST/GET   /api/v1/rides/{rideId}/safety-events
POST       /api/v1/rides/{rideId}/safety-events/{eventId}/respond
POST       /api/v1/rides/{rideId}/safety-audio/init
POST       /api/v1/rides/{rideId}/safety-audio/{recordingId}/complete
DELETE     /api/v1/rides/{rideId}/safety-audio/{recordingId}
```

Writes send `Idempotency-Key`. Mock PIN is cached locally so web refresh works; that cache is not production PIN storage.

Hidden QA: `window.moveraSimulateRideCheck(type)`, `window.moveraSafetySnapshot()`.
