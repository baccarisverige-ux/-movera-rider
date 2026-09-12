import 'package:movera_rider/app/di.dart';
import 'package:movera_rider/core/analytics/analytics.dart';
import 'package:movera_rider/core/api/idempotency.dart';
import 'package:movera_rider/features/ride_booking/domain/ride_status.dart';

class BookingCoordinator {
  Future<String> requestBooking({
    required String rideType,
    required String paymentMethod,
  }) async {
    final id = newIdempotencyKey('booking');
    AppScope.instance.ride.restoreFromBackend(
      RideStatus.bookingRequested,
      id: id,
    );
    Analytics.bookingSubmitted(rideId: id);
    AppScope.instance.ride.restoreFromBackend(RideStatus.findingDriver, id: id);
    return id;
  }
}
