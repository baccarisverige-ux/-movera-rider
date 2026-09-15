import 'package:flutter_test/flutter_test.dart';
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
}
