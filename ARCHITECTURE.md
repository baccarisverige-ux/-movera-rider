# Movera Rider architecture

Approved UI is frozen. Status is **runtime wiring**, not folder names.

WaitingForDriver is the approved surface for assigned / arriving / in-progress.

Web snapshot key: `flutter.movera_active_ride` (`RideSnapshotStore.key`).

Previous landmark SHA `a82b70b` / “108 tests” is **historical**, not current proof.
Mocks remain intentional (in-process API, mock realtime, mock payments).
**Cancel-first:** tapping Cancel request runs `cancelSearch` + `RideSnapshotStore.clear`
before the optional why-sheet; Keep on the why-sheet must not restore Finding.
QA `window.movera*` hooks are gated (`kDebugMode` or `--dart-define=MOVERA_QA=true`).
See `docs/API_V1_MOCK.md`, `docs/UAT_CHECKLIST.md`, `docs/QA_HOOKS.md`.

## Canonical frontend state (existing names)

Do not invent a second source of truth. Runtime ride mutations use
`RideSession.restoreFromBackend` (not `transitionRide`).

| Concern | Owner |
|---|---|
| Live ride (in memory) | `AppScope.instance.ride` (`RideSession`) |
| Live ride persistence | `RideSnapshotStore` (`movera_active_ride`) |
| Book now submit lock | `AppScope.instance.booking` (`BookingCoordinator`) |
| Searching UI | `FindingDriverController` (`FindingDrivers`) |
| Matched / in-progress UI | `ActiveRideController` (`WaitingForDriver`) |
| Scheduled reservations | `AppScope.instance.reservations` (`ReservationController`) |
| Finished Book now History | `OnDemandRideHistoryStore` |
| Restore surface | `RideRestoreCoordinator` / `RideRestoreGate` |
| Category + payment on SelectRide | `RideSelectionController` |

Book now CTA must go through `BookingController` → `BookingRepository` →
`AppScope.instance.booking`. A second tap reuses the in-flight submit and must
not push a second `FindingDrivers`.

Cancel of a live Book now ride archives History (`archiveCancelledThenClear`)
then clears the snapshot. Reservations stay in `ReservationController` until
the frontend later promotes them.

Public web cold start restores a fresh snapshot (`RideRestoreCoordinator`).
The document-load wipe helper still exists for QA clear and is not invoked
on boot. BFCache `persisted == true` is not teardown.

## 20-phase completion pass

Historical phase table retained below for archaeology. Treat CI tip + `flutter test`
as current proof — do not cite frozen “108 tests” / `a82b70b` as live status.

## Remaining intentional mocks

These do **not** block local architecture completion:

- production backend / Postgres
- real WebSocket
- Stripe / Swish
- FCM / APNs
- Sentry / Crashlytics
- separate Admin app

`InProcessMockClient` + `backend/src/index.js` stay the v1 mock contract.
`AppEnv.current` remains `https://api.dev.movera.invalid`.

## Live

https://baccarisverige-ux.github.io/-movera-rider/
