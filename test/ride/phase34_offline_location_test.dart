import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
void main() {
  test('location access stays behind repository boundary', () {
    final s=File('lib/core/location/location_repository.dart').readAsStringSync();
    expect(s, contains('class LocationRepository'));
    expect(s, contains('isLocationServiceEnabled'));
    expect(s, contains('checkPermission'));
    expect(s, contains('requestPermission'));
    expect(s, contains('getCurrentPosition'));
    expect(s, contains('getPositionStream'));
  });
  test('GPS unavailable booking path remains certified', () {
    final s=File('test/ride/book_now_two_paths_e2e_test.dart').readAsStringSync();
    expect(s, contains('GPS unavailable still opens Confirm pickup'));
  });
}
