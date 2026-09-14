import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movera_rider/app/di.dart';
import 'package:movera_rider/core/realtime/mock_ride_realtime.dart';
import 'package:movera_rider/features/active_ride/presentation/waiting_for_driver.dart';
import 'package:movera_rider/features/finding_driver/application/cancel_first.dart';
import 'package:movera_rider/features/finding_driver/application/finding_driver_controller.dart';
import 'package:movera_rider/features/finding_driver/data/finding_driver_repository.dart';
import 'package:movera_rider/features/finding_driver/presentation/finding_drivers.dart';
import 'package:movera_rider/features/home/presentation/home.dart';
import 'package:movera_rider/features/ride_booking/application/ride_restore_coordinator.dart';
import 'package:movera_rider/features/ride_booking/data/ride_snapshot_store.dart';
import 'package:movera_rider/features/ride_booking/domain/ride_status.dart';
import 'package:shared_preferences/shared_preferences.dart';

RideSnapshot findingSnap({String rideId = 'r-late'}) => RideSnapshot(
      status: RideStatus.findingDriver,
      savedAt: DateTime.now(),
      pickupAddress: 'A',
      destinationAddress: 'B',
      pickupLat: 59.3,
      pickupLng: 18.0,
      destinationLat: 59.4,
      destinationLng: 18.1,
      rideType: 'Movera',
      price: 259,
      paymentMethod: 'Apple Pay',
      rideId: rideId,
    );

MockRideRealtime get _rt =>
    AppScope.instance.rideRealtime as MockRideRealtime;

