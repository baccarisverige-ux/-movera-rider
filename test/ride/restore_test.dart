import 'package:flutter_test/flutter_test.dart';
import 'package:movera_rider/features/ride_booking/application/ride_restore_coordinator.dart';
import 'package:movera_rider/features/ride_booking/data/ride_snapshot_store.dart';
import 'package:movera_rider/features/ride_booking/domain/ride_status.dart';

RideSnapshot snap(RideStatus status, {DateTime? savedAt}) {
  return RideSnapshot(
    status: status,
    savedAt: savedAt ?? DateTime.now(),
    pickupAddress: 'A',
    destinationAddress: 'B',
    pickupLat: 59.3,
    pickupLng: 18.0,
    destinationLat: 59.4,
    destinationLng: 18.1,
    rideType: 'Movera',
    price: 259,
    paymentMethod: 'Apple Pay',
    rideId: 'r1',
  );
}

void main() {
  test('finding driver', () {
    final c = RideRestoreCoordinator(reader: () async => snap(RideStatus.findingDriver));
    expect(c.surfaceFor(snap(RideStatus.findingDriver)), RestoredSurface.finding);
  });

  test('driver assigned', () {
    final c = RideRestoreCoordinator(reader: () async => null);
    expect(
      c.surfaceFor(snap(RideStatus.driverAssigned)),
      RestoredSurface.waiting,
    );
  });

  test('trip in progress', () {
    final c = RideRestoreCoordinator(reader: () async => null);
    expect(
      c.surfaceFor(snap(RideStatus.tripInProgress)),
      RestoredSurface.waiting,
    );
  });

  test('no active ride', () {
    final c = RideRestoreCoordinator(reader: () async => null);
    expect(c.surfaceFor(null), RestoredSurface.home);
  });

  test('cancelled ride', () {
    final c = RideRestoreCoordinator(reader: () async => null);
    expect(
      c.surfaceFor(snap(RideStatus.cancelledByRider)),
      RestoredSurface.home,
    );
  });

  test('outdated snapshot', () {
    final c = RideRestoreCoordinator(reader: () async => null);
    expect(
      c.surfaceFor(
        snap(
          RideStatus.findingDriver,
          savedAt: DateTime.now().subtract(const Duration(hours: 3)),
        ),
      ),
      RestoredSurface.home,
    );
  });

  test('resume is idempotent when already showing', () async {
    final snapshot = snap(RideStatus.findingDriver);
    final c = RideRestoreCoordinator(reader: () async => snapshot);
    c.showing = RestoredSurface.finding;
    expect(await c.resumeIfNeeded(), isNull);
  });
}
