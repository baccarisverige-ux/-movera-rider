import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:movera_rider/app/di.dart';
import 'package:movera_rider/app/router/routes.dart';
import 'package:movera_rider/core/api/api_client.dart';
import 'package:movera_rider/core/api/in_process_mock_client.dart';
import 'package:movera_rider/core/realtime/mock_ride_realtime.dart';
import 'package:movera_rider/features/active_ride/application/active_ride_controller.dart';
import 'package:movera_rider/features/finding_driver/application/finding_driver_controller.dart';
import 'package:movera_rider/features/finding_driver/domain/cancellation_reason.dart';
import 'package:movera_rider/features/finding_driver/presentation/cancel_ride_sheet.dart';
import 'package:movera_rider/features/finding_driver/presentation/finding_drivers.dart';
import 'package:movera_rider/shared/widgets/navigation_transition.dart';
import 'package:movera_rider/features/ride_booking/data/ride_snapshot_store.dart';
import 'package:movera_rider/features/ride_booking/domain/ride_status.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The in-process backend without the platform token store, which never
/// answers inside widget tests.
ApiClient _api() => ApiClient(client: InProcessMockClient());

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    RideSnapshotStore.epoch = 0;
    FindingDriverController.active = null;
    AppScope.instance.ride
      ..rideId = null
      ..suppressRestore = false
      ..restoreFromBackend(RideStatus.idle);
  });

  Future<void> seed(String id, RideStatus status) async {
    AppScope.instance.ride.restoreFromBackend(status, id: id);
    await RideSnapshotStore.save(
      RideSnapshot(
        status: status,
        savedAt: DateTime.now(),
        pickupAddress: 'Sveavägen 1',
        destinationAddress: 'Hornsgatan 2',
        pickupLat: 59.34,
        pickupLng: 18.05,
        destinationLat: 59.31,
        destinationLng: 18.04,
        rideType: 'Movera',
        price: 259,
        paymentMethod: 'Apple Pay',
        rideId: id,
      ),
    );
  }

  Future<void> openCancelRoute(
    WidgetTester tester, {
    required String routeName,
    required String trigger,
    required CancelPhase phase,
  }) async {
    final nav = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: nav,
        home: const Scaffold(body: Text('journey-home')),
      ),
    );
    nav.currentState!.push(
      MaterialPageRoute<void>(
        settings: RouteSettings(name: routeName),
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              // Mirrors Waiting's production cancel: sheet, then the
              // server-first ActiveRideController.markCancelled (D-013).
              onPressed: () async {
                final outcome = await showCancelRideSheet(
                  context,
                  takingLonger: false,
                  phase: phase,
                );
                if (outcome.cancelled) {
                  await ActiveRideController(
                    api: _api(),
                  ).markCancelled(reasonId: outcome.reasonId);
                }
              },
              child: Text(trigger),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('rider cancels while still searching', (tester) async {
    // Drives the real Finding screen: Cancel request commits the cancel
    // first, and the why-sheet afterwards is feedback only (CODE-3).
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const rideId = 'journey-cancel-searching';
    await seed(rideId, RideStatus.findingDriver);
    final realtime = MockRideRealtime(assignAfter: const Duration(days: 1));
    addTearDown(realtime.dispose);
    final nav = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (_, __) => MaterialApp(
          navigatorKey: nav,
          home: const Scaffold(body: Text('journey-home')),
        ),
      ),
    );
    nav.currentState!.push(
      RideStageTransition(
        FindingDrivers(
          pickupAddress: 'Sveavägen 1',
          destinationAddress: 'Hornsgatan 2',
          pickupPosition: const LatLng(59.34, 18.05),
          destinationPosition: const LatLng(59.31, 18.04),
          rideType: 'Movera',
          price: 259,
          paymentMethod: 'Apple Pay',
          realtime: realtime,
          controller: FindingDriverController(realtime: realtime, api: _api()),
        ),
        settings: const RouteSettings(name: AppRoutes.findingDriver),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(FindingDrivers), findsOneWidget);
    expect(AppScope.instance.ride.rideId, rideId);
    expect(AppScope.instance.ride.status, RideStatus.findingDriver);
    expect(await RideSnapshotStore.read(), isNotNull);

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.widgetWithText(TextButton, 'Cancel request'));
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      if (find.text('Plans changed').evaluate().isNotEmpty) break;
    }
    await tester.pump(const Duration(milliseconds: 400));

    // Committed before the reason is asked for.
    expect(AppScope.instance.ride.status, RideStatus.cancelledByRider);
    expect(await RideSnapshotStore.read(), isNull);
    expect(find.text('Keep ride'), findsNothing);

    await tester.tap(find.text('Plans changed'));
    await tester.pump();
    await tester.tap(find.widgetWithText(TextButton, 'Send'));
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      if (find.byType(FindingDrivers).evaluate().isEmpty) break;
    }
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(FindingDrivers), findsNothing);
    expect(AppScope.instance.ride.rideId, rideId);
    expect(AppScope.instance.ride.status, RideStatus.cancelledByRider);
    expect(await RideSnapshotStore.read(), isNull);
  });

  testWidgets('rider cancels after driver assignment', (tester) async {
    const rideId = 'journey-cancel-matched';
    await seed(rideId, RideStatus.driverAssigned);
    await openCancelRoute(
      tester,
      routeName: AppRoutes.waitingForDriver,
      trigger: 'cancel-matched',
      phase: CancelPhase.matched,
    );

    final trigger = find.text('cancel-matched');
    expect(
      ModalRoute.of(tester.element(trigger))?.settings.name,
      AppRoutes.waitingForDriver,
    );
    expect(AppScope.instance.ride.rideId, rideId);
    expect(AppScope.instance.ride.status, RideStatus.driverAssigned);

    await tester.tap(trigger);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel request'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Driver/ride details are not suitable'));
    await tester.pump();
    await tester.tap(find.widgetWithText(TextButton, 'Cancel ride'));
    await tester.pumpAndSettle();

    expect(AppScope.instance.ride.rideId, rideId);
    expect(AppScope.instance.ride.status, RideStatus.cancelledByRider);
    expect(await RideSnapshotStore.read(), isNull);
  });
}
