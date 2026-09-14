# Movera Rider API v1 — in-process mock contract

This documents `InProcessMockClient` (`lib/core/api/in_process_mock_client.dart`)
and the aligned Node mock in `backend/src/index.js`.

No Postgres, Stripe, hosted API, or real auth. In-memory only.
`AppEnv.current` stays on `https://api.dev.movera.invalid`.

## Headers

| Header | Required | Notes |
|---|---|---|
| `X-Request-Id` | yes (client always sends) | Echoed on responses |
| `Idempotency-Key` | mutating POSTs | Same key returns cached 200 body |
| `X-Api-Version` | yes | Always `v1` from `ApiClient` |
| `Authorization` | optional | Bearer access token when present |
| `Content-Type` | JSON bodies | `application/json` |

## Routes

### `GET /health`

```json
{ "ok": true, "requestId": "…" }
```

### `POST /api/v1/quotes`

Body: `{ rideType?, pickup?, destination?, … }`

Quote fields:

- `id` and `quoteId` are **identical**
- `currency`: `SEK`
- `expiresInSec`: `120` (also `expiresAt` ISO in Dart mock)
- `totalMinor` / `amountMinor` from catalog prices
- `breakdown`, `signedPayload: "mock-api"`

Response: `{ "code": "OK", "quote": {…}, "requestId" }`

### `POST /api/v1/rides`

Creates an in-memory ride. Status `findingDriver`, or `bookingRequested` when
`scheduledAt` is set.

Response: `{ "code": "OK", "ride": { id, status, … }, "requestId" }`

### `GET /api/v1/rides/:id`

Returns the ride or `404 NOT_FOUND`.

### `POST /api/v1/rides/:id/cancel`

Sets `cancelledByRider`. Optional body `{ "reason": "…" }`.
Idempotent if already cancelled. `404` if unknown id.

### `GET /api/v1/rides/:id/nearby`

Returns mock vehicles near pickup lat/lng.

### `POST /api/v1/rides/:id/status`

Updates status / driver / lat / lng (QA / realtime helper).

### `PATCH /api/v1/rides/:id`

Price bump: `{ "price", "offerIncreaseKr?" }` → stays `findingDriver`.

### `POST /api/v1/payments`

Mock payment intent `{ id, status: "succeeded", amountMinor }`.

### `POST /api/v1/wallet/topup`

Mock top-up `{ status: "succeeded", amountMinor }`.

### Safety

Unhandled `/api/v1/...` paths may be handled by `SafetyMockApi` /
`backend/src/modules/safety.js` (share, contacts, ride-check, etc.).

## Intentional mocks

SQL under `backend/sql` remains documentation only. Do not wire a database here.
