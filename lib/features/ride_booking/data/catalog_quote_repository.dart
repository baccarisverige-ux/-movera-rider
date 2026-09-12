import 'package:movera_rider/features/ride_booking/data/mock_quote_repository.dart';
import 'package:movera_rider/features/ride_booking/domain/entities/quote.dart';

/// Returns the same catalog fares the Select Ride UI already shows.
class CatalogQuoteRepository implements QuoteRepository {
  static const pricesKr = <String, int>{
    'movera': 259,
    'comfort': 339,
    'premium': 369,
    'priority': 289,
    'xl': 399,
    'electric': 259,
    'pet': 279,
  };

  @override
  Future<RideQuote> quote({
    required String rideType,
    required int distanceMeters,
  }) async {
    final kr = pricesKr[rideType] ?? 259;
    return RideQuote(
      id: 'q_$rideType',
      rideType: rideType,
      totalMinor: kr * 100,
      currency: 'SEK',
      expiresAt: DateTime.now().add(const Duration(minutes: 2)),
      baseMinor: kr * 100,
      signedPayload: 'catalog',
    );
  }
}
