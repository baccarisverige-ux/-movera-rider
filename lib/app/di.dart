import 'package:movera_rider/app/lifecycle/app_lifecycle.dart';
import 'package:movera_rider/core/api/api_client.dart';
import 'package:movera_rider/core/auth/token_store.dart';
import 'package:movera_rider/core/feature_flags/feature_flags.dart';
import 'package:movera_rider/core/location/place_search.dart';
import 'package:movera_rider/core/maps/google_map_provider.dart';
import 'package:movera_rider/core/maps/map_camera_controller.dart';
import 'package:movera_rider/core/maps/map_facade.dart';
import 'package:movera_rider/core/maps/map_lifecycle.dart';
import 'package:movera_rider/core/maps/marker_store.dart';
import 'package:movera_rider/core/motion/motion_engine.dart';
import 'package:movera_rider/core/permissions/permission_service.dart';
import 'package:movera_rider/core/realtime/realtime_connection.dart';
import 'package:movera_rider/core/sockets/socket_client.dart';
import 'package:movera_rider/features/payments/data/local_payment_repository.dart';
import 'package:movera_rider/features/ride_booking/application/ride_session.dart';
import 'package:movera_rider/features/ride_booking/data/mock_quote_repository.dart';
import 'package:movera_rider/features/wallet/domain/wallet_ledger.dart';

class AppScope {
  AppScope._()
      : maps = GoogleMapProvider(),
        mapLifecycle = MapLifecycleController(),
        markers = MarkerStore(),
        motion = MotionEngine(),
        ride = RideSession(),
        api = ApiClient(),
        tokens = MemoryTokenStore(),
        realtime = RealtimeConnection(),
        quotes = MockQuoteRepository(),
        payments = LocalPaymentRepository(),
        wallet = WalletLedger(),
        lifecycle = AppLifecycleObserver(),
        permissions = PermissionService(),
        search = PlaceSearchService() {
    sockets = SocketClient(realtime);
    camera = MapCameraController(maps);
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
  final ApiClient api;
  final MemoryTokenStore tokens;
  final RealtimeConnection realtime;
  late final SocketClient sockets;
  final MockQuoteRepository quotes;
  final LocalPaymentRepository payments;
  final WalletLedger wallet;
  final AppLifecycleObserver lifecycle;
  final PermissionService permissions;
  final PlaceSearchService search;
  FeatureFlags flags = FeatureFlags.current;
}
