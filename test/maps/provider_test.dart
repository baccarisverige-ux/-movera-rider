import 'package:flutter_test/flutter_test.dart';
import 'package:movera_rider/core/maps/geo_point.dart';
import 'package:movera_rider/core/maps/google_map_provider.dart';
import 'package:movera_rider/core/maps/map_facade.dart';
import 'package:movera_rider/core/maps/map_camera_controller.dart';
import 'package:movera_rider/core/maps/map_lifecycle.dart';
import 'package:movera_rider/core/maps/marker_store.dart';

void main() {
  test('provider stores markers and routes', () {
    final maps = GoogleMapProvider();
    maps.upsertMarker('pickup', const GeoPoint(59.33, 18.06));
    maps.drawRoute('select', const [
      GeoPoint(59.33, 18.06),
      GeoPoint(59.34, 18.07),
    ]);
    expect(maps.markers['pickup']?.point.latitude, 59.33);
    expect(maps.routes['select']?.length, 2);
    maps.removeMarker('pickup');
    maps.clearRoute('select');
    expect(maps.markers['pickup'], isNull);
    expect(maps.routes['select'], isNull);
  });

  test('older owner cannot detach newer map', () {
    final maps = GoogleMapProvider();
    expect(maps.activeOwner, isNull);
    maps.detach(owner: 'home');
    expect(maps.activeOwner, isNull);
  });

  test('facade coordinates marker and route state', () {
    final maps = GoogleMapProvider();
    final facade = MapFacade(
      provider: maps,
      camera: MapCameraController(maps),
      markers: MarkerStore(),
      lifecycle: MapLifecycleController(),
    );
    facade.upsertMarker('user', const GeoPoint(59.3, 18.0), heading: 45);
    facade.drawRoute(
      'select',
      const GeoPoint(59.3, 18.0),
      const GeoPoint(59.4, 18.1),
    );
    expect(facade.markers['user']?.heading, 45);
    expect(facade.route('select').length, 2);
  });
}
