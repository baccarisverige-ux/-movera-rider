import 'package:flutter_test/flutter_test.dart';
import 'package:movera_rider/core/realtime/mock_ride_realtime.dart';
import 'package:movera_rider/features/ride_booking/domain/entities/matched_driver.dart';

void main() {
  test('driver card fields come from the match payload', () {
    const driver = MatchedDriver(
      id: 'drv_1',
      firstName: 'Alex',
      rating: 4.92,
      tripCount: 1284,
      vehicleMake: 'Volvo',
      vehicleModel: 'XC40',
      vehicleColor: 'Black',
      plate: 'MVR 421',
    );
    expect(driver.firstName, 'Alex');
    expect(driver.plate, 'MVR 421');
    expect(driver.vehicleLabel, 'Black Volvo XC40');
    expect(driver.ratingLabel, '4.92');
    expect(driver.tripsLabel, '1284 trips');
    expect(driver.yearsOnMovera, isNull);
    expect(driver.languages, isEmpty);
  });

  test('prototype mock driver is the centralized Linnea payload', () {
    const driver = MockRideRealtime.mockDriver;
    expect(driver.firstName, 'Linnea');
    expect(driver.rating, 4.97);
    expect(driver.vehicleMake, 'Volvo');
    expect(driver.vehicleModel, 'XC60');
    expect(driver.plate, 'MVR 418');
    expect(driver.vehicleLabel, 'Black Volvo XC60');
    expect(driver.ratingLabel, '4.97');
  });
}
