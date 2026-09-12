import 'package:flutter_test/flutter_test.dart';
import 'package:movera_rider/core/realtime/mock_ride_realtime.dart';
import 'package:movera_rider/features/finding_driver/application/finding_driver_controller.dart';
import 'package:movera_rider/features/finding_driver/data/finding_driver_repository.dart';
import 'package:movera_rider/features/ride_booking/application/ride_session.dart';
import 'package:movera_rider/features/ride_booking/data/ride_snapshot_store.dart';
import 'package:movera_rider/features/ride_booking/domain/ride_status.dart';
import 'package:shared_preferences/shared_preferences.dart';

RideSnapshot snap() => RideSnapshot(
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
      rideId: 'r1',
    );

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('duplicate assignment matches once', () async {
    final rt = MockRideRealtime(assignAfter: const Duration(days: 1));
    final ride = RideSession()..rideId = 'r1';
    var matches = 0;
    final controller = FindingDriverController(
      realtime: rt,
      ride: ride,
      store: FindingDriverRepository(),
    );
    controller.start(
      seconds: 12,
      snapshot: snap(),
      onTick: (_) {},
      onMatched: () => matches += 1,
    );
    rt.emit(RideStatus.driverAssigned, sequence: 2);
    rt.emit(RideStatus.driverAssigned, sequence: 3);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(matches, 1);
    controller.dispose();
    rt.dispose();
  });

  test('assignment after cancel does not match', () async {
    final rt = MockRideRealtime(assignAfter: const Duration(days: 1));
    final ride = RideSession()..rideId = 'r1';
    var matches = 0;
    final controller = FindingDriverController(
      realtime: rt,
      ride: ride,
      store: FindingDriverRepository(),
    );
    controller.start(
      seconds: 12,
      snapshot: snap(),
      onTick: (_) {},
      onMatched: () => matches += 1,
    );
    controller.cancelSearch();
    rt.emit(RideStatus.driverAssigned, sequence: 9);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(matches, 0);
    controller.dispose();
    rt.dispose();
  });

  test('event after dispose has no effect', () async {
    final rt = MockRideRealtime(assignAfter: const Duration(days: 1));
    final ride = RideSession()..rideId = 'r1';
    var matches = 0;
    final controller = FindingDriverController(
      realtime: rt,
      ride: ride,
      store: FindingDriverRepository(),
    );
    controller.start(
      seconds: 12,
      snapshot: snap(),
      onTick: (_) {},
      onMatched: () => matches += 1,
    );
    controller.dispose();
    rt.emit(RideStatus.driverAssigned, sequence: 4);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(matches, 0);
    rt.dispose();
  });

  test('stale sequence is ignored', () async {
    final rt = MockRideRealtime(assignAfter: const Duration(days: 1));
    final ride = RideSession()..rideId = 'r1';
    var matches = 0;
    final controller = FindingDriverController(
      realtime: rt,
      ride: ride,
      store: FindingDriverRepository(),
    );
    controller.start(
      seconds: 12,
      snapshot: snap(),
      onTick: (_) {},
      onMatched: () => matches += 1,
    );
    rt.emit(RideStatus.findingDriver, sequence: 5);
    rt.emit(RideStatus.driverAssigned, sequence: 2);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(matches, 0);
    controller.dispose();
    rt.dispose();
  });
}
