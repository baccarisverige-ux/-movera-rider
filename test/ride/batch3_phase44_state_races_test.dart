import 'package:flutter_test/flutter_test.dart';
import 'package:movera_rider/features/ride_booking/application/ride_session.dart';
import 'package:movera_rider/features/ride_booking/domain/ride_status.dart';

void main() {
  test('authoritative backend may skip client-only intermediate states', () {
    final ride = RideSession()..rideId = 'r1';
    expect(
      ride.backendReconcile(
        RideStatus.driverArriving,
        id: 'r1',
        version: 1,
        updatedAt: DateTime.utc(2026, 9, 24, 11),
      ),
      isTrue,
    );
    expect(
      ride.backendReconcile(
        RideStatus.paymentFinalized,
        id: 'r1',
        version: 2,
        updatedAt: DateTime.utc(2026, 9, 24, 11, 1),
      ),
      isTrue,
    );
    expect(ride.status, RideStatus.paymentFinalized);
  });

  test('stale authoritative projection cannot move the ride backwards', () {
    final ride = RideSession()..rideId = 'r1';
    expect(
      ride.backendReconcile(
        RideStatus.findingDriver,
        id: 'r1',
        version: 5,
        updatedAt: DateTime.utc(2026, 9, 24, 12, 5),
      ),
      isTrue,
    );
    expect(
      ride.backendReconcile(
        RideStatus.driverAssigned,
        id: 'r1',
        version: 4,
        updatedAt: DateTime.utc(2026, 9, 24, 12, 4),
      ),
      isFalse,
    );
    expect(ride.status, RideStatus.findingDriver);
    expect(ride.authoritativeVersion, 5);
  });

  test('projection for another ride cannot replace an active session', () {
    final ride = RideSession()..rideId = 'r1';
    expect(
      ride.backendReconcile(
        RideStatus.findingDriver,
        id: 'r1',
        version: 3,
        updatedAt: DateTime.utc(2026, 9, 24, 12),
      ),
      isTrue,
    );
    expect(
      ride.backendReconcile(
        RideStatus.driverAssigned,
        id: 'r2',
        version: 99,
        updatedAt: DateTime.utc(2026, 9, 24, 12, 1),
      ),
      isFalse,
    );
    expect(ride.rideId, 'r1');
    expect(ride.status, RideStatus.findingDriver);
    expect(ride.authoritativeVersion, 3);
  });
}
