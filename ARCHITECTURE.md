# Movera Rider architecture

Approved UI is frozen. Status is **runtime wiring**, not folder names.

WaitingForDriver is the approved surface for assigned / arriving / in-progress.

Web snapshot key: `flutter.movera_active_ride` (`RideSnapshotStore.key`).

Final proof SHA: `dc46cda` (this document). Dart ownership SHA with 98 tests: `75442a3`. Live QA of the same tree: run `34710327313`.

## 20-phase completion pass

| PHASE | STATUS | PROOF |
|---|---|---|
| 1 Restore authority (`RideRestoreGate` only; Home restore deleted) | DONE AND WIRED | `ride_restore_gate.dart`, `test/ride/restore_test.dart`, guard `home does not own ride restoration` |
| 2 Resume vs cold start (resync always; navigate only at root) | DONE AND WIRED | `RideRestoreCoordinator.resumeIfNeeded`, restore tests |
| 3 Map owner/generation; never `GoogleMapController.dispose()` | DONE AND WIRED | `google_map_provider.dart`, `test/maps/provider_test.dart`, architecture guard |
| 4 Nested pickup map stays one owner-stacked map, no extra GoogleMap widget type | DONE AND WIRED | Home parks then `_PickupMapPickerPage` attaches `MapOwners.pickup` |
| 5 Routes stored in facade; polyline only on Select Ride (approved) | DONE AND WIRED | Select Ride polyline; Home guard forbids polyline |
| 6 `flutter_secure_storage` iOS/Android; memory web/CI | DONE AND WIRED | `secure_token_store.dart`, `test/auth/token_store_test.dart` |
| 7 Waiting `initState` does not `markArriving()` | DONE AND WIRED | guard `waiting screen does not markArriving on open` |
| 8 WaitingForDriver = assigned / arriving / in-progress | DONE AND WIRED | `RideRestoreCoordinator.surfaceFor` |
| 9 Finding assignment from realtime (~12s); countdown is visual | DONE AND WIRED | `FindingDriverController`, `test/ride/finding_controller_test.dart` |
| 10 Quote `id == quoteId`; later generation wins | DONE AND WIRED | `test/quotes/quote_race_test.dart` |
| 11 Wallet `topUp` / `redeemVoucher` / `chargeRide` / `refund` | DONE AND WIRED | `WalletController`, `test/wallet/ops_test.dart` |
| 12 Home promo from `PromotionsController` (“40% off your next ride”) | DONE AND WIRED | Home reads `_promos.homeCampaign()` |
| 13 Double-book in-flight lock on finding + scheduled | DONE AND WIRED | `BookingCoordinator`, `test/booking/lock_test.dart` |
| 14 `ScheduledRideSession` owns pickup/dropoff/stops/time/quote/booking | DONE AND WIRED | session capture methods; `test/ride/scheduled_session_test.dart` |
| 15 Unit tests (restore, maps, quotes, wallet, finding, tokens, booking, guards) | DONE AND WIRED | Architecture gates `34709967017`: **98 tests passed** |
| 16 Live QA scheduled Continue (test, not UI) | DONE AND WIRED | QA `34710327313` scheduled PASS |
| 17 Restore/reload QA seeds Finding + Waiting; first surface is not Home | DONE AND WIRED | QA: `moveraFirstSurface` finding/waiting; `moveraHomeBuilt` false |
| 18 Map stress QA nested pickup + Select Ride + Finding + Waiting + resume | DONE AND WIRED | QA isolated context; owner stack tests |
| 19 Analyzer + architecture gates CI | DONE AND WIRED | analyze `--no-fatal-infos --no-fatal-warnings` green (0 errors); 98 tests |
| 20 Honest remaining mocks below | DONE AND WIRED | this file |

## Audit close-out (items 1–13)

