import 'package:flutter/material.dart';
import 'package:movera_rider/app/lifecycle/app_lifecycle.dart';
import 'package:movera_rider/app/navigator_key.dart';
import 'package:movera_rider/app/config/env.dart';
import 'package:movera_rider/app/config/pin_composition.dart';
import 'package:movera_rider/app/config/transport_composition.dart';
import 'package:movera_rider/app/config/auth_composition.dart';
import 'package:movera_rider/core/api/api_client.dart';
import 'package:movera_rider/core/auth/secure_token_store.dart';
import 'package:movera_rider/core/auth/token_store.dart';
import 'package:movera_rider/core/feature_flags/feature_flags.dart';
import 'package:movera_rider/core/location/app_geocoding.dart';
import 'package:movera_rider/core/location/location_repository.dart';
import 'package:movera_rider/core/location/place_search.dart';
import 'package:movera_rider/core/logging/crash_reporter.dart';
import 'package:movera_rider/core/maps/google_map_provider.dart';
import 'package:movera_rider/core/maps/map_camera_controller.dart';
import 'package:movera_rider/core/maps/map_facade.dart';
import 'package:movera_rider/core/maps/map_lifecycle.dart';
import 'package:movera_rider/core/maps/marker_store.dart';
import 'package:movera_rider/core/maps/routing_service.dart';
import 'package:movera_rider/core/motion/motion_engine.dart';
import 'package:movera_rider/core/notifications/firebase_push_service.dart';
import 'package:movera_rider/core/notifications/push_service.dart';
import 'package:movera_rider/core/observability/http_observability.dart';
import 'package:movera_rider/core/observability/observability.dart';
import 'package:movera_rider/core/payments/api_payment_gateway.dart';
import 'package:movera_rider/core/payments/mock_payment_gateway.dart';
import 'package:movera_rider/core/payments/payment_gateway.dart';
import 'package:movera_rider/core/permissions/permission_service.dart';
import 'package:movera_rider/core/realtime/api_ride_realtime.dart';
import 'package:movera_rider/core/realtime/mock_ride_realtime.dart';
import 'package:movera_rider/core/realtime/realtime_connection.dart';
import 'package:movera_rider/core/realtime/ride_realtime.dart';
import 'package:movera_rider/core/sockets/socket_client.dart';
import 'package:movera_rider/features/auth/application/auth_controller.dart';
import 'package:movera_rider/features/booking/application/booking_coordinator.dart';
import 'package:movera_rider/features/auth/presentation/sign_in.dart';
import 'package:movera_rider/features/destination/application/destination_controller.dart';
import 'package:movera_rider/features/destination/application/destination_session.dart';
import 'package:movera_rider/features/destination_search/application/destination_search_controller.dart';
import 'package:movera_rider/features/onboarding/application/onboarding_controller.dart';
import 'package:movera_rider/features/payments/data/default_payment_store.dart';
import 'package:movera_rider/features/payments/data/local_payment_repository.dart';
import 'package:movera_rider/features/pickup/application/pickup_session.dart';
import 'package:movera_rider/features/profile/application/account_security_controller.dart';
import 'package:movera_rider/features/profile/application/profile_controller.dart';
import 'package:movera_rider/features/profile/data/account_security_repository.dart';
import 'package:movera_rider/features/reservations/application/reservation_controller.dart';
import 'package:movera_rider/features/reservations/data/mock_reservation_dispatch.dart';
import 'package:movera_rider/features/ride_booking/application/ride_session.dart';
import 'package:movera_rider/features/ride_booking/data/ride_snapshot_store.dart';
import 'package:movera_rider/features/ride_booking/data/api_quote_repository.dart';
import 'package:movera_rider/features/ride_booking/data/mock_quote_repository.dart';
import 'package:movera_rider/features/ride_complete/application/ride_complete_controller.dart';
import 'package:movera_rider/features/ride_selection/data/ride_selection_repository.dart';
import 'package:movera_rider/features/safety/application/emergency_call_service.dart';
import 'package:movera_rider/features/saved_places/application/saved_places_controller.dart';
import 'package:movera_rider/features/support/application/support_controller.dart';
import 'package:movera_rider/features/wallet/application/wallet_controller.dart';
import 'package:movera_rider/features/wallet/domain/wallet_ledger.dart';

