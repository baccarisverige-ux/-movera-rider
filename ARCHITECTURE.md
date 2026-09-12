# Movera Rider architecture

Approved UI is frozen. This file describes **runtime wiring**, not folder names.

## Status legend

- **DONE AND WIRED** — live screens depend on it
- **INTENTIONALLY MOCK** — contract exists, mock transport
- **BLOCKED BY EXTERNAL CREDENTIAL** — needs keys/URL/DSN

## Points 1–70

| POINT | STATUS | LIVE FILES USING IT | REMAINING WORK | BLOCKED BY CREDENTIALS? |
|---|---|---|---|---|
| 1 Clean architecture | DONE AND WIRED | `lib/features/*` | — | No |
| 2 UI frozen | DONE AND WIRED | Home, Select Ride, maps, sheets | — | No |
| 3 Legacy unused splash removed | DONE AND WIRED | git history | — | No |
| 4 Ride state machine | DONE AND WIRED | `ride_transition.dart`, tests | — | No |
| 5 Quotes/status contracts | DONE AND WIRED | `ApiQuoteRepository`, Select Ride | Swap transport to live URL | No (mock) |
| 6 Modular mock `/api/v1` | INTENTIONALLY MOCK | `InProcessMockClient`, `backend/` | Real hosted API | Yes for production host |
| 7 SQL schema | INTENTIONALLY MOCK | `backend/sql/0001_schema.sql` | Hosted Postgres | Yes |
| 8 Structured API errors | DONE AND WIRED | `ApiClient`, `ApiError` | — | No |
| 9 Idempotency-Key | DONE AND WIRED | booking, wallet, mock client | — | No |
| 10 FareBreakdown | DONE AND WIRED | quote breakdown + `FareRules` | — | No |
| 11 Promotion domain | DONE AND WIRED | `PromotionsController` | — | No |
| 12 MapFacade/camera/markers/routing | DONE AND WIRED | `AppScope.map`, `RoutingService` | No visual polyline added | No |
| 13 MapProvider | DONE AND WIRED | `GoogleMapProvider` | — | No |
| 14–18 MotionEngine | DONE AND WIRED | Home location + tests | No new moving driver pin | No |
| 19–22 Camera modes | DONE AND WIRED | `MapCameraController` | — | No |
| 23–24 Realtime + backoff | DONE AND WIRED | `MockRideRealtime`, Finding Driver | Real websocket | Yes for live socket |
| 25 StaleGuard | DONE AND WIRED | geocode, quotes, camera | — | No |
| 26 Lifecycle restore | DONE AND WIRED | `RideRestoreGate`, `RideRestoreCoordinator` | — | No |
| 27–30 Failures/logger/crash/zone | DONE AND WIRED | `bootstrap.dart`, `CrashReporter` | Sentry DSN | Yes for Sentry |
| 31–33 ApiClient | DONE AND WIRED | in-process mock transport | Live base URL | Yes for prod URL |
| 34 ConnectivityKind | DONE AND WIRED | typed status (logs/controllers, no new UI) | — | No |
| 35 TokenStore | DONE AND WIRED | `SecureTokenStore` (web = memory, not Keychain) | Native plugin optional | No |
| 36 No server secrets in Flutter | DONE AND WIRED | architecture tests | — | No |
| 37 PaymentRepository + gateway | INTENTIONALLY MOCK | Wallet → `MockPaymentGateway` | Stripe/Swish | Yes |
| 38 Wallet ledger | DONE AND WIRED | `WalletController` | — | No |
| 39–42 Permissions, GPS, geocode, 320ms search | DONE AND WIRED | Home | — | No |
| 43 Snapshot restore | DONE AND WIRED | restore coordinator | — | No |
| 44 Scheduled rides | DONE AND WIRED | `ScheduledRideSession` → booking API | — | No |
| 45 PushPayload | INTENTIONALLY MOCK | `NoopPushService` | FCM/APNs | Yes |
| 46 FeatureFlags | DONE AND WIRED | Select Ride payments | — | No |
| 47 Admin | BLOCKED | mock health list only | Separate admin app | Yes / separate repo |
| 48 AppEnv | DONE AND WIRED | `env.dart` | Real URLs | Yes for prod |
| 49 Immutable Ride/Quote/Driver | DONE AND WIRED | domain entities | — | No |
| 50 RideNavigator | DONE AND WIRED | wraps BottomToTop/RightToLeft | Screens keep existing pushes | No |
| 51 GetX | DONE AND WIRED | `GetMaterialApp` | — | No |
| 52 Design system present | DONE AND WIRED | tokens; screens keep CustomBtn | Do not replace approved widgets | No |
| 53–55 Tokens/dispose/map park | DONE AND WIRED | map lifecycle | — | No |
| 56–58 Motion tests | DONE AND WIRED | `test/motion` | — | No |
| 59 Tests | DONE AND WIRED | unit + launch integration | Broader device QA | No |
| 60–67 Errors, anti-abuse, analytics, IDs, TLS comments | DONE AND WIRED | tests + logs | — | No |
| 68 Privacy retention | DONE AND WIRED | snapshot `isFresh` 20 min | — | No |
| 69 Restore/reconnect/smoother | DONE AND WIRED | restore + realtime resync | — | No |
| 70 No redesign / no guessed deletes | DONE AND WIRED | this pass | — | No |

## How to replace mocks later

| Mock | Replace with |
|---|---|
| `InProcessMockClient` | `http.Client()` + real `AppEnv.apiBaseUrl` |
| `MockRideRealtime` | authenticated WebSocket implementing `RideRealtime` |
| `MockPaymentGateway` | Stripe/Swish adapter, same `PaymentGateway` |
| `NoopPushService` | FCM/APNs `PushService` |
| `CrashReporter` log-only | Sentry/Crashlytics behind same `record()` |
| `SecureTokenStore` web memory | keep Keychain/Keystore on iOS/Android; web is not equivalent |

## Web token storage

Browser-backed or in-memory tokens are **not** iOS Keychain / Android Keystore. Tokens are never written to SharedPreferences, git, URLs, or logs.
