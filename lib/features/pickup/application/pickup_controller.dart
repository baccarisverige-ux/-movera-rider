import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:movera_rider/core/location/app_geocoding.dart';
import 'package:movera_rider/core/location/location_repository.dart';
import 'package:movera_rider/core/utils/stale_guard.dart';
import 'package:movera_rider/features/pickup/data/pickup_repository.dart';

enum PickupLocationFailure {
  servicesDisabled,
  permissionDenied,
  permissionDeniedForever,
  unavailable,
}

class PickupCurrentPositionResult {
  const PickupCurrentPositionResult._({this.position, this.failure});

  const PickupCurrentPositionResult.success(LatLng position)
      : this._(position: position);

  const PickupCurrentPositionResult.failure(PickupLocationFailure failure)
      : this._(failure: failure);

  final LatLng? position;
  final PickupLocationFailure? failure;

  bool get hasPosition => position != null;
}

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
    PickupRepository.instance.remember(
      address: address,
      lat: position.latitude,
      lng: position.longitude,
    );
    return address;
  }

  Future<PickupCurrentPositionResult> currentPosition() async {
    try {
      if (!await location.isLocationServiceEnabled()) {
        return const PickupCurrentPositionResult.failure(
          PickupLocationFailure.servicesDisabled,
        );
      }
      var permission = await location.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await location.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        return const PickupCurrentPositionResult.failure(
          PickupLocationFailure.permissionDeniedForever,
        );
      }
      if (permission == LocationPermission.denied) {
        return const PickupCurrentPositionResult.failure(
          PickupLocationFailure.permissionDenied,
        );
      }
      final current = await location.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      return PickupCurrentPositionResult.success(
        LatLng(current.latitude, current.longitude),
      );
    } catch (_) {
      return const PickupCurrentPositionResult.failure(
        PickupLocationFailure.unavailable,
      );
    }
  }

  Future<PickupMapFix?> search(String query) async {
    final result = await geocoding.geocodeAddress(query);
    if (result == null) return null;
    return PickupMapFix(
      position: LatLng(result.latitude, result.longitude),
      address: result.address,
    );
  }

  void dispose() => _stale.dispose();
}
