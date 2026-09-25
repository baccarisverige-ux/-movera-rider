import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movera_rider/app/di.dart';
import 'package:movera_rider/app/navigator_key.dart';
import 'package:movera_rider/app/router/routes.dart';
import 'package:movera_rider/features/ride_booking/domain/ride_status.dart';
import 'package:movera_rider/features/ride_complete/presentation/ride_completed.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Phase 69 journey coverage must exercise the production completion surface
/// through real taps and the named Rider route contract. It intentionally does
/// not recreate RideCompleted logic in a test stand-in.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    AppScope.instance.ride
      ..rideId = 'journey-book-1'
      ..status = RideStatus.ratingPending;
  });

  testWidgets('completed ride -> rating/tip surface -> Done -> Home', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(1200, 1600),
        builder: (_, __) => MaterialApp(
          navigatorKey: moveraNavigatorKey,
          home: const Scaffold(body: Text('journey-home')),
        ),
      ),
    );

    moveraNavigatorKey.currentState!.push(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: AppRoutes.rideCompleted),
        builder: (_) => const RideCompleted(
          status: RideStatus.ratingPending,
          rideId: 'journey-book-1',
          showConnectionBanner: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      ModalRoute.of(tester.element(find.byType(RideCompleted)))?.settings.name,
      AppRoutes.rideCompleted,
    );
    expect(AppScope.instance.ride.rideId, 'journey-book-1');
    expect(AppScope.instance.ride.status, RideStatus.ratingPending);
    expect(find.text('How was your trip'), findsOneWidget);
    expect(find.text('Tip your driver'), findsOneWidget);

    final star = find.byIcon(Icons.star_rounded).first;
    await tester.ensureVisible(star);
    await tester.tap(star);
    await tester.pump();

    final tip = find.text('20 kr').first;
    await tester.ensureVisible(tip);
    await tester.tap(tip);
    await tester.pump();
    expect(find.text('20 kr selected.'), findsOneWidget);

    final done = find.byKey(const ValueKey<String>('ride-completed-done'));
    await tester.ensureVisible(done);
    await tester.tap(done);
    await tester.pumpAndSettle();

    expect(find.text('journey-home'), findsOneWidget);
    expect(moveraNavigatorKey.currentState!.canPop(), isFalse);
    expect(AppScope.instance.ride.status, RideStatus.closed);
  });
}
