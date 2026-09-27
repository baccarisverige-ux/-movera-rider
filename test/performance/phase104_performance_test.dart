import 'dart:async';
import 'dart:io' show sleep;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:movera_rider/app/di.dart';
import 'package:movera_rider/core/realtime/ride_realtime.dart';
import 'package:movera_rider/features/active_ride/presentation/waiting_for_driver.dart';
import 'package:movera_rider/features/finding_driver/application/finding_driver_controller.dart';
import 'package:movera_rider/features/ride_booking/data/ride_snapshot_store.dart';
import 'package:movera_rider/features/ride_booking/domain/ride_status.dart';
import 'package:movera_rider/features/home/application/home_controller.dart';
import 'package:movera_rider/features/home/presentation/side_menu.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Batch 9 Phase 104 — U7 performance sweep (conservative subset).
void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    RideSnapshotStore.epoch = 0;
    FindingDriverController.active = null;
    AppScope.instance.ride
      ..rideId = null
      ..suppressRestore = false
      ..authoritativeVersion = null
      ..authoritativeUpdatedAt = null
      ..restoreFromBackend(RideStatus.idle);
  });

  group('rotated puck cache', () {
    test('headings snap to 5° buckets and wrap at 360°', () {
      final cache = RotatedPuckCache();
      expect(cache.bucketCount, 72);
      expect(cache.bucketFor(0), 0);
      expect(cache.bucketFor(2.4), 0);
      expect(cache.bucketFor(2.6), 1);
      expect(cache.bucketFor(359), 0);
      expect(cache.bucketFor(-5), 71);
      expect(cache.bucketFor(double.nan), 0);
      expect(cache.headingFor(3), 15);
    });

    test('a bitmap is stored once per pulse state and bucket', () {
      final cache = RotatedPuckCache();
      final icon = BitmapDescriptor.defaultMarker;
      expect(cache.lookup(expanded: false, bucket: 4), isNull);
      cache.store(expanded: false, bucket: 4, icon: icon);
      expect(cache.lookup(expanded: false, bucket: 4), same(icon));
      expect(cache.lookup(expanded: true, bucket: 4), isNull);
      expect(cache.length, 1);
      cache.clear();
      expect(cache.length, 0);
    });
  });

  group('side menu', () {
    Future<GlobalKey<ScaffoldState>> pumpMenu(
      WidgetTester tester,
      List<bool> covered,
    ) async {
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
              drawer: RiderSideMenu(onCoveredChanged: covered.add),
              body: const Center(child: Text('Home body')),
            ),
          ),
        ),
      );
      key.currentState!.openDrawer();
      await tester.pumpAndSettle();
      return key;
    }

    testWidgets('the page is pushed without waiting on the drawer close', (
      tester,
    ) async {
      final covered = <bool>[];
      await pumpMenu(tester, covered);
      await tester.tap(find.text('About'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      // Two frames in, the drawer (a ~250 ms close) is still closing but the
      // page is already on its way in.
      expect(find.text('About Movera'), findsWidgets);
      expect(covered, [true]);
      await tester.pumpAndSettle();
    });

    testWidgets('Home is told when a menu page covers it and when it leaves', (
      tester,
    ) async {
      final covered = <bool>[];
      await pumpMenu(tester, covered);
      await tester.tap(find.text('About'));
      await tester.pumpAndSettle();
      expect(covered, [true]);
      tester.state<NavigatorState>(find.byType(Navigator).first).pop();
      await tester.pumpAndSettle();
      expect(covered, [true, false]);
    });
  });

  testWidgets('Waiting moves the driver without rebuilding the map leaf', (
    tester,
  ) async {
    final feed = _ScriptedFeed();
    await RideSnapshotStore.save(
      RideSnapshot(
        status: RideStatus.driverAssigned,
        savedAt: DateTime.now(),
        pickupAddress: 'Pickup',
        destinationAddress: 'Destination',
        pickupLat: 59.3293,
        pickupLng: 18.0686,
        destinationLat: 59.3326,
        destinationLng: 18.0649,
        rideType: 'Movera',
        price: 259,
        paymentMethod: 'Apple Pay',
        rideId: 'perf-1',
      ),
    );
    AppScope.instance.ride.restoreFromBackend(
      RideStatus.driverAssigned,
      id: 'perf-1',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: WaitingForDriver(
          pickupAddress: 'Pickup',
          destinationAddress: 'Destination',
          pickupPosition: const LatLng(59.3293, 18.0686),
          destinationPosition: const LatLng(59.3326, 18.0649),
          rideType: 'Movera',
          price: 259,
          paymentMethod: 'Apple Pay',
          rideId: 'perf-1',
          realtime: feed,
          persistRideSnapshot: false,
        ),
      ),
    );
    await tester.pump();

    Future<void> driverAt(int sequence, double lat, double lng) async {
      // paintIfDue throttles on the wall clock, which pump() doesn't advance.
      sleep(const Duration(milliseconds: 420));
      feed.add(
        RideRealtimeEvent(
          rideId: 'perf-1',
          status: RideStatus.driverAssigned,
          sequence: sequence,
          latitude: lat,
          longitude: lng,
          locationAt: DateTime.now(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 450));
    }

    final map = find.byKey(const ValueKey('waiting-map'));
    final leaf = find.ancestor(of: map, matching: find.byType(RepaintBoundary));
    LatLng? driverMarker() {
      final markers = (tester.widget(map) as dynamic).markers as Set<Marker>;
      for (final marker in markers) {
        if (marker.markerId.value == 'driver') return marker.position;
      }
      return null;
    }

    await driverAt(1, 59.3400, 18.0500);
    final before = tester.widget(leaf.first);
    final first = driverMarker();
    expect(first, isNotNull);

    await driverAt(2, 59.3380, 18.0550);
    for (var i = 0; i < 6; i++) {
      sleep(const Duration(milliseconds: 60));
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(driverMarker(), isNot(first), reason: 'the driver still moves');
    expect(
      tester.widget(leaf.first),
      same(before),
      reason: 'the cached map leaf survives driver movement',
    );

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    await feed.close();
  });
}

/// A ride feed the test pushes events into.
class _ScriptedFeed implements RideRealtime {
  final StreamController<RideRealtimeEvent> _events =
      StreamController<RideRealtimeEvent>.broadcast();

  void add(RideRealtimeEvent event) => _events.add(event);

  Future<void> close() => _events.close();

  @override
  bool get supportsRiderSignals => false;
  @override
  Stream<RideRealtimeEvent> subscribe(String rideId) => _events.stream;
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
  void dispose() {}
}
