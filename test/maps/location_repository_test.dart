import 'package:flutter_test/flutter_test.dart';
import 'package:movera_rider/core/location/location_repository.dart';

void main() {
  test('location repository is constructible', () {
    expect(LocationRepository(), isA<LocationRepository>());
  });
}
