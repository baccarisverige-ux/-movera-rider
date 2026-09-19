import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movera_rider/features/driver_arriving/presentation/driver_profile_page.dart';
import 'package:movera_rider/features/profile/application/profile_controller.dart';
import 'package:movera_rider/features/profile/data/profile_repository.dart';
import 'package:movera_rider/features/profile/presentation/account_checkup.dart';
import 'package:movera_rider/features/profile/presentation/account_widgets.dart';
import 'package:movera_rider/features/ride_booking/domain/entities/matched_driver.dart';
import 'package:movera_rider/features/safety/application/safety_controller.dart';
import 'package:movera_rider/features/safety/data/safety_data_sources.dart';
import 'package:movera_rider/features/safety/data/safety_store.dart';
import 'package:movera_rider/features/safety/presentation/ride_check_page.dart';
import 'package:movera_rider/features/saved_places/presentation/saved_places.dart';
import 'package:movera_rider/features/support/presentation/support.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Screens that need a fixture to build, so no test had ever built them.
/// The first nine argument-free ones yielded three real layout faults; these
/// are the rest worth checking.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  SafetyController safety() => SafetyController(
    session: SafetyStore(
      local: PreferencesSafetyLocalDataSource(memoryOnly: true),
    ),
  );

  ProfileController profile() => ProfileController(
    store: ProfileRepository(storageKey: 'screens_fixture_profile'),
  );

  const driver = MatchedDriver(
    id: 'drv_fixture',
    firstName: 'Elin',
    rating: 4.9,
    tripCount: 2140,
    vehicleMake: 'Volvo',
    vehicleModel: 'XC40',
    vehicleColor: 'Black',
    plate: 'MVR 204',
  );

  final screens = <String, Widget Function()>{
    'Ride check': () => RideCheckPage(controller: safety()),
    'Account checkup': () => AccountCheckupPage(controller: profile()),
    'Terms': () => const AccountLegalPage(kind: 'terms'),
    'Privacy': () => const AccountLegalPage(kind: 'privacy'),
    'Driver profile': () => const DriverProfilePage(driver: driver),
    'Saved places': () => SavedPlaces(),
    'Help article': () => const HelpArticle(
      title: 'How history works',
      body: 'Completed and cancelled rides appear in your history.',
    ),
  };

  for (final viewport in const [
    Size(320, 568),
    Size(390, 844),
    Size(844, 390),
  ]) {
    for (final entry in screens.entries) {
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
              builder: (_, __) => MaterialApp(home: entry.value()),
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
