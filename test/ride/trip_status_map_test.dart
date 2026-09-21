import 'package:flutter_test/flutter_test.dart';
import 'package:movera_rider/core/contracts/trip_status.dart';
import 'package:movera_rider/features/reservations/domain/reservation_status.dart';
import 'package:movera_rider/features/ride_booking/domain/ride_status.dart';

void main() {
  test('RideStatus.driverArriving maps to driver_to_pickup', () {
    expect(
      RideStatus.driverArriving.tripStatus,
      TripStatus.driverToPickup,
    );
    expect(TripStatus.driverToPickup.wireName, 'driver_to_pickup');
  });

  test('ReservationStatus.driverEnRoute is the same live slice', () {
    expect(
      ReservationStatus.driverEnRoute.tripStatus,
      TripStatus.driverToPickup,
    );
    expect(
      ReservationStatus.driverEnRoute.asRideStatus,
      RideStatus.driverArriving,
    );
  });

  test('payment and rating stay off the trip machine', () {
    expect(RideStatus.paymentProcessing.tripStatus, TripStatus.completed);
    expect(RideStatus.ratingPending.tripStatus, TripStatus.completed);
    expect(RideStatus.paymentFailed.tripStatus, TripStatus.failed);
  });
}
