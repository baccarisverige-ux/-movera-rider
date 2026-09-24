import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:movera_rider/app/router/routes.dart';
import 'package:movera_rider/features/ride_selection/presentation/select_ride.dart';
import 'package:movera_rider/shared/widgets/navigation_transition.dart';

class _RecordingObserver extends NavigatorObserver {
  final List<Route<dynamic>> pushed = <Route<dynamic>>[];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushed.add(route);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('Select Ride transition carries its stable route name', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final navigatorKey = GlobalKey<NavigatorState>();
    final observer = _RecordingObserver();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        navigatorObservers: [observer],
        home: const Scaffold(body: Text('phase54-home')),
      ),
    );

    navigatorKey.currentState!.push(
      RideStageTransition(
        const SelectRide(
          pickupAddress: 'Stockholm Central',
          destinationAddress: 'Arlanda Airport',
          pickupPosition: LatLng(59.3300, 18.0590),
          destinationPosition: LatLng(59.6519, 17.9186),
        ),
      ),
    );
    await tester.pump();

    expect(observer.pushed.last.settings.name, AppRoutes.selectRide);
  });
}
