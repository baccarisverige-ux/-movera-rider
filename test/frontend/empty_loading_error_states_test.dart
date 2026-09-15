import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movera_rider/features/active_ride/presentation/waiting_sheet_bits.dart';
import 'package:movera_rider/features/history/presentation/ride_history.dart';
import 'package:movera_rider/features/messages/presentation/chat.dart';
import 'package:movera_rider/features/notifications/presentation/notifications.dart';
import 'package:movera_rider/features/promotions/presentation/promotions.dart';
import 'package:movera_rider/features/reservations/application/reservation_controller.dart';
import 'package:movera_rider/features/reservations/data/local_reservation_repository.dart';
import 'package:movera_rider/features/reservations/domain/reservation.dart';
import 'package:movera_rider/features/ride_complete/presentation/add_tip.dart';
import 'package:movera_rider/features/ride_complete/presentation/driver_info.dart';
import 'package:movera_rider/features/ride_complete/presentation/trip_detail.dart';
import 'package:movera_rider/features/support/presentation/support.dart';
import 'package:movera_rider/shared/design_system/movera_empty_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  ReservationController emptyReservations() {
    return ReservationController(
      store: LocalReservationRepository(storage: MemoryReservationStorage()),
    );
  }

  Future<void> setViewport(WidgetTester tester, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Future<void> pumpScreen(
    WidgetTester tester,
    Widget screen, {
    Size viewport = const Size(390, 844),
    bool settle = true,
  }) async {
    await setViewport(tester, viewport);
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 844),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (_, __) => MaterialApp(home: screen),
      ),
    );
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
  }

  testWidgets('notifications empty state is designed and has no fake events', (
    tester,
  ) async {
    await pumpScreen(tester, const NotificationScreen());
    expect(find.byType(MoveraEmptyState), findsOneWidget);
    expect(find.text("You're all caught up."), findsOneWidget);
    expect(find.text('Driver assigned'), findsNothing);
    expect(find.textContaining(r'$10.00'), findsNothing);
    expect(find.textContaining('Marle'), findsNothing);
  });

  testWidgets('history loading does not show empty at the same time', (
    tester,
  ) async {
    final delayed = Completer<List<Reservation>>();
    await pumpScreen(
      tester,
      RideHistory(
        reservations: emptyReservations(),
        onDemandReader: () => delayed.future,
      ),
      settle: false,
    );
    await tester.tap(find.text('Completed'));
    await tester.pump();

    expect(find.text('Loading rides'), findsOneWidget);
    expect(find.text('No completed rides yet'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    delayed.complete(const []);
    await tester.pumpAndSettle();
    expect(find.text('Loading rides'), findsNothing);
    expect(find.text('No completed rides yet'), findsOneWidget);
    expect(find.text('Book a ride'), findsOneWidget);
  });

  testWidgets('history error offers a real retry without raw exceptions', (
    tester,
  ) async {
    var calls = 0;
    await pumpScreen(
      tester,
      RideHistory(
        reservations: emptyReservations(),
        onDemandReader: () async {
          calls += 1;
          if (calls == 1) {
            throw StateError('disk-corrupt-xyz');
          }
          return const [];
        },
      ),
    );
    await tester.tap(find.text('Completed'));
    await tester.pumpAndSettle();

    expect(find.text('Couldn’t load rides'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
    expect(find.textContaining('disk-corrupt-xyz'), findsNothing);
    expect(find.text('No completed rides yet'), findsNothing);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(find.text('Couldn’t load rides'), findsNothing);
    expect(find.text('No completed rides yet'), findsOneWidget);
  });

  testWidgets('history Book a ride returns to the previous screen', (
    tester,
  ) async {
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (_, __) => MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => RideHistory(
                          reservations: emptyReservations(),
                          onDemandReader: () async => const [],
                        ),
                      ),
                    );
                  },
                  child: const Text('Open history'),
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open history'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Completed'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Book a ride'));
    await tester.pumpAndSettle();

    expect(find.text('Open history'), findsOneWidget);
    expect(find.text('No completed rides yet'), findsNothing);
  });

  testWidgets('driver chat shows an honest empty conversation', (tester) async {
    await pumpScreen(tester, const Chat());
    expect(find.text('Messages'), findsOneWidget);
    expect(find.text("Driver’s name"), findsNothing);
    expect(find.text('No messages yet'), findsOneWidget);
    expect(
      find.textContaining('when the ride is connected'),
      findsOneWidget,
    );
  });

  testWidgets('waiting driver card is designed when no driver is matched', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      Scaffold(
        body: WaitingDriverCard(
          driver: null,
          onOpenProfile: () {},
          onCall: () {},
          onMore: () {},
        ),
      ),
    );
    expect(find.byType(MoveraEmptyState), findsOneWidget);
    expect(find.text('Driver details unavailable'), findsOneWidget);
    expect(find.byIcon(Icons.person_search_outlined), findsOneWidget);
    expect(find.textContaining('Merle'), findsNothing);
  });

  testWidgets('tip and receipt empties stay designed with no fake values', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      const Scaffold(
        body: SingleChildScrollView(
          child: Column(
            children: [
              RideCompletedAddTip(),
              RideCompletedTripDetail(),
              RideCompletedDriverInfo(),
            ],
          ),
        ),
      ),
    );
    expect(find.text('Tips unavailable'), findsOneWidget);
    expect(find.text('Trip details unavailable'), findsOneWidget);
    expect(find.text('Driver details unavailable'), findsOneWidget);
    expect(find.text(r'$1'), findsNothing);
    expect(find.textContaining('Skypulse'), findsNothing);
    expect(find.textContaining('I11/Street'), findsNothing);
    expect(find.textContaining('Marle'), findsNothing);
    expect(find.textContaining('RID2ESSA'), findsNothing);
  });

  Widget screenFor(String name) {
    switch (name) {
      case 'Notifications':
        return const NotificationScreen();
      case 'History':
        return RideHistory(
          reservations: emptyReservations(),
          onDemandReader: () async => const [],
        );
      case 'Support':
        return const SupportHome();
      case 'Promotions':
        return const Promotions();
      case 'Chat':
        return const Chat();
      case 'Tip':
        return const Scaffold(body: RideCompletedAddTip());
      default:
        throw StateError('Unknown empty-state screen: $name');
    }
  }

  for (final viewport in const [
    Size(320, 568),
    Size(390, 844),
    Size(844, 390),
  ]) {
    for (final name in const [
      'Notifications',
      'History',
      'Support',
      'Promotions',
      'Chat',
      'Tip',
    ]) {
      testWidgets(
        '$name empty state fits ${viewport.width.toInt()}x${viewport.height.toInt()}',
        (tester) async {
          await pumpScreen(tester, screenFor(name), viewport: viewport);
          expect(
            tester.takeException(),
            isNull,
            reason:
                '$name overflowed at ${viewport.width.toInt()}x${viewport.height.toInt()}',
          );
        },
      );
    }
  }
}
