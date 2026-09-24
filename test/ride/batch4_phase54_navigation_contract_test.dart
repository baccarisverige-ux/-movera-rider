import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:movera_rider/app/router/routes.dart';
import 'package:movera_rider/features/reservations/presentation/ride_scheduled.dart';
import 'package:movera_rider/features/pickup/presentation/confirm_pickup_spot.dart';
import 'package:movera_rider/features/reservations/domain/reservation.dart';
import 'package:movera_rider/features/reservations/data/local_reservation_repository.dart';
import 'package:movera_rider/features/reservations/application/reservation_controller.dart';
import 'package:movera_rider/features/ride_selection/presentation/select_ride.dart';
import 'package:movera_rider/features/ride_selection/application/ride_selection_controller.dart';
import 'package:movera_rider/features/ride_booking/domain/entities/quote.dart';
import 'package:movera_rider/features/ride_booking/data/mock_quote_repository.dart';
import 'package:movera_rider/shared/widgets/navigation_transition.dart';

class _RecordingObserver extends NavigatorObserver {
  final List<Route<dynamic>> pushed = <Route<dynamic>>[];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushed.add(route);
  }
}


class _NeverQuotes implements QuoteRepository {
  int calls = 0;

  @override
  Future<RideQuote> quote({
    required String rideType,
    required int distanceMeters,
    int durationSeconds = 600,
    String? pickup,
    String? destination,
  }) {
    calls += 1;
    return Completer<RideQuote>().future;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('Select Ride transition carries its stable route name', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final navigatorKey = GlobalKey<NavigatorState>();
    final observer = _RecordingObserver();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        navigatorObservers: [observer],
        home: const Scaffold(body: Text('phase54-home')),
      ),
    );

    navigatorKey.currentState!.push(
      RideStageTransition(
        const SelectRide(
          pickupAddress: 'Stockholm Central',
          destinationAddress: 'Arlanda Airport',
          pickupPosition: LatLng(59.3300, 18.0590),
          destinationPosition: LatLng(59.6519, 17.9186),
        ),
        settings: const RouteSettings(name: AppRoutes.selectRide),
      ),
    );
    await tester.pump();

    expect(observer.pushed.last.settings.name, AppRoutes.selectRide);
  });
  testWidgets(
    'Ride Scheduled Done returns to named Home instead of assuming first route',
    (tester) async {
      final controller = ReservationController(
        store: LocalReservationRepository(
          storage: MemoryReservationStorage(),
          nextId: () => 'phase54-scheduled-home',
        ),
      );
      final created = await controller.create(
        ReservationDraft(
          scheduledPickupAt: DateTime(2026, 9, 24, 18),
          pickup: const ReservationPlace(
            label: 'Stockholm Central',
            lat: 59.3300,
            lng: 18.0590,
          ),
          destination: const ReservationPlace(
            label: 'Arlanda Airport',
            lat: 59.6519,
            lng: 17.9186,
          ),
          categoryId: 'movera',
          categoryName: 'Movera',
          categoryImage: 'assets/images/rides/movera.webp',
          price: 349,
          paymentMethod: 'Apple Pay',
        ),
      );

      final navigatorKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          home: const Scaffold(body: Text('phase54-shell')),
        ),
      );

      navigatorKey.currentState!.push(
        MaterialPageRoute<void>(
          settings: const RouteSettings(name: AppRoutes.home),
          builder: (_) => const Scaffold(body: Text('phase54-home')),
        ),
      );
      navigatorKey.currentState!.push(
        BottomToTopTransition<void>(
          RideScheduledPage(
            reservationId: created.reservationId,
            controller: controller,
          ),
          settings: const RouteSettings(name: AppRoutes.reservationScheduled),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Your ride is scheduled'), findsOneWidget);
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      expect(find.text('phase54-home'), findsOneWidget);
      expect(find.text('phase54-shell'), findsNothing);
    },
  );

  test(
    'Select Ride quote cancellation releases an in-flight quote batch',
    () async {
      final quotes = _NeverQuotes();
      final selection = RideSelectionController(quotes: quotes);
      final generation = selection.beginQuotes();

      final pending = selection.loadQuotes(
        generation: generation,
        pickup: 'Stockholm Central',
        destination: 'Arlanda Airport',
        parallelism: 1,
        timeout: const Duration(minutes: 5),
      );

      await Future<void>.delayed(Duration.zero);
      expect(quotes.calls, 1);
      expect(selection.hasPendingQuoteRequests, isTrue);

      selection.cancelPendingQuotes();
      await pending.timeout(const Duration(seconds: 1));

      expect(selection.hasPendingQuoteRequests, isFalse);
      selection.dispose();
    },
  );

  testWidgets('Back from Select Ride returns cleanly with no route exception', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final navigatorKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        home: const Scaffold(body: Text('phase54-select-parent')),
      ),
    );

    navigatorKey.currentState!.push(
      RideStageTransition(
        const SelectRide(
          pickupAddress: 'Stockholm Central',
          destinationAddress: 'Arlanda Airport',
          pickupPosition: LatLng(59.3300, 18.0590),
          destinationPosition: LatLng(59.6519, 17.9186),
        ),
        settings: const RouteSettings(name: AppRoutes.selectRide),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 160));

    expect(find.byType(SelectRide), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(find.text('phase54-select-parent'), findsOneWidget);
    expect(find.byType(SelectRide), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Confirm pickup carries the on-demand journey route identity', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final navigatorKey = GlobalKey<NavigatorState>();
    final observer = _RecordingObserver();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        navigatorObservers: [observer],
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () {
                ConfirmPickupSpot.open(
                  context,
                  initialPosition: const LatLng(59.3300, 18.0590),
                  initialAddress: 'Stockholm Central',
                );
              },
              child: const Text('open-confirm-pickup'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open-confirm-pickup'));
    await tester.pump();
    expect(observer.pushed.last.settings.name, '/ride/pickup-confirm');
  });

}
