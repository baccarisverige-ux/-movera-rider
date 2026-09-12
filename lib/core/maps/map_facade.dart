import 'package:movera_rider/core/maps/geo_point.dart';
import 'package:movera_rider/core/maps/google_map_provider.dart';
import 'package:movera_rider/core/maps/map_camera_controller.dart';
import 'package:movera_rider/core/maps/map_lifecycle.dart';
import 'package:movera_rider/core/maps/marker_store.dart';
import 'package:movera_rider/core/maps/routing_service.dart';

class MapFacade {
  MapFacade({
    required this.provider,
    required this.camera,
    required this.markers,
    required this.lifecycle,
    RoutingService? routing,
  }) : routing = routing ?? RoutingService();

  final GoogleMapProvider provider;
  final MapCameraController camera;
  final MarkerStore markers;
  final MapLifecycleController lifecycle;
  final RoutingService routing;

  Future<void> focusOnPickup(GeoPoint point) => camera.focusOnPickup(point);

  void upsertMarker(String id, GeoPoint point, {double heading = 0}) {
    markers.upsert(id, point, heading: heading);
    provider.upsertMarker(id, point, heading: heading);
  }

  void removeMarker(String id) {
    markers.remove(id);
    provider.removeMarker(id);
  }

  void drawRoute(String id, GeoPoint from, GeoPoint to) {
    final line = routing.line(from: from, to: to);
    provider.drawRoute(id, line);
  }

  void clearRoute(String id) => provider.clearRoute(id);

  List<GeoPoint> route(String id) => provider.routes[id] ?? const [];
}
