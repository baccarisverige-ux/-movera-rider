import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movera_rider/features/history/presentation/ride_history.dart';
import 'package:movera_rider/features/notifications/presentation/notifications.dart';
import 'package:movera_rider/features/profile/application/profile_controller.dart';
import 'package:movera_rider/features/profile/data/profile_repository.dart';
import 'package:movera_rider/features/profile/presentation/account_home.dart';
import 'package:movera_rider/features/promotions/presentation/promotions.dart';
import 'package:movera_rider/features/reservations/application/reservation_controller.dart';
import 'package:movera_rider/features/reservations/data/local_reservation_repository.dart';
import 'package:movera_rider/features/ride_complete/presentation/ride_completed.dart';
import 'package:movera_rider/features/scheduled_rides/presentation/schedule_ride.dart';
import 'package:movera_rider/features/support/presentation/support.dart';
import 'package:movera_rider/features/wallet/presentation/wallet.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> setViewport(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
  }

  Future<void> pumpResponsive(
    WidgetTester tester,
    Widget screen, {
    required Size viewport,
    required String label,
  }) async {
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 844),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (_, __) => MaterialApp(home: screen),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester.takeException(),
      isNull,
      reason: '$label overflowed or threw at '
          '${viewport.width.toInt()}x${viewport.height.toInt()}',
    );
  }

  const completionViewports = [
    Size(320, 568),
    Size(375, 667),
    Size(390, 844),
    Size(430, 932),
    Size(768, 1024),
    Size(844, 390),
  ];

  for (final viewport in completionViewports) {
    testWidgets(
      'ride completion fits ${viewport.width.toInt()}x'
      '${viewport.height.toInt()}',
      (tester) async {
        await setViewport(tester, viewport);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await pumpResponsive(
          tester,
          const RideCompleted(),
          viewport: viewport,
          label: 'Ride completion',
        );
      },
    );
  }

  for (final viewport in const [Size(320, 568), Size(844, 390)]) {
    testWidgets(
      'primary frontend surfaces fit ${viewport.width.toInt()}x'
      '${viewport.height.toInt()}',
      (tester) async {
        await setViewport(tester, viewport);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final profile = ProfileController(
          store: ProfileRepository(storageKey: 'responsive_profile'),
        );
        final reservations = ReservationController(
          store: LocalReservationRepository(
            storage: MemoryReservationStorage(),
          ),
        );
        final screens = <(String, Widget)>[
          ('Notifications', const NotificationScreen()),
          ('Promotions', const Promotions()),
          ('Support', const SupportHome()),
          ('Profile', AccountHomePage(controller: profile)),
          ('History', RideHistory(reservations: reservations)),
          ('Schedule', const ScheduleRide()),
          ('Wallet', const WalletHome()),
        ];

        for (final entry in screens) {
          await pumpResponsive(
            tester,
            entry.$2,
            viewport: viewport,
            label: entry.$1,
          );
        }
      },
    );
  }
}
