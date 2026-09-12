import 'package:movera_rider/features/ride_booking/domain/entities/quote.dart';

abstract class QuoteRepository {
  Future<RideQuote> quote({
    required String rideType,
    required int distanceMeters,
    int durationSeconds = 600,
    String? pickup,
    String? destination,
  });
}
