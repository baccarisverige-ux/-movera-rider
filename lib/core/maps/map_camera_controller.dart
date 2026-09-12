
import 'package:movera_rider/core/maps/camera_mode.dart';
import 'package:movera_rider/core/maps/geo_point.dart';
import 'package:movera_rider/core/maps/google_map_provider.dart';
import 'package:movera_rider/core/utils/stale_guard.dart';

class MapCameraController {
  MapCameraController(this._maps);
  final GoogleMapProvider _maps;
  final stale = StaleGuard();

  bool showRecenter({required double zoom, required double metersFromUser}) {
    return zoom < 15.5 || metersFromUser > 35;
  }

  Future<void> focusOnPickup(GeoPoint point) {
    _maps.mode = CameraMode.pickupSelection;
    return _maps.animateCamera(point, zoom: 16);
  }

  Future<void> followUser(GeoPoint point) {
    final gen = stale.next();
    _maps.mode = CameraMode.followUser;
    return _run(gen, () => _maps.animateCamera(point, zoom: 15));
  }

  Future<void> _run(int gen, Future<void> Function() action) async {
    await action();
    if (!stale.isCurrent(gen)) return;
  }
}
