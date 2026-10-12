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

### `GET /api/v1/promotions`

Promotions this rider can use. Each: `id`, `code`, `title`, `kind` (`percent` | `fixed`),
`value`, `maxPerRideMinor`, `minFareMinor`, `ridesLeft`, `validFrom`, `validTo`,
`categories` (empty = all), `popup`, optional `message`. The mock seeds `WELCOME30`
as a popup. Response: `{ "code": "OK", "promotions": [...], "requestId" }`

### `POST /api/v1/promotions/redeem`

Body: `{ code }`. Known mock codes: `AUTUMN15`, `THANKYOU20`, `FLAT40`; `OLDCODE` has ended.
Errors: `404 PROMO_NOT_FOUND`, `410 PROMO_EXPIRED`, `409 PROMO_ALREADY_USED`,
`403 PROMO_NOT_FOR_RIDER` (backend only). Response: `{ "code": "OK", "promotion": {...}, "requestId" }`

`POST /api/v1/quotes` also takes `promoCode`; when the rider has that promotion the
quote's `totalMinor` is lowered and `discountMinor` and `promotion` are set.

### Safety

Unhandled `/api/v1/...` paths may be handled by `SafetyMockApi` /
`backend/src/modules/safety.js` (share, contacts, ride-check, etc.).

## Intentional mocks

SQL under `backend/sql` remains documentation only. Do not wire a database here.
