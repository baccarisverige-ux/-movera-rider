import 'package:movera_rider/app/lifecycle/app_lifecycle.dart';
import 'package:movera_rider/app/config/env.dart';
import 'package:movera_rider/app/config/transport_composition.dart';
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
import 'package:movera_rider/core/notifications/push_service.dart';
import 'package:movera_rider/core/observability/http_observability.dart';
import 'package:movera_rider/core/observability/observability.dart';
import 'package:movera_rider/core/payments/mock_payment_gateway.dart';
import 'package:movera_rider/core/payments/payment_gateway.dart';
import 'package:movera_rider/core/payments/unavailable_payment_gateway.dart';
import 'package:movera_rider/core/permissions/permission_service.dart';
import 'package:movera_rider/core/realtime/api_ride_realtime.dart';
import 'package:movera_rider/core/realtime/mock_ride_realtime.dart';
import 'package:movera_rider/core/realtime/realtime_connection.dart';
import 'package:movera_rider/core/realtime/ride_realtime.dart';
import 'package:movera_rider/core/sockets/socket_client.dart';
import 'package:movera_rider/features/booking/application/booking_coordinator.dart';
import 'package:movera_rider/features/destination/application/destination_session.dart';
import 'package:movera_rider/features/destination_search/application/destination_search_controller.dart';
import 'package:movera_rider/features/payments/data/default_payment_store.dart';
import 'package:movera_rider/features/payments/data/local_payment_repository.dart';
import 'package:movera_rider/features/pickup/application/pickup_session.dart';
import 'package:movera_rider/features/profile/application/account_security_controller.dart';
import 'package:movera_rider/features/profile/application/profile_controller.dart';
import 'package:movera_rider/features/profile/data/account_security_repository.dart';
import 'package:movera_rider/features/reservations/application/reservation_controller.dart';
import 'package:movera_rider/features/ride_booking/application/ride_session.dart';
import 'package:movera_rider/features/ride_booking/data/api_quote_repository.dart';
import 'package:movera_rider/features/ride_booking/data/mock_quote_repository.dart';
import 'package:movera_rider/features/safety/application/emergency_call_service.dart';
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
        paymentGateway = environment.allowsMockTransport
            ? MockPaymentGateway()
            : const UnavailablePaymentGateway(),
        wallet = WalletLedger(),
        lifecycle = AppLifecycleObserver(),
        permissions = PermissionService(),
        search = PlaceSearchService(),
        location = LocationRepository(),
        push = environment.allowsMockTransport
            ? NoopPushService()
            : const UnavailablePushService(),
        crashes = const CrashReporter(),
        pickup = PickupSession(),
        destination = DestinationSession(),
        booking = BookingCoordinator(),
        reservations = ReservationController(environment: environment),
        profile = ProfileController() {
    api = ApiClient(env: environment, tokens: tokens);

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
        : ApiRideRealtime(api: api);
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
      usesMockDriverAssignment: reservations.usesMockDriverAssignment,
    );
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
  final PaymentGateway paymentGateway;
  final WalletLedger wallet;
  final AppLifecycleObserver lifecycle;
  final PermissionService permissions;
  final PlaceSearchService search;
  final LocationRepository location;
  late final AppGeocoding geocoding;
  final PushService push;
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
