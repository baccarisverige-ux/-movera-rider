import 'package:movera_rider/core/maps/geo_point.dart';

/// Map SDK is behind this. Screens never call Google Maps directly.
abstract class MapProvider {
  Future<void> moveCamera(GeoPoint target, {double zoom = 15});
  Future<void> animateCamera(GeoPoint target, {double zoom = 15, double bearing = 0});
  Future<void> fitBounds(GeoPoint a, GeoPoint b, {double padding = 56});
  void upsertMarker(String id, GeoPoint point, {double heading = 0});
  void removeMarker(String id);
  void drawRoute(String id, List<GeoPoint> points);
  void clearRoute(String id);
  void dispose();
}
