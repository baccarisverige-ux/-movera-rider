import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movera_rider/app/di.dart';
import 'package:movera_rider/core/realtime/ride_realtime.dart';
import 'package:movera_rider/features/ride_booking/domain/ride_status.dart';
import 'package:movera_rider/features/ride_complete/presentation/ride_completed.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppScope.instance.ride
      ..rideId = 'ride-post-trip-live'
      ..status = RideStatus.tripCompleted;
  });

  testWidgets(
    'completion surface follows backend-owned payment and rating states',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final realtime = _CompletionRealtime();
      addTearDown(realtime.dispose);

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(1200, 1600),
          minTextAdapt: true,
          splitScreenMode: true,
          builder: (_, __) => MaterialApp(
            home: RideCompleted(
              status: RideStatus.tripCompleted,
              rideId: 'ride-post-trip-live',
              realtime: realtime,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Trip complete'), findsOneWidget);
      expect(find.text('Trip completed'), findsOneWidget);
      expect(AppScope.instance.ride.status, RideStatus.tripCompleted);

      realtime.emit(RideStatus.paymentProcessing);
      await tester.pump();

      expect(find.text('Trip complete'), findsOneWidget);
      expect(find.text('Payment processing'), findsOneWidget);
      expect(AppScope.instance.ride.status, RideStatus.paymentProcessing);

      realtime.emit(RideStatus.paymentFinalized);
      await tester.pump();

      expect(find.text('Trip complete'), findsOneWidget);
      expect(find.text('Payment confirmed'), findsOneWidget);
      expect(AppScope.instance.ride.status, RideStatus.paymentFinalized);

      realtime.emit(RideStatus.ratingPending);
      await tester.pump();

      expect(find.text('Trip complete'), findsOneWidget);
      expect(find.text('Ready for feedback'), findsOneWidget);
      expect(find.text('How was your trip'), findsOneWidget);
      expect(
        find.text(
          'Rating and tip are optional. Tap Done when you are finished.',
        ),
        findsOneWidget,
      );
      expect(AppScope.instance.ride.status, RideStatus.ratingPending);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('completion surface ignores non-completion realtime states', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final realtime = _CompletionRealtime();
    addTearDown(realtime.dispose);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(1200, 1600),
        builder: (_, __) => MaterialApp(
          home: RideCompleted(
            status: RideStatus.tripCompleted,
            rideId: 'ride-post-trip-live',
            realtime: realtime,
          ),
        ),
      ),
    );
    await tester.pump();

    realtime.emit(RideStatus.driverWaiting);
    await tester.pump();

    expect(find.text('Trip complete'), findsOneWidget);
    expect(AppScope.instance.ride.status, RideStatus.tripCompleted);
    expect(tester.takeException(), isNull);
  });
}

class _CompletionRealtime implements RideRealtime {
  @override
  bool get supportsRiderSignals => true;

  final StreamController<RideRealtimeEvent> _controller =
      StreamController<RideRealtimeEvent>.broadcast(sync: true);
  String? _rideId;
  int _sequence = 0;

  @override
  Stream<RideRealtimeEvent> subscribe(String rideId) {
    _rideId = rideId;
    return _controller.stream;
  }

  void emit(RideStatus status) {
    final rideId = _rideId;
    if (rideId == null) return;
    _sequence += 1;
    _controller.add(
      RideRealtimeEvent(
        rideId: rideId,
        status: status,
        sequence: _sequence,
        at: DateTime.now(),
      ),
    );
  }

  @override
  Future<void> reconnectAndResync(String rideId) async {}

  @override
  Future<void> sendSignal({
    required String rideId,
    required RideRealtimeSignal signal,
    String? message,
  }) async {}

  @override
  void unsubscribe() {}

  @override
  void cancelRide() {}

  @override
  void researchAfterDriverCancel() {}

  @override
  void dispose() {
    _controller.close();
  }
}
