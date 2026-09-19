import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movera_rider/features/active_ride/presentation/driver_arrived_sheet.dart';
import 'package:movera_rider/features/active_ride/presentation/driver_cancelled_sheet.dart';
import 'package:movera_rider/features/finding_driver/domain/cancellation_reason.dart';
import 'package:movera_rider/features/finding_driver/presentation/cancel_reason_sheet.dart';
import 'package:movera_rider/features/finding_driver/presentation/ride_details_sheet.dart';
import 'package:movera_rider/features/reservations/presentation/reservation_booked_popup.dart';
import 'package:movera_rider/features/ride_booking/domain/entities/matched_driver.dart';
import 'package:movera_rider/features/ride_booking/domain/ride_notes.dart';
import 'package:movera_rider/features/ride_selection/presentation/quick_ride_notes_sheet.dart';
import 'package:movera_rider/features/safety/presentation/ride_safety_kit.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Sheets and popups, which no test had built either. A shared widget is where
/// the CustomButton overflow hid, so these are worth the same treatment as the
/// full screens.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  const driver = MatchedDriver(
    id: 'drv_sheet',
    firstName: 'Elin',
    rating: 4.9,
    tripCount: 2140,
    vehicleMake: 'Volvo',
    vehicleModel: 'XC40',
    vehicleColor: 'Black',
    plate: 'MVR 204',
  );

  final sheets = <String, Widget Function()>{
    'Driver arrived': () => const DriverArrivedSheet(driver: driver),
    'Driver arrived, unknown': () => const DriverArrivedSheet(),
    'Driver cancelled': () => const DriverCancelledSheet(driverName: 'Elin'),
    'Driver cancelled, unknown': () => const DriverCancelledSheet(),
    'Safety kit': () => const RideSafetyKitSheet(rideId: 'ride_sheet'),
    'Quick notes': () => const QuickRideNotesSheet(),
    'Reservation booked': () => const ReservationBookedPopup(),
    'Cancel reason, searching': () =>
        const CancelReasonSheet(phase: CancelPhase.searching),
    'Cancel reason, matched': () =>
        const CancelReasonSheet(phase: CancelPhase.matched),
    'Cancel reason, reservation': () =>
        const CancelReasonSheet(phase: CancelPhase.reservation),
    'Ride details': () => RideDetailsSheet(
      pickupAddress: 'Sveavägen 1, Stockholm',
      destinationAddress: 'Hornsgatan 2, Stockholm',
      rideType: 'Movera',
      price: 259,
      paymentMethod: 'Apple Pay',
      notes: RideNotes.empty,
      canEditPickup: true,
      onEditPickup: () {},
      onEditDestination: () {},
      onCancelTrip: () {},
    ),
  };

  for (final viewport in const [
    Size(320, 568),
    Size(390, 844),
    Size(844, 390),
  ]) {
    for (final entry in sheets.entries) {
      testWidgets(
        '${entry.key} builds at ${viewport.width.toInt()}x${viewport.height.toInt()}',
        (tester) async {
          tester.view.physicalSize = viewport;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(
            ScreenUtilInit(
              designSize: const Size(390, 844),
              minTextAdapt: true,
              splitScreenMode: true,
              builder: (_, __) => MaterialApp(
                home: Scaffold(
                  // Sheets sit at the bottom of a screen, not filling one.
                  body: Align(
                    alignment: Alignment.bottomCenter,
                    child: SingleChildScrollView(child: entry.value()),
                  ),
                ),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 80));

          expect(
            tester.takeException(),
            isNull,
            reason:
                '${entry.key} threw at '
                '${viewport.width.toInt()}x${viewport.height.toInt()}',
          );
        },
      );
    }
  }
}
