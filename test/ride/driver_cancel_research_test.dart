import 'package:flutter_test/flutter_test.dart';
import 'package:movera_rider/core/realtime/mock_driver_pool.dart';
import 'package:movera_rider/core/realtime/mock_ride_realtime.dart';
import 'package:movera_rider/features/history/data/on_demand_ride_history_store.dart';
import 'package:movera_rider/features/ride_booking/domain/ride_status.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A driver dropping the ride before pickup is not the rider's ride ending.
/// Dispatch looks again, so the rider keeps their ride, their price and their
/// addresses — and must not be filed in History as a cancelled trip.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('driver cancel returns the ride to searching', () async {
    final rt = MockRideRealtime(assignAfter: const Duration(milliseconds: 10));
    addTearDown(rt.dispose);

    final seen = <RideStatus>[];
    rt.subscribe('ride_dc_1').listen((e) => seen.add(e.status));
    rt.assignNow();
    await Future<void>.delayed(const Duration(milliseconds: 60));
    expect(rt.lastStatus, RideStatus.driverAssigned);

    rt.cancelByDriver();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(seen, contains(RideStatus.cancelledByDriver));

    rt.researchAfterDriverCancel();
    await Future<void>.delayed(const Duration(milliseconds: 120));

    expect(rt.lastStatus, RideStatus.driverAssigned);
    expect(rt.lastDriver, isNotNull);
  });

  test('the replacement is a different driver', () async {
    final rt = MockRideRealtime(assignAfter: const Duration(milliseconds: 10));
    addTearDown(rt.dispose);

    rt.subscribe('ride_dc_2');
    rt.assignNow();
    await Future<void>.delayed(const Duration(milliseconds: 60));
    final first = rt.lastDriver;

    rt.cancelByDriver();
    rt.researchAfterDriverCancel();
    await Future<void>.delayed(const Duration(milliseconds: 120));

    expect(first, isNotNull);
    expect(rt.lastDriver, isNotNull);
    expect(rt.lastDriver!.id, isNot(first!.id));
  });

  test('a dropped ride is not filed as a cancelled trip', () async {
    final rt = MockRideRealtime(assignAfter: const Duration(milliseconds: 10));
    addTearDown(rt.dispose);

    rt.subscribe('ride_dc_3');
    rt.assignNow();
    await Future<void>.delayed(const Duration(milliseconds: 60));
    rt.cancelByDriver();
    rt.researchAfterDriverCancel();
    await Future<void>.delayed(const Duration(milliseconds: 120));

    expect(await OnDemandRideHistoryStore.read(), isEmpty);
  });

  test('a completed ride ignores a late driver cancel', () async {
    final rt = MockRideRealtime(assignAfter: const Duration(milliseconds: 10));
    addTearDown(rt.dispose);

    rt.subscribe('ride_dc_4');
    rt.assignNow();
    await Future<void>.delayed(const Duration(milliseconds: 40));
    rt.lastStatus = RideStatus.tripCompleted;

    rt.cancelByDriver();
    expect(rt.lastStatus, RideStatus.tripCompleted);
  });

  test('the pool offers someone new on each attempt', () {
    final first = MockDriverPool.forRide('ride_x');
    final second = MockDriverPool.forRide('ride_x', attempt: 1);
    final third = MockDriverPool.forRide('ride_x', attempt: 2);
    expect({first.id, second.id, third.id}.length, 3);
  });
}
