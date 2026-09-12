import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:movera_rider/core/location/app_geocoding.dart';
import 'package:movera_rider/core/location/location_repository.dart';
import 'package:movera_rider/core/motion/motion_engine.dart';
import 'package:movera_rider/features/home/application/home_controller.dart';
import 'package:movera_rider/shared/services/location_address.dart';

class _SlowGeo extends AppGeocoding {
  Duration delay = const Duration(milliseconds: 40);
  String resolved = 'Resolved address';

  @override
  Future<AddressCoordinates?> geocodeAddress(String address) async {
    await Future<void>.delayed(delay);
    return AddressCoordinates(
      latitude: 59.33,
      longitude: 18.06,
      address: resolved,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  HomeLocationController controllerOf(_SlowGeo geo) {
    return HomeLocationController(
      location: LocationRepository(),
      geocoding: geo,
      motion: MotionEngine(),
    );
  }

  test('overlay sets live on the location controller', () {
    final ctl = controllerOf(_SlowGeo());
    ctl.clearOverlays();
    expect(ctl.markers, isEmpty);
    expect(ctl.locationCircles, isEmpty);
    expect(ctl.locationDirection, isEmpty);
    ctl.dispose();
  });

  test('geocode result after dispose is ignored', () async {
    final geo = _SlowGeo();
    final ctl = controllerOf(geo);
    final pending = ctl.normaliseAddress('Stockholm Central Station');
    ctl.dispose();
    expect(await pending, 'Stockholm Central Station');
  });

  test('later geocode generation wins when the first finishes late', () async {
    final geo = _SlowGeo()..delay = const Duration(milliseconds: 50);
    final ctl = controllerOf(geo);
    final first = ctl.geocodeLatLng('Destination A');
    geo.delay = Duration.zero;
    geo.resolved = 'Destination B';
    final second = ctl.geocodeLatLng('Destination B');
    final late = await first;
    final latest = await second;
    expect(late, isNull);
    expect(latest, const LatLng(59.33, 18.06));
    ctl.dispose();
  });
}
