import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:movera_rider/core/location/app_geocoding.dart';
import 'package:movera_rider/core/location/location_repository.dart';
import 'package:movera_rider/core/utils/stale_guard.dart';

class PickupMapFix {
  const PickupMapFix({required this.position, this.address});
  final LatLng position;
  final String? address;
}

class PickupMapController {
  PickupMapController({
    required this.location,
    required this.geocoding,
  });

  final LocationRepository location;
  final AppGeocoding geocoding;
  final StaleGuard _stale = StaleGuard();
  bool resolving = false;

  Future<String?> reverse(LatLng position) async {
    if (resolving) return null;
    resolving = true;
    final generation = _stale.next();
    final address = await geocoding.reverseGeocodeAddress(
      position.latitude,
      position.longitude,
    );
    resolving = false;
    if (!_stale.isCurrent(generation)) return null;
    return address;
  }

  Future<LatLng?> currentPosition() async {
    if (!await location.isLocationServiceEnabled()) return null;
    var permission = await location.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await location.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }
    final current = await location.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
    return LatLng(current.latitude, current.longitude);
  }

  void dispose() => _stale.dispose();
}
