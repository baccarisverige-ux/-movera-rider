import 'package:movera_rider/app/di.dart';
import 'package:movera_rider/core/feature_flags/feature_flags.dart';
import 'package:movera_rider/features/fare/application/fare_controller.dart';
import 'package:movera_rider/features/ride_booking/data/mock_quote_repository.dart';
import 'package:movera_rider/features/ride_selection/data/ride_selection_repository.dart';
import 'package:movera_rider/features/ride_selection/domain/ride_selection.dart';

class RideSelectionController {
  RideSelectionController({
    RideSelectionRepository? store,
    QuoteRepository? quotes,
    FareController? fare,
    FeatureFlags? flags,
  })  : _store = store ?? RideSelectionRepository(),
        _quotes = quotes ?? AppScope.instance.quotes,
        _fare = fare ?? FareController(),
        _flags = flags ?? AppScope.instance.flags;

  final RideSelectionRepository _store;
  final QuoteRepository _quotes;
  final FareController _fare;
  final FeatureFlags _flags;

  final Map<String, double> offeredPrices = {};
  final Map<String, String> quoteIds = {};
  int _quoteGeneration = 0;
  bool usedFallback = false;
  String selectedRideId = 'movera';
  int selectedPayment = 1;

  List<RideCatalogItem> rides() => _store.rides();

  List<RidePaymentItem> payments() {
    return _store.payments().where((item) {
      if (item.brand == 'cash') return _flags.enableCash;
      if (item.brand == 'apple') return _flags.enableApplePay;
      if (item.brand == 'wallet') return _flags.enableWallet;
      if (item.brand == 'google') return _flags.enableGooglePay;
      if (item.brand == 'swish') return _flags.enableSwish;
      return true;
    }).toList();
  }

  int beginQuotes() => ++_quoteGeneration;

  Future<void> loadQuotes({
    required int generation,
    required String pickup,
    required String destination,
    int distanceMeters = 3000,
  }) async {
    usedFallback = false;
    for (final ride in rides()) {
      if (generation != _quoteGeneration) return;
      final quote = await _quotes.quote(
        rideType: ride.id,
        distanceMeters: distanceMeters,
        pickup: pickup,
        destination: destination,
      );
      if (generation != _quoteGeneration) return;
      offeredPrices[ride.id] = quote.totalMinor / 100;
      quoteIds[ride.id] = quote.id;
      if (quote.signedPayload == 'fallback') usedFallback = true;
    }
  }

  double priceFor(String id, double catalog) => offeredPrices[id] ?? catalog;

  void selectRide(String id, double catalog) {
    selectedRideId = id;
    offeredPrices.putIfAbsent(id, () => catalog);
  }

  double changeOffer({
    required String id,
    required double catalog,
    required int delta,
  }) {
    final current = priceFor(id, catalog);
    final next = _fare.nudge(current: current, catalog: catalog, delta: delta);
    offeredPrices[id] = next;
    return next;
  }
}