class AppScope {
  AppScope._(this.environment)
      : maps = GoogleMapProvider(),
        mapLifecycle = MapLifecycleController(),
        markers = MarkerStore(),
        motion = MotionEngine(),
        ride = RideSession(),
        tokens = SecureTokenStore(),
        realtime = RealtimeConnection(),
        payments = LocalPaymentRepository(),
        defaultPayment = const PrefsDefaultPaymentStore(),
        wallet = WalletLedger(),
        lifecycle = AppLifecycleObserver(),
        permissions = PermissionService(),
        search = PlaceSearchService(),
        location = LocationRepository(),
        crashes = const CrashReporter(),
        pickup = PickupSession(),
        destination = DestinationSession(),
        booking = BookingCoordinator(),
        reservations = ReservationController(
          environment: environment,
          // Simulated scheduled-ride dispatch: mock-transport builds only.
          mockDispatch: environment.allowsMockTransport
              ? MockReservationDispatch()
              : null,
        ),
        profile = ProfileController() {
    api = ApiClient(
      env: environment,
      tokens: tokens,
      onSessionExpired: () async {
        await RideSnapshotStore.clear();
        await LocationRepository.clearLastGoodFix();
        moveraNavigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute<void>(builder: (_) => const SignIn()),
          (_) => false,
        );
      },
    );
    paymentGateway = environment.allowsMockTransport
        ? MockPaymentGateway()
        : ApiPaymentGateway(api: api);
    push = environment.allowsMockTransport
        ? NoopPushService()
        : FirebasePushService(api: api, environment: environment);

    if (environment.isReleaseLike) {
      final sink = HttpObservabilitySink(baseUrl: environment.apiBaseUrl);
      observabilitySink = sink;
      Observability.configure(
        loggerSink: sink,
        analyticsSink: sink,
        crashSink: sink,
      );
    }

    accountSecurity = AccountSecurityController(
      repository: AccountSecurityRepository(api: api),
    );

    geocoding = AppGeocoding(api: api);
    routing = RoutingService(api: api);
    quotes = ApiQuoteRepository(api: api);
    rideRealtime = environment.allowsMockTransport
        ? MockRideRealtime(api: api, connection: realtime)
        : ApiRideRealtime(api: api, connection: realtime);
    sockets = SocketClient(realtime);
    camera = MapCameraController(maps);
    destinationSearch = DestinationSearchController(search);
    map = MapFacade(
      provider: maps,
      camera: camera,
      markers: markers,
      lifecycle: mapLifecycle,
      routing: routing,
    );

    PinComposition.validate(
      environment: environment,
      usesMockPinIssuance: api.usesMockTransport,
    );
    TransportComposition.validate(
      environment: environment,
      api: api,
      realtime: rideRealtime,
      paymentGateway: paymentGateway,
      push: push,
      emergencyDialer: emergencyDialer,
      logger: Observability.logger,
      analytics: Observability.analytics,
      crashes: Observability.crashes,
    );
    AuthComposition.validate(environment);
  }

  static final instance = AppScope._(AppEnv.current);

  /// Uses the exact production composition root without replacing individual
  /// dependencies by hand. Phase 72 CI exercises this factory directly.
  static AppScope composeForEnvironment(AppEnv environment) =>
      AppScope._(environment);

  final AppEnv environment;
  final GoogleMapProvider maps;
  final MapLifecycleController mapLifecycle;
  final MarkerStore markers;
  late final MapCameraController camera;
  late final MapFacade map;
  final MotionEngine motion;
  final RideSession ride;
  late final ApiClient api;
  final TokenStore tokens;
  final RealtimeConnection realtime;
  late final SocketClient sockets;
  late final QuoteRepository quotes;
  final LocalPaymentRepository payments;
  final DefaultPaymentStore defaultPayment;
  late final PaymentGateway paymentGateway;
  final WalletLedger wallet;
  final AppLifecycleObserver lifecycle;
  final PermissionService permissions;
  final PlaceSearchService search;
  final LocationRepository location;
  late final AppGeocoding geocoding;
  late final PushService push;
  final CrashReporter crashes;
  final PickupSession pickup;
  final DestinationSession destination;
  final BookingCoordinator booking;
  late final DestinationSearchController destinationSearch;
  late final RoutingService routing;
  late final RideRealtime rideRealtime;
  final ReservationController reservations;
  final ProfileController profile;
  late final AccountSecurityController accountSecurity;

  // Phase 138: these default-construct their own dependencies internally
  // (several read AppScope.instance themselves), so each is declared as a
  // lazy `late final` field initializer rather than built eagerly in the
  // constructor above - AppScope.instance is not yet bound while this
  // constructor is still running, so a screen reading one of these before
  // that assignment completes would otherwise hit it uninitialized. Nothing
  // does that in practice (screens read AppScope.instance.x from their own
  // initState, always after app startup), so this only matters for
  // correctness under construction order, not normal use.
  late final AuthController auth = AuthController();
  late final RideCompleteController rideComplete = RideCompleteController();
  late final WalletController walletController = WalletController();
  late final SavedPlacesController savedPlaces = SavedPlacesController();
  late final SupportController support = SupportController();
  late final OnboardingController onboarding = OnboardingController();
  late final DestinationController destinationMemory = DestinationController();
  late final RideSelectionRepository rideCatalog = RideSelectionRepository();
  HttpObservabilitySink? observabilitySink;
  FeatureFlags flags = FeatureFlags.current;

  EmergencyDialer get emergencyDialer => EmergencyCallService.shared.dialer;

  void disposeForTest() {
    rideRealtime.dispose();
    realtime.dispose();
    observabilitySink?.dispose();
    if (environment.isReleaseLike) Observability.reset();
  }
}
