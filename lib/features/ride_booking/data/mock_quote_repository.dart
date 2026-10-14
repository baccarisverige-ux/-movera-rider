import 'package:movera_rider/core/maps/geo_point.dart';
import 'package:movera_rider/features/ride_booking/domain/entities/quote.dart';
import 'package:movera_rider/features/ride_booking/domain/route_stop.dart';

abstract class QuoteRepository {
  /// ARCH-8 / contract C-2: the server prices the trip from [pickupPoint],
  /// [destinationPoint] and [stops], routing it itself. [distanceMeters] and
  /// [durationSeconds] are only a hint; the address strings are labels.
  Future<RideQuote> quote({
    required String rideType,
    required int distanceMeters,
    int durationSeconds = 600,
    String? pickup,
    String? destination,
    GeoPoint? pickupPoint,
    GeoPoint? destinationPoint,
    List<RouteStop> stops = const <RouteStop>[],
  });
}
