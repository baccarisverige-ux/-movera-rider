import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movera_rider/features/active_ride/presentation/waiting_for_driver.dart';
import 'package:movera_rider/features/finding_driver/presentation/finding_drivers.dart';
import 'package:movera_rider/features/home/presentation/home.dart';
import 'package:movera_rider/features/ride_booking/application/ride_restore_coordinator.dart';
import 'package:movera_rider/features/ride_booking/data/ride_snapshot_store.dart';
import 'package:movera_rider/features/ride_booking/domain/ride_status.dart';
import 'package:movera_rider/features/ride_complete/presentation/ride_completed.dart';

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
  TestWidgetsFlutterBinding.ensureInitialized();
  test('cold start finding driver', () {
    final c = RideRestoreCoordinator(reader: () async => snap(RideStatus.findingDriver));
    final page = c.pageFor(snap(RideStatus.findingDriver));
    expect(page, isA<FindingDrivers>());
    expect(c.showing, RestoredSurface.finding);
  });

  test('cold start assigned', () {
    final c = RideRestoreCoordinator(reader: () async => null);
    expect(c.pageFor(snap(RideStatus.driverAssigned)), isA<WaitingForDriver>());
  });

  test('trip active uses waiting surface', () {
    final c = RideRestoreCoordinator(reader: () async => null);
    expect(c.pageFor(snap(RideStatus.tripInProgress)), isA<WaitingForDriver>());
  });

  test('completed', () {
    final c = RideRestoreCoordinator(reader: () async => null);
    expect(c.pageFor(snap(RideStatus.tripCompleted)), isA<RideCompleted>());
  });

  test('cancelled and stale go home', () {
    final c = RideRestoreCoordinator(reader: () async => null);
    expect(c.pageFor(snap(RideStatus.cancelledByRider)), isA<Home>());
    expect(
      c.pageFor(
        snap(
          RideStatus.findingDriver,
          savedAt: DateTime.now().subtract(const Duration(hours: 3)),
        ),
      ),
      isA<Home>(),
    );
  });

  test('resume is idempotent when already showing', () async {
    final snapshot = snap(RideStatus.findingDriver);
    final c = RideRestoreCoordinator(reader: () async => snapshot);
    c.showing = RestoredSurface.finding;
    expect(await c.resumeIfNeeded(), isNull);
  });

  test('repeated resume does not loop', () async {
    final snapshot = snap(RideStatus.findingDriver);
    final c = RideRestoreCoordinator(reader: () async => snapshot);
    c.showing = RestoredSurface.finding;
    expect(await c.resumeIfNeeded(), isNull);
    expect(await c.resumeIfNeeded(), isNull);
  });
}
