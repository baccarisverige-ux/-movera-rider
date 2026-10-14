import 'package:flutter_test/flutter_test.dart';
import 'package:movera_rider/features/ride_booking/data/ride_snapshot_store.dart';
import 'package:movera_rider/features/ride_booking/domain/ride_status.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// RIDE-6: a read -> modify -> save that read before a clear (for example a
/// live-status persist racing the cancel commit) must never write the ride
/// back after the clear.
RideSnapshot _snap(String rideId) => RideSnapshot(
  status: RideStatus.driverAssigned,
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
  rideId: rideId,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    RideSnapshotStore.epoch = 0;
  });

  test(
    'a persist that read before clear does not resurrect the ride',
    () async {
      await RideSnapshotStore.save(_snap('ride_1'));
      // Mirrors DriverTrackingController._persistLiveStatus: read, then save.
      final persist = () async {
        final stored = await RideSnapshotStore.read();
        if (stored == null) return;
        await RideSnapshotStore.save(
          stored.copyWith(
            status: RideStatus.driverArriving,
            savedAt: DateTime.now(),
          ),
        );
      }();
      // The cancel commit clears the store meanwhile.
      final clear = RideSnapshotStore.clear();
      await Future.wait([persist, clear]);

      expect(await RideSnapshotStore.read(), isNull);
    },
  );

  test('a snapshot read before clear and saved later is dropped', () async {
    await RideSnapshotStore.save(_snap('ride_2'));
    final stored = await RideSnapshotStore.readForArchive();
    await RideSnapshotStore.clear();
    await RideSnapshotStore.save(
      stored!.copyWith(status: RideStatus.driverWaiting),
    );
    expect(await RideSnapshotStore.read(), isNull);
  });

  test('read -> save with no clear in between still persists', () async {
    await RideSnapshotStore.save(_snap('ride_3'));
    final stored = await RideSnapshotStore.read();
    await RideSnapshotStore.save(
      stored!.copyWith(status: RideStatus.driverArriving),
    );
    final after = await RideSnapshotStore.read();
    expect(after?.status, RideStatus.driverArriving);
    expect(after?.rideId, 'ride_3');
  });

  test('a fresh snapshot built after a clear can be saved', () async {
    await RideSnapshotStore.save(_snap('ride_4'));
    await RideSnapshotStore.clear();
    await RideSnapshotStore.save(_snap('ride_5'));
    expect((await RideSnapshotStore.read())?.rideId, 'ride_5');
  });
}
