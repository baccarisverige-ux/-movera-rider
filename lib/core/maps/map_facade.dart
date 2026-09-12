
import 'package:movera_rider/core/maps/geo_point.dart';
import 'package:movera_rider/core/maps/google_map_provider.dart';
import 'package:movera_rider/core/maps/map_camera_controller.dart';
import 'package:movera_rider/core/maps/map_lifecycle.dart';
import 'package:movera_rider/core/maps/marker_store.dart';

class MapFacade {
  MapFacade({
    required this.provider,
    required this.camera,
    required this.markers,
    required this.lifecycle,
  });

  final GoogleMapProvider provider;
  final MapCameraController camera;
  final MarkerStore markers;
  final MapLifecycleController lifecycle;

  Future<void> focusOnPickup(GeoPoint point) => camera.focusOnPickup(point);
}
