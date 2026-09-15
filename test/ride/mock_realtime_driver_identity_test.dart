import 'package:flutter_test/flutter_test.dart';
import 'package:movera_rider/core/realtime/mock_ride_realtime.dart';
import 'package:movera_rider/features/ride_booking/domain/entities/matched_driver.dart';
import 'package:movera_rider/features/ride_booking/domain/ride_status.dart';

void main() {
  test('mock assignment does not invent a driver identity or vehicle', () async {
    final realtime = MockRideRealtime(
      assignAfter: const Duration(hours: 1),
    );
    addTearDown(realtime.dispose);

    final events = realtime.subscribe('ride-without-driver-details');
    final assigned = events.firstWhere(
      (event) => event.status == RideStatus.driverAssigned,
    );

    realtime.assignNow();
    final event = await assigned;

    expect(event.status, RideStatus.driverAssigned);
    expect(event.driver, isNull);
    expect(realtime.lastDriver, isNull);
  });

  test('explicit real driver payload still passes through realtime unchanged', () async {
    final realtime = MockRideRealtime(
      assignAfter: const Duration(hours: 1),
    );
    addTearDown(realtime.dispose);

    const driver = MatchedDriver(
      id: 'driver-real-123',
      firstName: 'Real driver',
      rating: 4.8,
      tripCount: 321,
      vehicleMake: 'Vehicle make',
      vehicleModel: 'Vehicle model',
      vehicleColor: 'Vehicle color',
      plate: 'REAL 123',
    );

    final events = realtime.subscribe('ride-with-real-driver');
    final matched = events.firstWhere(
      (event) =>
          event.status == RideStatus.driverAssigned && event.driver != null,
    );

    realtime.emit(RideStatus.driverAssigned, driver: driver);
    final event = await matched;

    expect(event.driver?.id, driver.id);
    expect(event.driver?.firstName, driver.firstName);
    expect(event.driver?.rating, driver.rating);
    expect(event.driver?.tripCount, driver.tripCount);
    expect(event.driver?.vehicleLabel, driver.vehicleLabel);
    expect(event.driver?.plate, driver.plate);
  });
}
