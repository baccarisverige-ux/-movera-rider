import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movera_rider/app/di.dart';
import 'package:movera_rider/app/router/routes.dart';
import 'package:movera_rider/features/finding_driver/application/cancel_first.dart';
import 'package:movera_rider/features/finding_driver/domain/cancellation_reason.dart';
import 'package:movera_rider/features/finding_driver/presentation/cancel_ride_sheet.dart';
import 'package:movera_rider/features/ride_booking/data/ride_snapshot_store.dart';
import 'package:movera_rider/features/ride_booking/domain/ride_status.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    RideSnapshotStore.epoch = 0;
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
              onPressed: () async {
                final outcome = await showCancelRideSheet(
                  context,
                  takingLonger: false,
                  phase: phase,
                );
                if (outcome.cancelled) {
                  await commitCancelFirst(reasonId: outcome.reasonId);
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
    const rideId = 'journey-cancel-searching';
    await seed(rideId, RideStatus.findingDriver);
    await openCancelRoute(
      tester,
      routeName: AppRoutes.findingDriver,
      trigger: 'cancel-searching',
      phase: CancelPhase.searching,
    );

    final trigger = find.text('cancel-searching');
    expect(trigger, findsOneWidget);
    expect(
      ModalRoute.of(tester.element(trigger))?.settings.name,
      AppRoutes.findingDriver,
    );
    expect(AppScope.instance.ride.rideId, rideId);
    expect(AppScope.instance.ride.status, RideStatus.findingDriver);

    await tester.tap(trigger);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel request'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Plans changed'));
    await tester.pump();
    await tester.tap(find.widgetWithText(TextButton, 'Cancel ride'));
    await tester.pumpAndSettle();

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