void _resetScope() {
  SharedPreferences.setMockInitialValues({});
  RideSnapshotStore.epoch = 0;
  FindingDriverController.active = null;
  final ride = AppScope.instance.ride;
  ride.rideId = null;
  ride.suppressRestore = false;
  ride.restoreFromBackend(RideStatus.idle);
  final rt = _rt;
  rt.cancelled = false;
  rt.disposed = false;
  rt.held = false;
  rt.lastDriver = null;
  rt.lastStatus = RideStatus.idle;
  RideRestoreCoordinator.instance.showing = RestoredSurface.home;
  RideRestoreCoordinator.instance.onReplaceRoot = null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(_resetScope);
  tearDown(_resetScope);

  test(
    'finding: cancel-first then late assign stays Home (not Finding/Waiting)',
    () async {
      final rt = _rt;
      rt.holdAssignment();
      final ride = AppScope.instance.ride..rideId = 'r-find';
      var matches = 0;
      final controller = FindingDriverController(
        realtime: rt,
        ride: ride,
        store: FindingDriverRepository(),
      );
      controller.start(
        snapshot: findingSnap(rideId: 'r-find'),
        onTick: (_) {},
        onMatched: () => matches += 1,
      );

      expect(ride.status, RideStatus.findingDriver);
      expect(
        RideRestoreCoordinator(
          reader: RideSnapshotStore.read,
        ).surfaceFor(await RideSnapshotStore.read()),
        anyOf(RestoredSurface.finding, RestoredSurface.home),
      );

      await commitCancelFirst();

      expect(ride.status, RideStatus.cancelledByRider);
      expect(ride.suppressRestore, isTrue);
      expect(rt.cancelled, isTrue);
      expect(await RideSnapshotStore.read(), isNull);

      rt.assignNow();
      rt.emit(RideStatus.driverAssigned, sequence: 50);
      rt.emit(RideStatus.findingDriver, sequence: 51);
      rt.emit(RideStatus.driverWaiting, sequence: 52);
      await Future<void>.delayed(const Duration(milliseconds: 40));

      expect(matches, 0);
      expect(controller.matchCount, 0);
      expect(ride.status, RideStatus.cancelledByRider);
      expect(await RideSnapshotStore.read(), isNull);

      final restore = RideRestoreCoordinator(reader: RideSnapshotStore.read);
      expect(restore.surfaceFor(await RideSnapshotStore.read()), RestoredSurface.home);
      expect(await restore.root(), isA<Home>());

      Widget? replaced;
      restore.showing = RestoredSurface.home;
      restore.debugAtRoot = () => true;
      restore.onReplaceRoot = (page) => replaced = page;
      expect(await restore.resumeIfNeeded(), isNull);
      expect(replaced, isNull);
      expect(restore.showing, isNot(RestoredSurface.finding));
      expect(restore.showing, isNot(RestoredSurface.waiting));

      controller.dispose();
    },
  );

  test(
    'waiting: cancel-first then late assign stays Home (not Waiting/Finding)',
    () async {
      final rt = _rt;
      rt.holdAssignment();
      final ride = AppScope.instance.ride..rideId = 'r-wait';
      var matches = 0;
      final controller = FindingDriverController(
        realtime: rt,
        ride: ride,
        store: FindingDriverRepository(),
      );
      controller.start(
        snapshot: findingSnap(rideId: 'r-wait'),
        onTick: (_) {},
        onMatched: () => matches += 1,
      );

      rt.assignNow();
      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(matches, 1);
      expect(ride.status, RideStatus.driverAssigned);

      // Leave Finding like pushReplacement → Waiting (active cleared).
      controller.dispose();
      expect(FindingDriverController.active, isNull);

      final waitingSnap = await RideSnapshotStore.read();
      expect(waitingSnap, isNotNull);
      final restore = RideRestoreCoordinator(reader: RideSnapshotStore.read);
      expect(restore.surfaceFor(waitingSnap), RestoredSurface.waiting);
      expect(restore.pageFor(waitingSnap), isA<WaitingForDriver>());
      restore.showing = RestoredSurface.waiting;

      await commitCancelFirst();

      expect(ride.status, RideStatus.cancelledByRider);
      expect(ride.suppressRestore, isTrue);
      expect(rt.cancelled, isTrue);
      expect(await RideSnapshotStore.read(), isNull);
      expect(restore.surfaceFor(await RideSnapshotStore.read()), RestoredSurface.home);

      // Late matched / searching events must not reopen Waiting or Finding.
      rt.assignNow();
      rt.emit(RideStatus.driverAssigned, sequence: 80);
      rt.emit(RideStatus.driverArriving, sequence: 81);
      rt.emit(RideStatus.driverWaiting, sequence: 82);
      rt.emit(RideStatus.findingDriver, sequence: 83);
      await Future<void>.delayed(const Duration(milliseconds: 40));

      expect(ride.status, RideStatus.cancelledByRider);
      expect(await RideSnapshotStore.read(), isNull);
      expect(await restore.root(), isA<Home>());

      Widget? replaced;
      restore.showing = RestoredSurface.home;
      restore.debugAtRoot = () => true;
      restore.onReplaceRoot = (page) => replaced = page;
      final resumed = await restore.resumeIfNeeded();
      expect(resumed, isNull);
      expect(replaced, isNull);
      expect(restore.showing, RestoredSurface.home);
      expect(replaced, isNot(isA<WaitingForDriver>()));
      expect(replaced, isNot(isA<FindingDrivers>()));
    },
  );

  test(
    'cancel-first bumps epoch so a late assigned snapshot save cannot revive Waiting',
    () async {
      final rt = _rt;
      rt.holdAssignment();
      final ride = AppScope.instance.ride..rideId = 'r-epoch';
      final controller = FindingDriverController(
        realtime: rt,
        ride: ride,
        store: FindingDriverRepository(),
      );
      controller.start(
        snapshot: findingSnap(rideId: 'r-epoch'),
        onTick: (_) {},
        onMatched: () {},
      );

      await commitCancelFirst();
      final epochAfterCancel = RideSnapshotStore.epoch;

      // In-flight matching persist that races after cancel-first.
      await RideSnapshotStore.save(
        findingSnap(rideId: 'r-epoch').copyWith(
          status: RideStatus.driverAssigned,
          savedAt: DateTime.now(),
          driver: MockRideRealtime.mockDriver,
        ),
      );
      rt.assignNow();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(RideSnapshotStore.epoch, greaterThanOrEqualTo(epochAfterCancel));
      expect(await RideSnapshotStore.read(), isNull);
      expect(ride.suppressRestore, isTrue);

      final restore = RideRestoreCoordinator(reader: RideSnapshotStore.read);
      expect(restore.surfaceFor(await RideSnapshotStore.read()), RestoredSurface.home);
      expect(await restore.root(), isA<Home>());

      controller.dispose();
    },
  );
}
