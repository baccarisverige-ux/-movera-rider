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
- RideCheck events and timestamps (the app detects triggers itself until the
  server does)
- TripShare access / `shareToken`
- safety event status
- future audio-upload authorization

## HTTP contracts

```
GET/PATCH  /api/v1/safety/preferences
GET        /api/v1/safety/pin
POST       /api/v1/safety/pin/rotate
(PIN verify is a driver-app call, not the rider's: docs/ride-pin-backend-contract.md section 3)
GET/POST   /api/v1/safety/contacts
PATCH/DELETE /api/v1/safety/contacts/{id}
POST       /api/v1/safety/contacts/{id}/primary
POST/GET/PATCH/DELETE /api/v1/rides/{rideId}/share
GET/PATCH  /api/v1/safety/ridecheck/preferences
POST       /api/v1/safety/ridecheck/answers
POST/GET   /api/v1/rides/{rideId}/safety-events
POST       /api/v1/rides/{rideId}/safety-events/{eventId}/respond
POST       /api/v1/rides/{rideId}/safety-audio/init
POST       /api/v1/rides/{rideId}/safety-audio/{recordingId}/complete
DELETE     /api/v1/rides/{rideId}/safety-audio/{recordingId}
```

Writes send `Idempotency-Key`. Mock PIN is cached locally so web refresh works; that cache is not production PIN storage.

## Ride check

`RideCheckController` (application) watches the live trip with
`RideCheckMonitor` (domain) against the admin's triggers in
`RideCheckPolicy.triggers`: finished far from drop-off (driver taps Finish
more than admin's `finishFarFromDropoffKm`, default 3 km, from the drop-off;
the card opens right after finish), long stop (more than admin's
`longStopMinutes`, default 2 min), off the route (2 km or 50% longer) and
possible crash. A hit opens
`RideCheckLayer` (presentation): the dark-glass card at the top of the in-trip
screen and the ride summary. It cannot be dismissed without an answer. Red
rows and Call 112 alert the Movera safety team at once through
`POST /api/v1/safety/ridecheck/answers`; a Yes or Not sure updates the alert.
Answers are saved on the ride's safety event on this device first, so the
trip details (`RideCheckTripEntry`) always have them. Call 112 opens the
dialer (`tel:112`); Movera never calls. A Ride check recording uses
`SafetyAudioService.start(deviceOnly: true)` and never reaches Movera.

Demo builds (`allowsMockTransport`, e.g. the live web build): Safety ›
RideCheck › Try it (demo) plays "Driver finished far from drop-off" and
"Long stop" through the real monitor (`RideCheckController.playDemo`).

Hidden QA: `window.moveraSafetySnapshot()` (read-only, every build) and `window.moveraSimulateRideCheck(type, detail?)` (debug or `MOVERA_QA=true` builds only; installed from Dart, not `index.html`; see `docs/QA_HOOKS.md`).
