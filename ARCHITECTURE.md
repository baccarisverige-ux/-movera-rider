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
