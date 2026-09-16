import 'package:flutter_test/flutter_test.dart';
import 'package:movera_rider/core/realtime/mock_ride_realtime.dart';
import 'package:movera_rider/features/finding_driver/application/finding_driver_controller.dart';
import 'package:movera_rider/features/finding_driver/data/finding_driver_repository.dart';
import 'package:movera_rider/features/history/data/on_demand_ride_history_store.dart';
import 'package:movera_rider/features/ride_booking/application/ride_session.dart';
import 'package:movera_rider/features/ride_booking/data/ride_snapshot_store.dart';
import 'package:movera_rider/features/ride_booking/domain/ride_status.dart';
import 'package:shared_preferences/shared_preferences.dart';

RideSnapshot _snapshot() => RideSnapshot(
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
  rideId: 'external-terminal-ride',
);

FindingDriverController _controller(MockRideRealtime realtime, RideSession ride) {
  return FindingDriverController(
    realtime: realtime,
    ride: ride,
    store: FindingDriverRepository(),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    RideSnapshotStore.epoch = 0;
  });

  test('no-driver event ends Finding and clears the active snapshot', () async {
    final realtime = MockRideRealtime(assignAfter: const Duration(days: 1));
    addTearDown(realtime.dispose);
    final ride = RideSession()..rideId = 'external-terminal-ride';
    final snapshot = _snapshot();
    await RideSnapshotStore.save(snapshot);

    final controller = _controller(realtime, ride);
    addTearDown(controller.dispose);
    controller.start(snapshot: snapshot, onTick: (_) {}, onMatched: () {});

    realtime.emit(RideStatus.noDriverFound, sequence: 4);
    await Future<void>.delayed(const Duration(milliseconds: 30));

    expect(ride.status, RideStatus.noDriverFound);
    expect(controller.matchCount, 0);
    expect(await RideSnapshotStore.read(), isNull);
  });

  test('driver cancellation during search archives once then clears snapshot', () async {
    final realtime = MockRideRealtime(assignAfter: const Duration(days: 1));
    addTearDown(realtime.dispose);
    final ride = RideSession()..rideId = 'external-terminal-ride';
    final snapshot = _snapshot();
    await RideSnapshotStore.save(snapshot);

    final controller = _controller(realtime, ride);
    addTearDown(controller.dispose);
    controller.start(snapshot: snapshot, onTick: (_) {}, onMatched: () {});

    realtime.emit(RideStatus.cancelledByDriver, sequence: 5);
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(ride.status, RideStatus.cancelledByDriver);
    expect(await RideSnapshotStore.read(), isNull);
    final history = await OnDemandRideHistoryStore.read();
    expect(history, hasLength(1));
    expect(history.single.reservationId, 'ondemand-external-terminal-ride');
    expect(history.single.status.name, 'cancelled');
  });
}
