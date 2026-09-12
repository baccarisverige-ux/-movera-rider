import 'package:movera_rider/features/ride_booking/domain/entities/quote.dart';

abstract class QuoteRepository {
  Future<RideQuote> quote({required String rideType, required int distanceMeters});
}

class MockQuoteRepository implements QuoteRepository {
  @override
  Future<RideQuote> quote({
    required String rideType,
    required int distanceMeters,
  }) async {
    final base = 8900;
    final distance = (distanceMeters / 1000 * 1200).round();
    final total = base + distance;
    return RideQuote(
      id: 'q_$rideType',
      rideType: rideType,
      totalMinor: total,
      currency: 'SEK',
      expiresAt: DateTime.now().add(const Duration(minutes: 2)),
      baseMinor: base,
      distanceMinor: distance,
      bookingFeeMinor: 500,
      signedPayload: 'mock',
    );
  }
}
