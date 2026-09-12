import 'package:geolocator/geolocator.dart';
import 'package:movera_rider/core/location/location_permission.dart';
import 'package:movera_rider/core/location/location_point.dart';
import 'package:movera_rider/core/maps/geo_point.dart';

class GeolocatorGateway {
  Future<AppLocationPermission> resolvePermission() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) return AppLocationPermission.servicesDisabled;
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    switch (permission) {
      case LocationPermission.denied:
        return AppLocationPermission.denied;
      case LocationPermission.deniedForever:
        return AppLocationPermission.permanentlyDenied;
      case LocationPermission.whileInUse:
        return AppLocationPermission.whileUsing;
      case LocationPermission.always:
        return AppLocationPermission.always;
      default:
        return AppLocationPermission.notDetermined;
    }
  }

  LocationPoint fromPosition(Position position) {
    return LocationPoint(
      point: GeoPoint(position.latitude, position.longitude),
      timestamp: position.timestamp,
      accuracyMeters: position.accuracy,
      speedMps: position.speed,
      heading: position.heading,
    );
  }
}
