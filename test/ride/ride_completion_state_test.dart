import 'package:flutter_test/flutter_test.dart';
import 'package:movera_rider/app/di.dart';
import 'package:movera_rider/features/active_ride/application/active_ride_controller.dart';
import 'package:movera_rider/features/ride_booking/data/ride_snapshot_store.dart';
import 'package:movera_rider/features/ride_booking/domain/ride_status.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    RideSnapshotStore.epoch = 0;
    AppScope.instance.ride
      ..rideId = null
      ..status = RideStatus.idle;
  });

  RideSnapshot activeSnapshot() {
    return RideSnapshot(
      status: RideStatus.tripInProgress,
      savedAt: DateTime.now(),
      pickupAddress: 'Current location',
      destinationAddress: 'Stockholm Central Station',
      pickupLat: 59.3293,
      pickupLng: 18.0686,
      destinationLat: 59.3301,
      destinationLng: 18.058,
      rideType: 'Movera',
      price: 259,
      paymentMethod: 'Apple Pay',
      rideId: 'ride-complete-test',
    );
  }

  test('markCompleted keeps terminal status and clears active snapshot', () async {
    final snapshot = activeSnapshot();
    await RideSnapshotStore.save(snapshot);
    AppScope.instance.ride
      ..rideId = snapshot.rideId
      ..status = RideStatus.tripInProgress;

    await ActiveRideController().markCompleted(RideStatus.tripCompleted);

    expect(AppScope.instance.ride.status, RideStatus.tripCompleted);
    expect(await RideSnapshotStore.read(), isNull);
  });

  test('markCompleted rejects non-completed statuses', () async {
    await expectLater(
      ActiveRideController().markCompleted(RideStatus.driverAssigned),
      throwsA(isA<ArgumentError>()),
    );
  });
}
