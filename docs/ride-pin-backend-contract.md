# Ride PIN backend contract (P-01/P-03)

The current `/api/v1/safety/pin` and `/api/v1/safety/pin/rotate` mock endpoints
issue a long-lived **per-user** PIN. They are demo behavior only; they cannot
authorize a real trip. The current rider client merely hides missing digits and
blocks mock issuance in release composition. A real ride PIN needs backend and
driver-app work before this safety feature can be promised in production.

## Required server behavior

1. On a confirmed ride, issue an independent four-digit PIN for that `ride_id`
   with a cryptographically secure generator. Bind it to rider and assigned
   driver, with an expiry and a short validity window around pickup. Store a
   salted, purpose-specific hash, not plaintext digits. The rider's authenticated
   `GET /api/v1/rides/{ride_id}/pin` returns the digits only while valid; never
   reuse the per-user safety PIN or return it for a different ride.
2. On rotation, invalidate the previous PIN atomically before returning new
   digits and a new version. Return explicit unavailable/error states if issuance
   fails; never allow either client to generate fallback digits. Do not cache the
   PIN for offline use or place it in logs, analytics, push payloads, or receipts.
3. The assigned driver app submits `POST /api/v1/rides/{ride_id}/pin/verify`
   with the entered digits and a stable idempotency key. Authenticate the driver,
   check assignment, ride state, expiry, version, and a constant-time hash match.
   Limit failed attempts per ride and driver, then lock out or require support.
   Responses should expose a code, never the expected PIN.
4. `POST /api/v1/rides/{ride_id}/start` must reject unverified attempts when
   verification is required. Verification and start authorization must be
   server-owned, transactionally bound to the same ride and driver; a UI check
   or a verify response alone cannot unlock trip start.
5. Define how reassignment, rider cancellation, driver cancellation, and ride
   expiration invalidate the PIN. Exercise cross-ride replay, brute-force,
   rotation races, offline clients, and driver reassignment in integration tests.

## Client integration remaining

Replace the per-user DTO and routes with the ride-scoped endpoints; include
`ride_id`, PIN version, expiration, and availability in the response. Refetch on
driver assignment and rotation. Render unavailable state on API errors. The
driver app must send verification to the backend and derive its start control
from the server's ride status. Only then may release compositions enable the
ride PIN feature. The long-lived locally persisted per-user PIN (P-06) should
be removed as part of that migration.
