import 'package:movera_rider/app/lifecycle/app_lifecycle.dart';
import 'package:movera_rider/core/api/api_client.dart';
import 'package:movera_rider/core/auth/token_store.dart';
import 'package:movera_rider/core/feature_flags/feature_flags.dart';
import 'package:movera_rider/core/maps/google_map_provider.dart';
import 'package:movera_rider/core/maps/map_lifecycle.dart';
import 'package:movera_rider/core/maps/marker_store.dart';
import 'package:movera_rider/core/motion/motion_engine.dart';
import 'package:movera_rider/core/realtime/realtime_connection.dart';
import 'package:movera_rider/features/payments/data/local_payment_repository.dart';
import 'package:movera_rider/features/ride_booking/application/ride_session.dart';
import 'package:movera_rider/features/ride_booking/data/mock_quote_repository.dart';
import 'package:movera_rider/features/wallet/domain/wallet_ledger.dart';

/// Composition root. Screens take services from here, not from SDKs.
class AppScope {
  AppScope._();
  static final instance = AppScope._();

  final maps = GoogleMapProvider();
  final mapLifecycle = MapLifecycleController();
  final markers = MarkerStore();
  final motion = MotionEngine();
  final ride = RideSession();
  final api = ApiClient();
  final tokens = MemoryTokenStore();
  final realtime = RealtimeConnection();
  final quotes = MockQuoteRepository();
  final payments = LocalPaymentRepository();
  final wallet = WalletLedger();
  final lifecycle = AppLifecycleObserver();
  FeatureFlags flags = FeatureFlags.current;
}
