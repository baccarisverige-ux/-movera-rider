import 'package:flutter_test/flutter_test.dart';
import 'package:movera_rider/features/driver_arriving/application/driver_arriving_controller.dart';

void main() {
  test('arrival view is the only driver display source', () {
    final view = DriverArrivingController().arrival(rideType: 'Movera');
    expect(view.plate, 'L - 2323 F');
    expect(view.name, 'Merle Feeney');
    expect(view.rating, '5.0');
    expect(view.tagline, 'Top rated driver');
    expect(view.eta, '5 mins');
    expect(view.vehicleLabel, 'Movera');
    expect(view.vehicleImage, 'assets/images/comfort_ride.png');
    expect(view.photoAsset, 'assets/images/profile_img.png');
  });
}
