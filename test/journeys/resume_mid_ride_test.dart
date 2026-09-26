import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movera_rider/app/di.dart';
import 'package:movera_rider/app/lifecycle/app_lifecycle.dart';
import 'package:movera_rider/features/active_ride/presentation/waiting_for_driver.dart';
import 'package:movera_rider/features/finding_driver/presentation/finding_drivers.dart';
import 'package:movera_rider/features/ride_booking/application/ride_restore_coordinator.dart';
import 'package:movera_rider/features/ride_booking/data/ride_snapshot_store.dart';
import 'package:movera_rider/features/ride_booking/domain/ride_status.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    RideSnapshotStore.epoch = 0;
    AppScope.instance.ride
      ..rideId = null
      ..suppressRestore = false
      ..restoreFromBackend(RideStatus.idle);
    // AppScope owns one reconnect controller across the full test process.
    // Reset its exponential attempt counter so this journey starts from the
    // same connected baseline as a normally foregrounded Rider session.
    AppScope.instance.realtime.markConnected();
    final restore = RideRestoreCoordinator.instance;
    restore.showing = RestoredSurface.home;
    restore.debugAtRoot = () => true;
    restore.onReplaceRoot = null;
  });

  tearDown(() {
    final restore = RideRestoreCoordinator.instance;
    restore.showing = RestoredSurface.home;
    restore.debugAtRoot = null;
    restore.onReplaceRoot = null;
  });

  RideSnapshot snapshot(String id, RideStatus status) => RideSnapshot(
    status: status,
    savedAt: DateTime.now(),
    pickupAddress: 'Stockholm Central',
    destinationAddress: 'Arlanda Airport',
    pickupLat: 59.3293,
    pickupLng: 18.0686,
    destinationLat: 59.6519,
    destinationLng: 17.9186,
    rideType: 'Movera',
    price: 299,
    paymentMethod: 'Apple Pay',
    rideId: id,
  );

  Future<Widget?> backgroundAndResume(
    WidgetTester tester,
    RideSnapshot ride,
  ) async {
    await RideSnapshotStore.save(ride);
    Widget? shown;
    RideRestoreCoordinator.instance.onReplaceRoot = (page) => shown = page;

    final observer = AppLifecycleObserver()..attach();
    addTearDown(observer.detach);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Text('resume-host'))),
    );

    tester.binding.handleAppLifecycleStateChanged(
      AppLifecycleState.paused,
    );
    await tester.pump();
    expect((await RideSnapshotStore.read())?.rideId, ride.rideId);

    tester.binding.handleAppLifecycleStateChanged(
      AppLifecycleState.resumed,
    );
    // resumeIfNeeded first awaits the persisted snapshot. Give that async
    // read a frame to schedule the production reconnect backoff, then advance
    // fake time until the restore callback owns the authoritative surface.
    await tester.pump();
    for (var i = 0; i < 8 && shown == null; i++) {
      await tester.pump(const Duration(milliseconds: 500));
    }

    return shown;
  }

  testWidgets('background/resume restores Finding with the same ride', (
    tester,
  ) async {
    const rideId = 'journey-resume-finding';
    final shown = await backgroundAndResume(
      tester,
      snapshot(rideId, RideStatus.findingDriver),
    );

    expect(shown, isA<FindingDrivers>());
    expect(RideRestoreCoordinator.instance.showing, RestoredSurface.finding);
    expect(AppScope.instance.ride.rideId, rideId);
    expect(AppScope.instance.ride.status, RideStatus.findingDriver);
  });

  testWidgets('background/resume restores Waiting with the same ride', (
    tester,
  ) async {
    const rideId = 'journey-resume-waiting';
    final shown = await backgroundAndResume(
      tester,
      snapshot(rideId, RideStatus.driverAssigned),
    );

    expect(shown, isA<WaitingForDriver>());
    expect(RideRestoreCoordinator.instance.showing, RestoredSurface.waiting);
    expect(AppScope.instance.ride.rideId, rideId);
    expect(AppScope.instance.ride.status, RideStatus.driverAssigned);
  });

  testWidgets('background/resume restores an active trip without regression', (
    tester,
  ) async {
    const rideId = 'journey-resume-active';
    final shown = await backgroundAndResume(
      tester,
      snapshot(rideId, RideStatus.tripInProgress),
    );

    expect(shown, isA<WaitingForDriver>());
    expect(RideRestoreCoordinator.instance.showing, RestoredSurface.waiting);
    expect(AppScope.instance.ride.rideId, rideId);
    expect(AppScope.instance.ride.status, RideStatus.tripInProgress);
  });
}
