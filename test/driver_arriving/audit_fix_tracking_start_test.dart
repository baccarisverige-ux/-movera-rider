import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:movera_rider/core/realtime/ride_realtime.dart';
import 'package:movera_rider/features/driver_arriving/application/driver_tracking_controller.dart';
import 'package:movera_rider/features/ride_booking/application/ride_session.dart';
import 'package:movera_rider/features/ride_booking/data/ride_snapshot_store.dart';
import 'package:movera_rider/features/ride_booking/domain/ride_status.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Realtime extends RideRealtime {
  final c = StreamController<RideRealtimeEvent>.broadcast();
  @override
  Stream<RideRealtimeEvent> subscribe(String rideId) => c.stream;
  @override
  Future<void> reconnectAndResync(String rideId) async {}
  @override
  Future<void> sendSignal({
    required String rideId,
    required RideRealtimeSignal signal,
    String? message,
  }) async {}
  @override
  void unsubscribe() {}
  @override
  void cancelRide() {}
  @override
  void dispose() => c.close();
}

RideSnapshot _stored(RideStatus status, int version) => RideSnapshot(
  status: status,
  savedAt: DateTime.now(),
  pickupAddress: 'A',
  destinationAddress: 'B',
  pickupLat: 59.3,
  pickupLng: 18.0,
  destinationLat: 59.6,
  destinationLng: 17.9,
  rideType: 'Movera',
  price: 259,
  paymentMethod: 'cash',
  rideId: 'ride_1',
  version: version,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    RideSnapshotStore.epoch = 0;
  });

  DriverTrackingController tracking(_Realtime realtime, RideSession ride) =>
      DriverTrackingController(
        realtime: realtime,
        pickupLat: 59.3,
        pickupLng: 18.0,
        ride: ride,
      );

  test('RIDE-7: mounting Waiting on a restored in-trip ride keeps the stored '
      'stage', () async {
    await RideSnapshotStore.save(_stored(RideStatus.tripInProgress, 7));
    final realtime = _Realtime();
    addTearDown(realtime.dispose);
    final controller = tracking(realtime, RideSession(rideId: 'ride_1'));
    addTearDown(controller.dispose);
    controller.start(rideId: 'ride_1');
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect((await RideSnapshotStore.read())?.status, RideStatus.tripInProgress);
    expect((await RideSnapshotStore.read())?.version, 7);
  });

  test('RIDE-7: tracking starts from the known stage', () async {
    await RideSnapshotStore.save(_stored(RideStatus.tripInProgress, 7));
    final realtime = _Realtime();
    addTearDown(realtime.dispose);
    final controller = tracking(realtime, RideSession(rideId: 'ride_1'));
    addTearDown(controller.dispose);
    controller.start(
      rideId: 'ride_1',
      initialStatus: RideStatus.tripInProgress,
    );
    expect(controller.status, RideStatus.tripInProgress);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect((await RideSnapshotStore.read())?.status, RideStatus.tripInProgress);
  });

  test(
    'a newer server version may still replace a later stored stage',
    () async {
      // A driver dropped the ride and a new one was matched: the stage goes
      // back to "assigned" under a newer version.
      await RideSnapshotStore.save(_stored(RideStatus.driverArriving, 4));
      final realtime = _Realtime();
      addTearDown(realtime.dispose);
      final controller = tracking(realtime, RideSession(rideId: 'ride_1'));
      addTearDown(controller.dispose);
      controller.start(rideId: 'ride_1');
      realtime.c.add(
        RideRealtimeEvent(
          tripId: 'ride_1',
          status: RideStatus.driverAssigned,
          sequence: 6,
          version: 6,
          serverTime: DateTime.now().toUtc(),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));
      final stored = await RideSnapshotStore.read();
      expect(stored?.status, RideStatus.driverAssigned);
      expect(stored?.version, 6);
      expect(stored?.serverUpdatedAt, isNotNull);
    },
  );
}
