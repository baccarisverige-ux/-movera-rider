# Movera Rider architecture

Approved UI is frozen. Status is **runtime wiring**, not folder names.

WaitingForDriver is the approved surface for assigned / arriving / in-progress.

Web snapshot key: `flutter.movera_active_ride` (`RideSnapshotStore.key`).

## How to replace mocks

| Mock | Replace with |
|---|---|
| `InProcessMockClient` | `http.Client()` + live `AppEnv.apiBaseUrl` |
| `MockRideRealtime` | WebSocket `RideRealtime` (reconnect still GET `/api/v1/rides/:id`) |
| `MockPaymentGateway` | Stripe/Swish `PaymentGateway` |
| `NoopPushService` | FCM/APNs |
| `CrashReporter` | Sentry/Crashlytics `record()` |
| `SecureTokenStore` | already Keychain/Keystore on iOS/Android; web stays memory |

## Points 1–70

| POINT | STATUS | ACTUAL LIVE USAGE | REMAINING WORK | EXTERNAL BLOCKER |
|---|---|---|---|---|
| 1 Clean architecture | DONE AND WIRED | `lib/features/*/application|data|domain|presentation` | — | No |
| 2 UI frozen | DONE AND WIRED | Home/Select Ride/Finding/Waiting | — | No |
| 3 Legacy unused removed | DONE AND WIRED | git | — | No |
| 4 Ride state machine | DONE AND WIRED | `ride_transition.dart` + tests | — | No |
| 5 Quotes/status | DONE AND WIRED | Select Ride → `ApiQuoteRepository` → mock `/api/v1/quotes` | Live URL | INTENTIONALLY MOCK host |
| 6 Modular mock API | INTENTIONALLY MOCK | `InProcessMockClient` + `backend/` | Hosted API | Yes |
| 7 SQL schema | INTENTIONALLY MOCK | `backend/sql` | Postgres | Yes |
| 8 Structured errors | DONE AND WIRED | `ApiClient`/`ApiError` | — | No |
| 9 Idempotency | DONE AND WIRED | booking, wallet, mock client | — | No |
| 10 Fare breakdown | DONE AND WIRED | quote + `FareRules` | — | No |
| 11 Promotions | DONE AND WIRED | Home ticket from `PromotionsController.homeCampaign()` | — | No |
| 12 Map facade | DONE AND WIRED | `MapFacade` upsert/drawRoute; Select Ride stores route; Home has no polyline | — | No |
| 13 MapProvider | DONE AND WIRED | `GoogleMapProvider` owner stack | — | No |
| 14–18 Motion | DONE AND WIRED | Home location + `test/motion` | No moving driver pin | NOT APPLICABLE BY APPROVED UI |
| 19–22 Camera | DONE AND WIRED | `MapCameraController` | — | No |
| 23–24 Realtime | DONE AND WIRED | `MockRideRealtime` + GET resync | Real websocket | INTENTIONALLY MOCK |
| 25 StaleGuard | DONE AND WIRED | geocode, quotes, camera | — | No |
| 26 Restore | DONE AND WIRED | `RideRestoreGate` cold start; resume only at root | — | No |
| 27–30 Crash/zone | DONE AND WIRED | `bootstrap.dart` | Sentry DSN | BLOCKED |
| 31–33 ApiClient | DONE AND WIRED | in-process mock default | Live URL | BLOCKED for prod URL |
| 34 Connectivity | DONE AND WIRED | typed, logs only | No new banners | NOT APPLICABLE BY APPROVED UI |
| 35 TokenStore | DONE AND WIRED | `flutter_secure_storage` iOS/Android; memory web/CI | — | No |
| 36 No secrets in lib | DONE AND WIRED | architecture tests | — | No |
| 37 Payments | INTENTIONALLY MOCK | `WalletController.topUp` → mock gateway | Stripe/Swish | Yes |
| 38 Wallet ledger | DONE AND WIRED | topUp/redeemVoucher/chargeRide/refund | — | No |
| 39–42 Location/search | DONE AND WIRED | Home + 320ms search | — | No |
| 43 Snapshot restore | DONE AND WIRED | coordinator; Home restore removed | — | No |
| 44 Scheduled rides | DONE AND WIRED | `ScheduledRideSession` → mock booking | — | No |
| 45 Push | INTENTIONALLY MOCK | `NoopPushService` | FCM/APNs | Yes |
| 46 Feature flags | DONE AND WIRED | Select Ride payments | — | No |
| 47 Admin | BLOCKED BY EXTERNAL CREDENTIAL | health list only | Separate app | Yes |
| 48 AppEnv | DONE AND WIRED | `env.dart` | Prod URL | Yes |
| 49 Immutable entities | DONE AND WIRED | Ride/Quote/Driver | — | No |
| 50 RideNavigator | DONE AND WIRED | wraps existing transitions | Screens keep BottomToTop | No |
| 51 GetX | DONE AND WIRED | `GetMaterialApp` | — | No |
| 52 Design system | DONE AND WIRED | tokens; CustomBtn kept | — | NOT APPLICABLE BY APPROVED UI |
| 53–55 Dispose/map park | DONE AND WIRED | owner detach; Home no longer disposes global map | — | No |
| 56–58 Motion tests | DONE AND WIRED | `test/motion` | — | No |
| 59 Tests | DONE AND WIRED | unit + restore/realtime/quotes/maps | Broader device | No |
| 60–67 Errors/anti-abuse/analytics/IDs | DONE AND WIRED | tests + logs | — | No |
| 68 Privacy | DONE AND WIRED | snapshot 20 min | — | No |
| 69 Restore/reconnect | DONE AND WIRED | GET ride on reconnect | — | No |
| 70 No redesign | DONE AND WIRED | this pass | — | No |
