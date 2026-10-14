import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:movera_rider/app/di.dart';
import 'package:movera_rider/core/location/location_repository.dart';
import 'package:movera_rider/core/maps/geo_point.dart';

/// Turns the device position into a street address for a saved place.
typedef CurrentAddressResolver = Future<String> Function();

/// Why the current address could not be found, in words for the rider.
class CurrentAddressException implements Exception {
  const CurrentAddressException(this.message);
  final String message;
  @override
  String toString() => 'CurrentAddressException($message)';
}

/// FLOW-4: "Current location" used to save the literal text "Current
/// location". This reads a real fix (asking for permission the way Home
/// does) and reverse-geocodes it. It never returns a placeholder: every
/// failure throws [CurrentAddressException] with copy the screen can show.
Future<String> resolveCurrentAddress({
  LocationRepository? location,
  Future<String?> Function(GeoPoint point)? reverse,
  Duration fixTimeout = const Duration(seconds: 15),
}) async {
  final loc = location ?? AppScope.instance.location;
  final Future<String?> Function(GeoPoint) lookup =
      reverse ?? AppScope.instance.geocoding.reverse;
  final Position position;
  try {
    if (!await loc.isLocationServiceEnabled()) {
      throw const CurrentAddressException(
        'Location is turned off. Turn it on, or search for the address.',
      );
    }
    var permission = await loc.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await loc.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      throw const CurrentAddressException(
        'Location access is off for Movera. Allow it in Settings, or search '
        'for the address.',
      );
    }
    if (permission == LocationPermission.denied) {
      throw const CurrentAddressException(
        'Allow location access to use where you are, or search for the '
        'address.',
      );
    }
    position = await loc
        .getCurrentPosition(
          locationSettings: LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: fixTimeout,
          ),
        )
        .timeout(fixTimeout);
  } on CurrentAddressException {
    rethrow;
  } catch (_) {
    throw const CurrentAddressException(
      'We couldn’t find where you are. Search for the address instead.',
    );
  }
  String? address;
  try {
    address = await lookup(
      GeoPoint(position.latitude, position.longitude),
    ).timeout(const Duration(seconds: 10));
  } catch (_) {
    address = null;
  }
  final clean = address?.trim() ?? '';
  if (clean.isEmpty || clean.toLowerCase() == 'current location') {
    throw const CurrentAddressException(
      'We couldn’t find an address for where you are. Search for it instead.',
    );
  }
  return clean;
}
