import 'package:movera_rider/core/location/geocoding_repository.dart';
import 'package:movera_rider/core/maps/geo_point.dart';
import 'package:movera_rider/core/utils/stale_guard.dart';
import 'package:movera_rider/shared/services/location_address.dart'
    as address_service;

class AppGeocoding implements GeocodingRepository {
  final stale = StaleGuard();

  @override
  Future<PlaceResult?> forward(String query) async {
    final generation = stale.next();
    final result = await address_service.geocodeAddress(query);
    if (!stale.isCurrent(generation) || result == null) return null;
    return PlaceResult(
      address: result.address,
      point: GeoPoint(result.latitude, result.longitude),
    );
  }

  @override
  Future<String?> reverse(GeoPoint point) async {
    final generation = stale.next();
    final result = await address_service.reverseGeocodeAddress(
      point.latitude,
      point.longitude,
    );
    if (!stale.isCurrent(generation)) return null;
    return result;
  }

  Future<String?> reverseGeocodeAddress(double latitude, double longitude) {
    return address_service.reverseGeocodeAddress(latitude, longitude);
  }

  Future<address_service.AddressCoordinates?> geocodeAddress(String address) {
    return address_service.geocodeAddress(address);
  }
}
