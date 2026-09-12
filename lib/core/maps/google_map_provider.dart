import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:movera_rider/core/maps/camera_mode.dart';
import 'package:movera_rider/core/maps/geo_point.dart';
import 'package:movera_rider/core/maps/map_provider.dart';

class GoogleMapProvider implements MapProvider {
  GoogleMapController? _controller;
  CameraMode mode = CameraMode.followUser;

  void attach(GoogleMapController controller) {
    _controller = controller;
  }

  void detach() => _controller = null;

  @override
  Future<void> moveCamera(GeoPoint target, {double zoom = 15}) async {
    await _controller?.moveCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(target.latitude, target.longitude),
          zoom: zoom,
        ),
      ),
    );
  }

  @override
  Future<void> animateCamera(GeoPoint target, {double zoom = 15}) async {
    await _controller?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(target.latitude, target.longitude),
          zoom: zoom,
        ),
      ),
    );
  }

  @override
  Future<void> fitBounds(GeoPoint a, GeoPoint b, {double padding = 56}) async {
    await _controller?.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(
            a.latitude < b.latitude ? a.latitude : b.latitude,
            a.longitude < b.longitude ? a.longitude : b.longitude,
          ),
          northeast: LatLng(
            a.latitude > b.latitude ? a.latitude : b.latitude,
            a.longitude > b.longitude ? a.longitude : b.longitude,
          ),
        ),
        padding,
      ),
    );
  }

  @override
  void upsertMarker(String id, GeoPoint point, {double heading = 0}) {}

  @override
  void removeMarker(String id) {}

  @override
  void drawRoute(String id, List<GeoPoint> points) {}

  @override
  void clearRoute(String id) {}

  @override
  void dispose() {
    _controller = null;
  }
}
