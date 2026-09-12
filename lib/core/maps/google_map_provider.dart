import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:movera_rider/core/maps/camera_mode.dart';
import 'package:movera_rider/core/maps/geo_point.dart';
import 'package:movera_rider/core/maps/map_provider.dart';
import 'package:movera_rider/core/maps/marker_store.dart';

class _OwnedMap {
  const _OwnedMap(this.owner, this.controller);
  final String owner;
  final GoogleMapController? controller;
}

class GoogleMapProvider implements MapProvider {
  final List<_OwnedMap> _owners = [];
  final MarkerStore markers = MarkerStore();
  final Map<String, List<GeoPoint>> routes = {};
  int generation = 0;
  CameraMode mode = CameraMode.followUser;

  GoogleMapController? get controller =>
      _owners.isEmpty ? null : _owners.last.controller;

  String? get activeOwner => _owners.isEmpty ? null : _owners.last.owner;

  void attach(GoogleMapController controller, {String owner = 'map'}) {
    _push(owner, controller);
  }

  /// Test hook for owner/generation without a plugin controller.
  @visibleForTesting
  void debugAttach(String owner) => _push(owner, null);

  void _push(String owner, GoogleMapController? controller) {
    generation += 1;
    _owners.removeWhere((item) => item.owner == owner);
    _owners.add(_OwnedMap(owner, controller));
  }

  /// Only the current owner may detach. Older stacked maps stay put.
  void detach({String owner = 'map'}) {
    if (_owners.isEmpty) return;
    if (_owners.last.owner != owner) return;
    _owners.removeLast();
  }

  @override
  Future<void> moveCamera(GeoPoint target, {double zoom = 15}) async {
    final map = controller;
    if (map == null) return;
    await map.moveCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(target.latitude, target.longitude),
          zoom: zoom,
        ),
      ),
    );
  }

  @override
  Future<void> animateCamera(
    GeoPoint target, {
    double zoom = 15,
    double bearing = 0,
  }) async {
    final map = controller;
    if (map == null) return;
    await map.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(target.latitude, target.longitude),
          zoom: zoom,
          bearing: bearing,
        ),
      ),
    );
  }

  @override
  Future<void> fitBounds(GeoPoint a, GeoPoint b, {double padding = 56}) async {
    final map = controller;
    if (map == null) return;
    await map.animateCamera(
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
  void upsertMarker(String id, GeoPoint point, {double heading = 0}) {
    markers.upsert(id, point, heading: heading);
  }

  @override
  void removeMarker(String id) => markers.remove(id);

  @override
  void drawRoute(String id, List<GeoPoint> points) => routes[id] = points;

  @override
  void clearRoute(String id) => routes.remove(id);

  @override
  void dispose() {
    // Never dispose plugin controllers. Drop ownership only.
    _owners.clear();
  }
}
