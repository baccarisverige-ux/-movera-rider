# Movera Rider UAT checklist

Manual / live checks derived from QA live Rider flow, plus cancel-first and
book-later regressions. Public Pages builds do **not** expose `window.movera*`
hooks unless built with debug or `--dart-define=MOVERA_QA=true`.

## Automated coverage (CI gates)

- `Global E2E UAT` (`.github/workflows/global-e2e-uat.yml`) — every push/PR:
  runs the full `flutter test` unit/widget suite (all areas under `test/`)
  plus `integration_test/` against the in-process mock backend. Phase 13
  permanently adds `integration_test/rider_full_uat_test.dart`, which drives
  the full ride lifecycle through ratingPending, driver-cancel re-search,
  external terminal states, reconnect/resync, ride-scoped messages/unread
  state, and Safety controller/store behavior. The existing
  `integration_test/global_uat_flow_test.dart` continues to drive booking,
  wallet top-up/debit, reservation create+cancel, and profile update through
  the real controllers in one flow.
- `Architecture gates` (`.github/workflows/architecture-gates.yml`) — analyze
  + unit/widget suite.
- `QA live Rider flow` / `QA Book now two paths` — live-site Playwright E2E,
  ride-booking path only (see below); these still require manual/QA-build
  follow-up for the areas they skip.

The controller/contract scenarios above are now automated. The checklist
below remains for live-browser/device behavior that cannot be truthfully
fabricated by the public build.

## Smoke

- [ ] Home loads without fatal console errors
- [ ] Destination → pickup confirm → Select Ride categories
- [ ] Fare stepper and payment sheet (Cash) change UI
- [ ] Book now → Finding Drivers
- [ ] Matching eventually opens Waiting (or assign via QA build)

## Cancel-first

- [ ] On Finding, open cancel → **Cancel request** immediately stops matching
- [ ] Why-sheet is optional after Cancel request
- [ ] **Keep ride** on why-sheet does **not** restore Finding — stay Home
- [ ] Late assign after Cancel request does not open Waiting / Finding
- [ ] Same cancel-first behavior on Waiting

## Book later

- [ ] Book for later date/time → Ride scheduled (or schedule confirmation)
- [ ] Book-later must **not** open Finding Drivers

## Restore

- [ ] Seeded Finding restore (QA build) first surface is Finding, not Home
- [ ] Seeded Waiting restore first surface is Waiting, not Home
- [ ] After cancel, cold restore / resume stays Home

## Safety / map (QA or manual)

- [ ] Safety hub from menu
- [ ] Nested pickup map owner does not stick after back
- [ ] Select Ride → Finding → Waiting map owners advance

## Wallet

- [ ] Top-up succeeds and balance reflects the credited amount
- [ ] Injected top-up failure surfaces an error, does not silently credit
- [ ] Voucher redemption applies once; expired/unknown codes are rejected
- [ ] Ride debit against wallet balance matches the ride price

## Reservations / scheduled rides

- [ ] Creating a reservation puts it in Upcoming with the entered pickup/drop
- [ ] Editing a reservation (time, note, category) updates the same record
- [ ] Cancelling moves it out of Upcoming and into Cancelled with a reason
- [ ] "Plan a return ride" pre-fills pickup/drop swapped from the origin leg
- [ ] Driver auto-assigns and status advances as pickup time approaches

## Profile / account

- [ ] Editing name/email/phone persists across app restart
- [ ] Two-step / passkey / recovery-phone toggles reflect in `checkupComplete`
- [ ] Notification and marketing preference toggles persist

## Mock contract

- [ ] Quotes return `quoteId == id`, SEK, ~120s expiry
- [ ] Ride create / cancel / nearby / price bump work on in-process mock
