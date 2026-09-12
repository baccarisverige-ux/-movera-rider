import 'package:flutter_test/flutter_test.dart';
import 'package:movera_rider/core/maps/geo_point.dart';
import 'package:movera_rider/core/maps/google_map_provider.dart';
import 'package:movera_rider/core/maps/map_facade.dart';
import 'package:movera_rider/core/maps/map_camera_controller.dart';
import 'package:movera_rider/core/maps/map_lifecycle.dart';
import 'package:movera_rider/core/maps/map_owners.dart';
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
    maps.debugAttach(MapOwners.home);
    maps.debugAttach(MapOwners.pickup);
    expect(maps.activeOwner, MapOwners.pickup);
    expect(maps.generation, 2);
    maps.detach(owner: MapOwners.home);
    expect(maps.activeOwner, MapOwners.pickup);
    maps.detach(owner: MapOwners.pickup);
    expect(maps.activeOwner, MapOwners.home);
    maps.detach(owner: MapOwners.home);
    expect(maps.activeOwner, isNull);
  });

  test('re-attach moves owner to top and bumps generation', () {
    final maps = GoogleMapProvider();
    maps.debugAttach(MapOwners.home);
    maps.debugAttach(MapOwners.selectRide);
    maps.debugAttach(MapOwners.home);
    expect(maps.activeOwner, MapOwners.home);
    expect(maps.generation, 3);
    maps.detach(owner: MapOwners.selectRide);
    expect(maps.activeOwner, MapOwners.home);
    maps.detach(owner: MapOwners.home);
    expect(maps.activeOwner, MapOwners.selectRide);
  });

  test('dispose drops owners and never needs a plugin controller', () {
    final maps = GoogleMapProvider();
    maps.debugAttach(MapOwners.finding);
    maps.debugAttach(MapOwners.waiting);
    maps.dispose();
    expect(maps.activeOwner, isNull);
    expect(maps.controller, isNull);
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
