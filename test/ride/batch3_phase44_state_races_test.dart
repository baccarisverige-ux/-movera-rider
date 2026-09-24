import 'package:flutter_test/flutter_test.dart';
import 'package:movera_rider/features/ride_booking/application/ride_session.dart';
import 'package:movera_rider/features/ride_booking/domain/ride_status.dart';

void main() {
  test('authoritative reconciliation rejects illegal state jumps', () {
    final ride = RideSession()..rideId = 'r1';
    expect(
      ride.backendReconcile(
        RideStatus.findingDriver,
        id: 'r1',
        version: 1,
        updatedAt: DateTime.utc(2026, 9, 24, 12),
      ),
      isTrue,
    );

    expect(
      ride.backendReconcile(
        RideStatus.tripCompleted,
        id: 'r1',
        version: 2,
        updatedAt: DateTime.utc(2026, 9, 24, 12, 1),
      ),
      isFalse,
    );
    expect(ride.status, RideStatus.findingDriver);
    expect(ride.authoritativeVersion, 1);
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
}
