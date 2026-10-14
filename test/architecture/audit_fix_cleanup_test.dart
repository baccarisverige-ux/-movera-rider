import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movera_rider/app/app.dart';
import 'package:movera_rider/features/ride_booking/application/ride_restore_coordinator.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// PR-14 cleanup (CODE-10, CODE-11, CODE-12, CODE-14). Every path below was
/// proved unused by a reference search before it was deleted; these checks
/// keep the dead files from coming back. Existence checks only, no source
/// reading.
void main() {
  test('CODE-10 dead Dart files stay deleted', () {
    const dead = [
      'lib/core/location/location_permission.dart',
      'lib/core/security/privacy.dart',
      'lib/features/history/presentation/history.dart',
      'lib/features/onboarding/presentation/onboarding.dart',
      'lib/features/ride_booking/domain/entities/vehicle.dart',
      'lib/features/ride_selection/presentation/ride_selection.dart',
      'lib/shared/animations/durations.dart',
      'lib/shared/design_system/movera_text_field.dart',
      'lib/shared/widgets/custom_btn.dart',
    ];
    for (final path in dead) {
      expect(File(path).existsSync(), isFalse, reason: path);
    }
  });

  test('CODE-12 unreferenced and Driver-app assets stay deleted', () {
    const images = [
      'black_dot.png',
      'google_pay_brand.svg',
      'logo.webp',
      'movera_airport_premium.webp',
      'movera_business_premium.webp',
      'movera_comfort_ride.webp',
      'movera_events_premium.webp',
      'movera_outings_premium.webp',
      'nav_account.png',
      'nav_map.png',
      'nav_payment.png',
      'nav_schedule.png',
      'onboard_grey_dot.png',
      'quick_add.png',
      'quick_home.png',
      'quick_work.png',
      'yellow_dot.png',
    ];
    const icons = [
      'call',
      'dbs_certificate',
      'documents',
      'driving_licence',
      'earnings',
      'edit_user',
      'favourite_icon',
      'future',
      'help_support_icon',
      'insurance',
      'legal_icon',
      'logout_icon',
      'mobile',
      'notification',
      'payment_icon',
      'pickup',
      'private_hire_licence',
      'profile_icon',
      'recent',
      'safety_shield',
      'saved',
      'schedule_calendar',
      'services',
      'settings',
      'sos',
      'trip',
      'trip_icon',
      'vehicle_licence',
      'verify_account',
      'work',
      'xl',
    ];
    for (final name in images) {
      final path = 'assets/images/$name';
      expect(File(path).existsSync(), isFalse, reason: path);
    }
    for (final name in icons) {
      final path = 'assets/icons/$name.png';
      expect(File(path).existsSync(), isFalse, reason: path);
    }
  });

  test('CODE-14 machine-specific generated files are not tracked', () {
    final result = Process.runSync('git', [
      'ls-files',
      '-ci',
      '--exclude-standard',
    ]);
    if (result.exitCode != 0) return; // not a git checkout (e.g. a tarball)
    final tracked = (result.stdout as String)
        .split('\n')
        .where((path) => path.trim().isNotEmpty)
        .where((path) => !path.startsWith('android/gradle'))
        .toList();
    expect(tracked, isEmpty, reason: tracked.join('\n'));
  });

  group('CODE-11 root app without GetX', () {
    setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
    setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));

    testWidgets('MoveraApp builds a plain MaterialApp in English', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);

      await tester.pumpWidget(const MoveraApp());
      await tester.pump(const Duration(milliseconds: 50));

      expect(
        find.byWidgetPredicate(
          (widget) => widget.runtimeType.toString() == 'GetMaterialApp',
        ),
        findsNothing,
      );
      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.locale, const Locale('en'));
      expect(app.debugShowCheckedModeBanner, isFalse);

      RideRestoreCoordinator.instance.showing = RestoredSurface.home;
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 2));
      debugDefaultTargetPlatformOverride = null;
    });
  });
}
