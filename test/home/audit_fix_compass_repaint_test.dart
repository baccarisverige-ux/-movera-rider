import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:movera_rider/core/location/app_geocoding.dart';
import 'package:movera_rider/core/location/location_repository.dart';
import 'package:movera_rider/core/motion/motion_engine.dart';
import 'package:movera_rider/features/home/application/home_controller.dart';

/// UI-12: a noisy compass used to repaint the puck (new marker set, map
/// rebuild, platform-channel update) on every 100 ms sample.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DateTime now;
  late double compass;

  HomeLocationController controller() => HomeLocationController(
    location: LocationRepository(),
    geocoding: AppGeocoding(),
    motion: MotionEngine(),
    startCompass: () async => true,
    readCompass: () => compass,
    stopCompass: () {},
    clock: () => now,
  );

  setUp(() {
    now = DateTime(2026, 10, 14, 12);
    compass = 0;
  });

  test('small turns are delivered at most every 250 ms', () async {
    final ctl = controller();
    var deliveries = 0;
    await ctl.startHeading(
      isMounted: () => true,
      onHeading: (_) {
        deliveries += 1;
      },
    );
    // One second of 100 ms samples drifting 0.3 degrees each.
    for (var i = 0; i < 10; i++) {
      compass += 0.3;
      ctl.pollHeading();
      now = now.add(const Duration(milliseconds: 100));
    }
    expect(deliveries, inInclusiveRange(1, 4));
    ctl.dispose();
  });

  test('a real turn is delivered straight away', () async {
    final ctl = controller();
    final delivered = <double>[];
    await ctl.startHeading(isMounted: () => true, onHeading: delivered.add);
    ctl.pollHeading();
    compass = 90;
    now = now.add(const Duration(milliseconds: 100));
    ctl.pollHeading();
    expect(delivered, hasLength(2));
    expect(delivered.last, ctl.heading);
    ctl.dispose();
  });

  test('painting the same puck again does not notify', () {
    final ctl = controller();
    var notified = 0;
    ctl.addListener(() => notified += 1);
    const at = LatLng(59.3293, 18.0686);
    final icon = BitmapDescriptor.defaultMarker;
    ctl.paintUserPuck(target: at, icon: icon, heading: 10);
    final markers = ctl.markers;
    ctl.paintUserPuck(target: at, icon: icon, heading: 10);
    expect(notified, 1);
    expect(identical(ctl.markers, markers), isTrue);
    ctl.paintUserPuck(target: at, icon: icon, heading: 20);
    expect(notified, 2);
    expect(ctl.markers.single.rotation, 20);
    ctl.dispose();
  });
}
