import 'package:flutter_test/flutter_test.dart';
import 'package:movera_rider/app/di.dart';
import 'package:movera_rider/features/active_ride/application/active_ride_controller.dart';
import 'package:movera_rider/features/history/data/on_demand_ride_history_store.dart';
import 'package:movera_rider/features/reservations/domain/reservation_status.dart';
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

  RideSnapshot snapshot({
    String rideId = 'ride-1',
    RideStatus status = RideStatus.findingDriver,
    double price = 259,
  }) {
    return RideSnapshot(
      status: status,
      savedAt: DateTime.now().subtract(const Duration(minutes: 12)),
      pickupAddress: 'Current location',
      destinationAddress: 'Stockholm Central Station',
      pickupLat: 59.3293,
      pickupLng: 18.0686,
      destinationLat: 59.3301,
      destinationLng: 18.058,
      rideType: 'Movera',
      price: price,
      paymentMethod: 'Apple Pay',
      rideId: rideId,
    );
  }

  test('completed Book Now ride survives active snapshot clearing', () async {
    final active = snapshot();
    await RideSnapshotStore.save(active);

    await ActiveRideController().markCompleted(RideStatus.tripCompleted);

    final history = await OnDemandRideHistoryStore.read();
    expect(history, hasLength(1));
    expect(history.single.reservationId, 'ondemand-ride-1');
    expect(history.single.status, ReservationStatus.completed);
    expect(history.single.pickup.label, 'Current location');
    expect(history.single.destination.label, 'Stockholm Central Station');
    expect(history.single.price, 259);
    expect(await RideSnapshotStore.read(), isNull);
    expect(AppScope.instance.ride.status, RideStatus.tripCompleted);
  });

  test('cancelled Book Now ride is archived with its reason', () async {
    await OnDemandRideHistoryStore.archive(
      snapshot(rideId: 'ride-cancelled'),
      terminalStatus: RideStatus.cancelledByRider,
      cancellationReason: 'changed-plans',
    );

    final history = await OnDemandRideHistoryStore.read();
    expect(history, hasLength(1));
    expect(history.single.status, ReservationStatus.cancelled);
    expect(history.single.cancellationReason, 'changed-plans');
  });

  test('archive deduplicates retries by ride id', () async {
    final ride = snapshot(rideId: 'ride-retry');
    final firstEnd = DateTime.now().subtract(const Duration(minutes: 2));
    final secondEnd = DateTime.now().subtract(const Duration(minutes: 1));

    await OnDemandRideHistoryStore.archive(
      ride,
      terminalStatus: RideStatus.tripCompleted,
      endedAt: firstEnd,
    );
    await OnDemandRideHistoryStore.archive(
      ride,
      terminalStatus: RideStatus.paymentFinalized,
      endedAt: secondEnd,
    );

    final history = await OnDemandRideHistoryStore.read();
    expect(history, hasLength(1));
    expect(history.single.scheduledPickupAt, secondEnd);
  });

  test('completed surface contract excludes cancelled states', () {
    expect(RideStatus.tripCompleted.isCompletedSurface, isTrue);
    expect(RideStatus.paymentProcessing.isCompletedSurface, isTrue);
    expect(RideStatus.paymentFinalized.isCompletedSurface, isTrue);
    expect(RideStatus.ratingPending.isCompletedSurface, isTrue);
    expect(RideStatus.cancelledByRider.isCompletedSurface, isFalse);
  });
}
