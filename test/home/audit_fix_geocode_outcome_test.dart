import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:movera_rider/core/location/app_geocoding.dart';
import 'package:movera_rider/core/location/geocoding_repository.dart';
import 'package:movera_rider/core/location/location_repository.dart';
import 'package:movera_rider/core/maps/geo_point.dart';
import 'package:movera_rider/core/motion/motion_engine.dart';
import 'package:movera_rider/features/home/application/home_controller.dart';

/// Answers each forward geocode when the test says so; null = not found.
class _Geo extends AppGeocoding {
  final List<Completer<PlaceResult?>> pending = [];

  @override
  Future<PlaceResult?> forward(String address) {
    final completer = Completer<PlaceResult?>();
    pending.add(completer);
    return completer.future;
  }
}

const _place = PlaceResult(
  point: GeoPoint(59.33, 18.06),
  address: 'Kungsgatan 1',
);

/// RIDE-18: a geocode superseded by a newer one is "stale", not "not found",
/// so Home can stop that flow quietly instead of showing an error.
void main() {
  late _Geo geo;
  late HomeLocationController ctl;

  setUp(() {
    geo = _Geo();
    ctl = HomeLocationController(
      location: LocationRepository(),
      geocoding: geo,
      motion: MotionEngine(),
    );
  });
  tearDown(() => ctl.dispose());

  test('place: the superseded call is stale, the newer one is found', () async {
    final first = ctl.resolvePlace('Kungsgatan');
    final second = ctl.resolvePlace('Kungsgatan 1');
    geo.pending[0].complete(_place);
    geo.pending[1].complete(_place);
    expect(await first, isA<GeocodeStale<({LatLng point, String address})>>());
    final latest = await second;
    expect(latest, isA<GeocodeFound<({LatLng point, String address})>>());
    expect(latest.valueOrNull?.address, 'Kungsgatan 1');
  });

  test('place: no match is not found, not stale', () async {
    final only = ctl.resolvePlace('Nowhere');
    geo.pending.single.complete(null);
    expect(
      await only,
      isA<GeocodeNotFound<({LatLng point, String address})>>(),
    );
  });

  test('point: stale and not found are told apart', () async {
    final first = ctl.resolveLatLng('A');
    final second = ctl.resolveLatLng('B');
    geo.pending[0].complete(_place);
    geo.pending[1].complete(null);
    expect(await first, isA<GeocodeStale<LatLng>>());
    expect(await second, isA<GeocodeNotFound<LatLng>>());
  });
}
