import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movera_rider/features/history/presentation/ride_history.dart';
import 'package:movera_rider/features/home/presentation/side_menu.dart';
import 'package:movera_rider/features/profile/data/profile_repository.dart';
import 'package:movera_rider/features/reservations/application/reservation_controller.dart';
import 'package:movera_rider/features/reservations/data/local_reservation_repository.dart';
import 'package:movera_rider/features/reservations/domain/reservation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Batch 9 Phase 97 — U1 (menu pages return to the menu), D-026 (Ride
/// History "Book a ride" starts a booking), D-024 (profile empty copy).
void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<GlobalKey<ScaffoldState>> pumpHomeWithMenu(
    WidgetTester tester, {
    VoidCallback? onStartBooking,
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final key = GlobalKey<ScaffoldState>();
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (_, __) => MaterialApp(
          home: Scaffold(
            key: key,
            drawer: RiderSideMenu(onStartBooking: onStartBooking),
            body: const Center(child: Text('Home body')),
          ),
        ),
      ),
    );
    key.currentState!.openDrawer();
    await tester.pumpAndSettle();
    return key;
  }

  testWidgets('U1: Back from a menu page returns to the open menu', (
    tester,
  ) async {
    final scaffold = await pumpHomeWithMenu(tester);
    await tester.tap(find.text('About'));
    await tester.pumpAndSettle();
    expect(scaffold.currentState!.isDrawerOpen, isFalse);
    expect(find.text('About Movera'), findsWidgets);

    tester.state<NavigatorState>(find.byType(Navigator).first).pop();
    await tester.pumpAndSettle();
    expect(scaffold.currentState!.isDrawerOpen, isTrue);
    expect(find.text('About'), findsOneWidget);
  });

  testWidgets('U1: the menu does not reopen over a route pushed on top', (
    tester,
  ) async {
    final scaffold = await pumpHomeWithMenu(tester);
    await tester.tap(find.text('About'));
    await tester.pumpAndSettle();
    final nav = tester.state<NavigatorState>(find.byType(Navigator).first);
    // The page is replaced by something else: Home never becomes current.
    nav.pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('Elsewhere')),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Elsewhere'), findsOneWidget);
    expect(scaffold.currentState!.isDrawerOpen, isFalse);
  });

  testWidgets('D-026: Ride History "Book a ride" asks to start a booking', (
    tester,
  ) async {
    Object? result = 'unset';
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (_, __) => MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  result = await Navigator.of(context).push<Object?>(
                    MaterialPageRoute(
                      builder: (_) => RideHistory(
                        reservations: ReservationController(
                          store: LocalReservationRepository(
                            storage: MemoryReservationStorage(),
                          ),
                        ),
                        onDemandReader: () async => const <Reservation>[],
                      ),
                    ),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Completed'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Book a ride').first);
    await tester.pumpAndSettle();
    expect(result, RideHistory.startBookingResult);
  });

  test('D-026: the menu turns that result into a booking, not the menu', () {
    final menu = File(
      'lib/features/home/presentation/side_menu.dart',
    ).readAsStringSync();
    expect(menu, contains('result == RideHistory.startBookingResult'));
    expect(menu, contains('onStartBooking?.call();'));
    final home = File(
      'lib/features/home/presentation/home.dart',
    ).readAsStringSync();
    expect(
      home,
      contains('onStartBooking: () => unawaited(_openDestinationSheet())'),
    );
  });

  test('D-024: an empty profile never reads as a literal placeholder', () {
    expect(ProfileRepository.emptyDisplayName, isNot('Profile not set'));
    for (final path in [
      'lib/features/profile/data/profile_repository.dart',
      'lib/features/profile/presentation/account_home.dart',
    ]) {
      expect(
        File(path).readAsStringSync(),
        isNot(contains("'Profile not set'")),
        reason: path,
      );
    }
  });
}
