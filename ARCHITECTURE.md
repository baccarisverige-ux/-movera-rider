## Executed this pass (UI frozen)

Core maps/location/motion/api/realtime/auth/errors, ride state machine with
validated transitions, wallet ledger, quote + payment repositories, design
tokens, crash handlers, unit tests, architecture CI, and a mock `/api/v1`
backend + SQL schema. Approved screens were **moved** into feature folders. Visual design is unchanged.

## Brief 1–70 (code in this repo)

Approved UI is still the live Home/SelectRide/etc. New folders re-export those
screens. Cloud Postgres/Redis/Sentry/Stripe are interfaces + mock backend, not
hosted vendor accounts.

1 Clean Architecture folders + presentation/application/domain/data  
2 UI frozen  
3 Legacy inventory in this file; unused splash/onboarding/starter/withdraw removed  
4 Ride state machine + validated transitions  
5 Backend-owned quote/status contracts; UI displays  
6 Modular backend mock (auth/trips/pricing/payments/admin)  
7 SQL schema including ride_status_events  
8 `/api/v1` structured errors + request IDs  
9 Idempotency-Key on booking mock  
10 FareBreakdown formula  
11 Promotion domain  
12 MapFacade, camera, markers, lifecycle, location, routing  
13 MapProvider + GoogleMapProvider  
14–18 MotionEngine, interpolator, smoother, heading, cone  
19–22 Camera modes, marker store, no map-widget rewrite  
23–24 Realtime states + backoff sockets  
25 StaleGuard on geocoding/camera  
26 Lifecycle resume refreshes ride snapshot  
27 Structured failures  
28–30 Logger + crash reporter + zone handler (no secrets)  
31–33 ApiClient timeouts, GET retry only  
34 ConnectivityKind  
35 TokenStore (not SharedPreferences for tokens)  
36 No server secrets in Flutter  
37 PaymentRepository + PaymentGateway  
38 Wallet ledger  
39–42 Permissions, accuracy, geocoding repo, 320ms search debounce  
43 Active ride snapshot restore  
44 Scheduled rides remain booking variant in existing flow  
45 PushPayload  
46 FeatureFlags  
47 Admin mock surface in backend health modules  
48 AppEnv flavors  
49 Immutable Ride/Quote/Driver/Vehicle + DTO factory  
50 RideNavigator single API  
51 GetX kept, not mixed with Bloc/Riverpod  
52 Design system components  
53–55 Tokens, existing dispose paths, map park/resume  
56–58 Motion isolation + tests (heading wrap, GPS jump, lifecycle)  
59 Unit/widget/integration skeleton  
60 Error types + anti-abuse impossible travel  
61 Visual baseline remains the live approved app  
62 CI analyze + tests  
63 Incremental architecture commits  
64 Analytics booking/driver/cancel/payment events  
65 Request/ride IDs on API + logs  
66 TLS-only client, token store, least privilege comments  
67 AntiAbuse.impossibleTravel  
68 PrivacyPolicy retention constants  
69 Restore ride, reconnect backoff, last GPS via smoother  
70 Rules followed: no approved UI redesign, no guessed deletes  
