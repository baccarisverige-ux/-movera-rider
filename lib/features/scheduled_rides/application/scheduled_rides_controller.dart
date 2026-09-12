import 'package:movera_rider/app/di.dart';
import 'package:movera_rider/features/ride_booking/domain/ride_status.dart';

class ScheduledRideSession {
  String pickup = 'Current location';
  String dropoff = '';
  DateTime? scheduledAt;
  String paymentMethod = 'Wallet';

  Future<String> confirm() {
    return AppScope.instance.booking.requestBooking(
      rideType: 'movera',
      paymentMethod: paymentMethod,
    );
  }

  void markScheduled() {
    AppScope.instance.ride.restoreFromBackend(RideStatus.bookingRequested);
  }
}
