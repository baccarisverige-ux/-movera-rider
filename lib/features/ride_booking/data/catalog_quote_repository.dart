import 'package:movera_rider/features/ride_booking/data/mock_quote_repository.dart';
import 'package:movera_rider/features/ride_booking/domain/entities/quote.dart';

/// Dev fallback only. Live Select Ride must go through [ApiQuoteRepository].
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
    int durationSeconds = 600,
    String? pickup,
    String? destination,
  }) async {
    final kr = pricesKr[rideType] ?? 259;
    return RideQuote(
      id: 'q_fallback_$rideType',
      rideType: rideType,
      totalMinor: kr * 100,
      currency: 'SEK',
      expiresAt: DateTime.now().add(const Duration(minutes: 2)),
      baseMinor: kr * 100,
      signedPayload: 'fallback',
    );
  }
}
