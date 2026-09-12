import 'package:movera_rider/app/lifecycle/app_lifecycle.dart';
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
import 'package:movera_rider/core/payments/mock_payment_gateway.dart';
import 'package:movera_rider/core/permissions/permission_service.dart';
import 'package:movera_rider/core/realtime/mock_ride_realtime.dart';
import 'package:movera_rider/core/realtime/realtime_connection.dart';
import 'package:movera_rider/core/realtime/ride_realtime.dart';
import 'package:movera_rider/core/sockets/socket_client.dart';
import 'package:movera_rider/features/booking/application/booking_coordinator.dart';
import 'package:movera_rider/features/destination/application/destination_session.dart';
import 'package:movera_rider/features/destination_search/application/destination_search_controller.dart';
import 'package:movera_rider/features/payments/data/local_payment_repository.dart';
import 'package:movera_rider/features/pickup/application/pickup_session.dart';
import 'package:movera_rider/features/ride_booking/application/ride_session.dart';
import 'package:movera_rider/features/ride_booking/data/api_quote_repository.dart';
import 'package:movera_rider/features/ride_booking/data/catalog_quote_repository.dart';
import 'package:movera_rider/features/ride_booking/data/mock_quote_repository.dart';
import 'package:movera_rider/features/wallet/domain/wallet_ledger.dart';

class AppScope {
  AppScope._()
      : maps = GoogleMapProvider(),
        mapLifecycle = MapLifecycleController(),
        markers = MarkerStore(),
        motion = MotionEngine(),
        ride = RideSession(),
        tokens = SecureTokenStore(),
        realtime = RealtimeConnection(),
        payments = LocalPaymentRepository(),
        paymentGateway = MockPaymentGateway(),
        wallet = WalletLedger(),
        lifecycle = AppLifecycleObserver(),
        permissions = PermissionService(),
        search = PlaceSearchService(),
        location = LocationRepository(),
        geocoding = AppGeocoding(),
        push = NoopPushService(),
        crashes = const CrashReporter(),
        pickup = PickupSession(),
        destination = DestinationSession(),
        booking = BookingCoordinator(),
        routing = RoutingService(),
        rideRealtime = MockRideRealtime() {
    api = ApiClient(tokens: tokens);
    quotes = ApiQuoteRepository(api: api, fallback: CatalogQuoteRepository());
    sockets = SocketClient(realtime);
    camera = MapCameraController(maps);
    destinationSearch = DestinationSearchController(search);
    map = MapFacade(
      provider: maps,
      camera: camera,
      markers: markers,
      lifecycle: mapLifecycle,
    );
  }

  static final instance = AppScope._();

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
  final MockPaymentGateway paymentGateway;
  final WalletLedger wallet;
  final AppLifecycleObserver lifecycle;
  final PermissionService permissions;
  final PlaceSearchService search;
  final LocationRepository location;
  final AppGeocoding geocoding;
  final PushService push;
  final CrashReporter crashes;
  final PickupSession pickup;
  final DestinationSession destination;
  final BookingCoordinator booking;
  late final DestinationSearchController destinationSearch;
  final RoutingService routing;
  final RideRealtime rideRealtime;
  FeatureFlags flags = FeatureFlags.current;
}
