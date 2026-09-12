import 'package:movera_rider/core/maps/geo_point.dart';

class PlaceResult {
  const PlaceResult({required this.address, required this.point});

  final String address;
  final GeoPoint point;
}

abstract class GeocodingRepository {
  Future<PlaceResult?> forward(String query);
  Future<String?> reverse(GeoPoint point);
}
