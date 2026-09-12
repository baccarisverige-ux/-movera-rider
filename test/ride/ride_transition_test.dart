import 'package:flutter_test/flutter_test.dart';
import 'package:movera_rider/features/ride_booking/domain/ride_status.dart';
import 'package:movera_rider/features/ride_booking/domain/ride_transition.dart';

void main() {
  test('happy path booking transitions', () {
    var status = RideStatus.idle;
    status = transitionRide(status, RideStatus.pickupSelected);
    status = transitionRide(status, RideStatus.destinationSelected);
    status = transitionRide(status, RideStatus.quoteLoading);
    status = transitionRide(status, RideStatus.rideOptionsReady);
    expect(status, RideStatus.rideOptionsReady);
  });

  test('rejects illegal jumps', () {
    expect(
      () => transitionRide(RideStatus.idle, RideStatus.findingDriver),
      throwsA(isA<InvalidRideTransition>()),
    );
  });

  test('terminal states cannot move', () {
    expect(
      () => transitionRide(RideStatus.closed, RideStatus.idle),
      throwsA(isA<InvalidRideTransition>()),
    );
  });
}
