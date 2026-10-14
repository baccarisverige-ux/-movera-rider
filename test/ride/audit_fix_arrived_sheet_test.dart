import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:movera_rider/app/di.dart';
import 'package:movera_rider/app/router/home_history_observer.dart';
import 'package:movera_rider/core/realtime/mock_ride_realtime.dart';
import 'package:movera_rider/core/realtime/ride_realtime.dart';
import 'package:movera_rider/features/active_ride/presentation/driver_arrived_sheet.dart';
import 'package:movera_rider/features/active_ride/presentation/waiting_for_driver.dart';
import 'package:movera_rider/features/ride_booking/data/ride_snapshot_store.dart';
import 'package:movera_rider/features/ride_booking/domain/ride_status.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// NAV-9: the trip starting closes the "driver arrived" sheet itself, not
/// whatever route happens to be on top of it.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    RideSnapshotStore.epoch = 0;
    AppScope.instance.ride
      ..rideId = null
      ..suppressRestore = false
      ..restoreFromBackend(RideStatus.idle);
  });

  testWidgets('trip start removes the arrived sheet and keeps the page '
      'pushed above it', (tester) async {
    const rideId = 'audit-nav9-arrived';
    await RideSnapshotStore.save(
      RideSnapshot(
        status: RideStatus.driverAssigned,
        savedAt: DateTime.now(),
        pickupAddress: 'Stockholm pickup',
        destinationAddress: 'Stockholm destination',
        pickupLat: 59.3293,
        pickupLng: 18.0686,
        destinationLat: 59.3326,
        destinationLng: 18.0649,
        rideType: 'Movera',
        price: 259,
        paymentMethod: 'Apple Pay',
        rideId: rideId,
      ),
    );
    AppScope.instance.ride.restoreFromBackend(
      RideStatus.driverAssigned,
      id: rideId,
    );

    final navigatorKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        navigatorObservers: [HomeHistoryObserver()],
        home: const Scaffold(body: Center(child: Text('audit-root'))),
      ),
    );
    navigatorKey.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => const WaitingForDriver(
          pickupAddress: 'Stockholm pickup',
          destinationAddress: 'Stockholm destination',
          pickupPosition: LatLng(59.3293, 18.0686),
          destinationPosition: LatLng(59.3326, 18.0649),
          rideType: 'Movera',
          price: 259,
          paymentMethod: 'Apple Pay',
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final realtime = AppScope.instance.rideRealtime as MockRideRealtime;
    realtime.holdAssignment();
    realtime.emit(
      RideStatus.driverWaiting,
      signal: RideRealtimeSignal.driverArrived,
      message: 'Driver arrived',
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 250));
    expect(find.byType(DriverArrivedSheet), findsOneWidget);

    // Something is pushed above the sheet (a notification tap, Safety).
    navigatorKey.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) =>
            const Scaffold(body: Center(child: Text('notification-page'))),
      ),
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 250));
    expect(find.text('notification-page'), findsOneWidget);

    realtime.emit(RideStatus.tripStarted, message: 'Trip started');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(DriverArrivedSheet, skipOffstage: false), findsNothing);
    expect(find.text('notification-page'), findsOneWidget);

    navigatorKey.currentState!.popUntil((route) => route.isFirst);
    await tester.pumpAndSettle(const Duration(milliseconds: 250));
    realtime.holdAssignment();
  });
}