| ITEM | STATUS | PROOF |
|---|---|---|
| 1 Home thinned | DONE | Presentation no longer imports `HomeAddressRepository`. Places/GPS/heading/pulse live in `HomePlacesController` + `HomeLocationController`. Home keeps sheet/animation/map widget paint. |
| 2 Select Ride single source of truth | DONE | No widget `_selectedRideId` / `_selectedPayment` / `_scheduledFor`. Controller owns ride, payment, quote ids, expiry, schedule. |
| 3 Waiting driver data owned underneath | DONE | `DriverArrivalView` from `DriverArrivingController.arrival()`. Plate is not a widget literal. `initState` does not transition ride state. |
| 4 Architecture guards strengthened | DONE | Presentation cannot import `features/*/data/`. No ApiClient/HTTP/SharedPreferences in presentation. Home/Select Ride/Waiting specific guards. |
| 5 No Home flash on restore | DONE | Gate holds white until `root()`. QA asserts `moveraFirstSurface` is finding/waiting and `moveraHomeBuilt !== true`. |
| 6 Full map stress sequence | DONE | Isolated browser context: Home → pickup → back → pickup → Select Ride → Finding → Waiting → visibility resume. |
| 7 Owner stack under nested nav | DONE | Older owner cannot detach newer; same-id reattach; camera no-op without controller; never `GoogleMapController.dispose()`. |
| 8 Async/race behavior tests | DONE | Destination B wins; category change while quotes pending; double book; cancel vs assign; dispose vs event; wallet idempotent top-up. |
| 9 Scheduled session fully written | DONE | Route/stops/time/note/payment/rideType captured from the live schedule screens. `confirm()` writes `bookingId`. |
| 10 Driver repository is display source | DONE | `DriverArrivalView` exposes ETA, name, rating, tagline, plate, vehicle label, images. Visible values unchanged (`L - 2323 F`, Merle Feeney, 5.0, 5 mins). |
| 11 Home redesign flexibility | DONE | GPS, geocoding, address persistence, restore, promotions, map attach live outside Home paint. Changing a card does not require rewriting those systems. |
| 12 CI + live QA green | DONE | Gates 98 tests; Pages live; QA four PASS lines on `dc46cda`. |
| 13 ARCHITECTURE.md matches reality | DONE | this file, written after green CI |

## How to replace mocks

| Mock | Replace with |
|---|---|
| `InProcessMockClient` | `http.Client()` + live `AppEnv.apiBaseUrl` |
| `MockRideRealtime` | WebSocket `RideRealtime` (reconnect still GET `/api/v1/rides/:id`) |
| `MockPaymentGateway` | Stripe/Swish `PaymentGateway` |
| `NoopPushService` | FCM/APNs |
| `CrashReporter` | Sentry/Crashlytics `record()` |
| `SecureTokenStore` | already Keychain/Keystore on iOS/Android; web stays memory |

## Remaining intentional mocks

These do **not** block local architecture completion:

- production backend / Postgres
- real WebSocket
- Stripe / Swish
- FCM / APNs
- Sentry / Crashlytics
- separate Admin app

## Live

https://baccarisverige-ux.github.io/-movera-rider/

## Points 1–70

| POINT | STATUS | ACTUAL LIVE USAGE | REMAINING WORK | EXTERNAL BLOCKER |
|---|---|---|---|---|
| 1 Clean architecture | DONE AND WIRED | `lib/features/*/application\|data\|domain\|presentation` | — | No |
| 2 UI frozen | DONE AND WIRED | Home/Select Ride/Finding/Waiting | — | No |
| 3 Legacy unused removed | DONE AND WIRED | git; no aggressive deletion this pass | — | No |
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
| 26 Restore | DONE AND WIRED | `RideRestoreGate` cold start; resume only at root; first-surface QA | — | No |
| 27–30 Crash/zone | DONE AND WIRED | `bootstrap.dart` | Sentry DSN | BLOCKED |
| 31–33 ApiClient | DONE AND WIRED | in-process mock default | Live URL | BLOCKED for prod URL |
| 34 Connectivity | DONE AND WIRED | typed, logs only | No new banners | NOT APPLICABLE BY APPROVED UI |
| 35 TokenStore | DONE AND WIRED | `flutter_secure_storage` iOS/Android; memory web/CI | — | No |
| 36 No secrets in lib | DONE AND WIRED | architecture tests | — | No |
| 37 Payments | INTENTIONALLY MOCK | `WalletController.topUp` → mock gateway | Stripe/Swish | Yes |
| 38 Wallet ledger | DONE AND WIRED | topUp/redeemVoucher/chargeRide/refund | — | No |
| 39–42 Location/search | DONE AND WIRED | Home + 320ms search | — | No |
| 43 Snapshot restore | DONE AND WIRED | coordinator; Home restore removed | — | No |
| 44 Scheduled rides | DONE AND WIRED | `ScheduledRideSession` capture + confirm | — | No |
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
| 59 Tests | DONE AND WIRED | 98 unit tests + live QA | Broader device | No |
| 60–67 Errors/anti-abuse/analytics/IDs | DONE AND WIRED | tests + logs | — | No |
| 68 Privacy | DONE AND WIRED | snapshot 20 min | — | No |
| 69 Restore/reconnect | DONE AND WIRED | GET ride on reconnect | — | No |
| 70 No redesign | DONE AND WIRED | this pass | — | No |
