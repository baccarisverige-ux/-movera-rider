import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movera_rider/app/di.dart';
import 'package:movera_rider/app/navigator_key.dart';
import 'package:movera_rider/core/location/app_geocoding.dart';
import 'package:movera_rider/core/location/location_access_notice.dart';
import 'package:movera_rider/core/location/location_repository.dart';
import 'package:movera_rider/core/motion/motion_engine.dart';
import 'package:movera_rider/features/home/application/home_controller.dart';
import 'package:movera_rider/features/finding_driver/application/finding_driver_controller.dart';
import 'package:movera_rider/features/home/presentation/home.dart';
import 'package:movera_rider/features/home/presentation/widgets/home_location_notice.dart';
import 'package:movera_rider/features/ride_booking/domain/ride_status.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The platform side Home's real LocationRepository talks to: services on,
/// permission blocked (iOS after any refusal, Android "Don't ask again").
class _BlockedGeolocator extends GeolocatorPlatform {
  @override
  Future<bool> isLocationServiceEnabled() async => true;

  @override
  Future<LocationPermission> checkPermission() async =>
      LocationPermission.deniedForever;

  @override
  Future<LocationPermission> requestPermission() async =>
      LocationPermission.deniedForever;

  @override
  Future<Position?> getLastKnownPosition({
    bool forceLocationManager = false,
  }) async => null;
}

class _Location extends LocationRepository {
  _Location({required this.permission});

  bool services = true;
  LocationPermission permission;

  @override
  Future<bool> isLocationServiceEnabled() async => services;

  @override
  Future<LocationPermission> checkPermission() async => permission;

  @override
  Future<LocationPermission> requestPermission() async => permission;
}

HomeLocationController _controller(LocationRepository location) =>
    HomeLocationController(
      location: location,
      geocoding: AppGeocoding(),
      motion: MotionEngine(),
      startCompass: () async => false,
      readCompass: () => null,
      stopCompass: () {},
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('UI-16 location recovery', () {
    test('the controller names the problem for each refusal', () async {
      final location = _Location(permission: LocationPermission.deniedForever);
      final ctl = _controller(location);
      expect(ctl.accessIssue, isNull);
      await ctl.detectCurrent();
      expect(ctl.accessIssue, LocationAccessIssue.deniedForever);
      location.permission = LocationPermission.denied;
      await ctl.detectCurrent();
      expect(ctl.accessIssue, LocationAccessIssue.denied);
      location.services = false;
      await ctl.detectCurrent();
      expect(ctl.accessIssue, LocationAccessIssue.servicesOff);
      ctl.dispose();
    });

    testWidgets('a blocked permission shows the notice with Open settings', (
      tester,
    ) async {
      final ctl = _controller(
        _Location(permission: LocationPermission.deniedForever),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                HomeLocationNotice(location: ctl, bottom: 100, onRetry: () {}),
              ],
            ),
          ),
        ),
      );
      expect(
        find.byKey(const ValueKey('location-access-notice')),
        findsNothing,
      );
      await ctl.detectCurrent();
      await tester.pump();
      expect(
        find.byKey(const ValueKey('location-access-notice')),
        findsOneWidget,
      );
      expect(find.text('Open settings'), findsOneWidget);
      // Dismissed for this problem.
      await tester.tap(find.byTooltip('Dismiss'));
      await tester.pump();
      expect(
        find.byKey(const ValueKey('location-access-notice')),
        findsNothing,
      );
      ctl.dispose();
    });

    testWidgets('Open settings deep-links to the right system screen', (
      tester,
    ) async {
      var app = 0;
      var location = 0;
      Future<void> pump(LocationAccessIssue issue) => tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocationAccessNotice(
              issue: issue,
              isWeb: false,
              openAppSettings: () async {
                app += 1;
                return true;
              },
              openLocationSettings: () async {
                location += 1;
                return true;
              },
            ),
          ),
        ),
      );
      await pump(LocationAccessIssue.deniedForever);
      await tester.tap(find.text('Open settings'));
      await pump(LocationAccessIssue.servicesOff);
      await tester.tap(find.text('Open settings'));
      expect(app, 1);
      expect(location, 1);
    });

    testWidgets('a plain refusal asks again; the web explains instead', (
      tester,
    ) async {
      var retries = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocationAccessNotice(
              issue: LocationAccessIssue.denied,
              isWeb: false,
              onRetry: () => retries += 1,
            ),
          ),
        ),
      );
      await tester.tap(find.text('Allow location'));
      expect(retries, 1);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocationAccessNotice(
              issue: LocationAccessIssue.deniedForever,
              isWeb: true,
              onRetry: () => retries += 1,
            ),
          ),
        ),
      );
      expect(find.text('Open settings'), findsNothing);
      expect(find.textContaining('browser settings'), findsOneWidget);
      await tester.tap(find.text('Try again'));
      expect(retries, 2);
    });

    testWidgets('Home shows the notice when location is blocked', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      debugDefaultTargetPlatformOverride = TargetPlatform.linux;
      final previous = GeolocatorPlatform.instance;
      GeolocatorPlatform.instance = _BlockedGeolocator();
      SharedPreferences.setMockInitialValues(<String, Object>{});
      FindingDriverController.active = null;
      AppScope.instance.ride
        ..rideId = null
        ..status = RideStatus.idle;

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(390, 844),
          minTextAdapt: true,
          splitScreenMode: true,
          builder: (_, __) =>
              MaterialApp(navigatorKey: moveraNavigatorKey, home: const Home()),
        ),
      );
      await tester.pump(const Duration(milliseconds: 800));
      expect(find.byType(HomeLocationNotice), findsOneWidget);
      expect(
        find.byKey(const ValueKey('location-access-notice')),
        findsOneWidget,
      );
      expect(find.text('Location access is off'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 10));
      GeolocatorPlatform.instance = previous;
      debugDefaultTargetPlatformOverride = null;
    });
  });

  testWidgets('CODE-19 native without a compass runs no heading poller', (
    tester,
  ) async {
    var reads = 0;
    final ctl = HomeLocationController(
      location: LocationRepository(),
      geocoding: AppGeocoding(),
      motion: MotionEngine(),
      startCompass: () async => false,
      readCompass: () {
        reads += 1;
        return null;
      },
      stopCompass: () {},
      compassSupported: false,
    );
    await ctl.startHeading(isMounted: () => true, onHeading: (_) {});
    await tester.pump(const Duration(seconds: 2));
    expect(reads, 0);
    expect(ctl.hasCompassHeading, isFalse);
    ctl.dispose();
  });
}
