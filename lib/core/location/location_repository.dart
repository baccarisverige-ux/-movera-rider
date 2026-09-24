import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// Screens talk to this, never to Geolocator.
class LocationRepository {
  const LocationRepository();
  @visibleForTesting
  Future<bool> isLocationServiceEnabled() {
    return Geolocator.isLocationServiceEnabled();
  }

  @visibleForTesting
  Future<LocationPermission> checkPermission() {
    return Geolocator.checkPermission();
  }

  @visibleForTesting
  Future<LocationPermission> requestPermission() {
    return Geolocator.requestPermission();
  }

  @visibleForTesting
  Future<Position> getCurrentPosition({LocationSettings? locationSettings}) {
    return Geolocator.getCurrentPosition(
      locationSettings: locationSettings ??
          const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  @visibleForTesting
  Stream<Position> getPositionStream({LocationSettings? locationSettings}) {
    return Geolocator.getPositionStream(locationSettings: locationSettings);
  }

  @visibleForTesting
  double distanceBetween(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }
}
