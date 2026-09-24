import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:movera_rider/app/di.dart';
import 'package:movera_rider/app/navigator_key.dart';
import 'package:movera_rider/shared/widgets/navigation_transition.dart';
import 'package:movera_rider/core/realtime/ride_realtime.dart';
import 'package:movera_rider/app/router/routes.dart';
import 'package:movera_rider/core/logging/app_log.dart';
import 'package:movera_rider/core/web/web_search_interrupted.dart';
import 'package:movera_rider/core/debug/web_qa_hooks.dart';
import 'package:movera_rider/features/active_ride/presentation/waiting_for_driver.dart';
import 'package:movera_rider/features/finding_driver/presentation/finding_drivers.dart';
import 'package:movera_rider/features/home/presentation/home.dart';
import 'package:movera_rider/features/ride_booking/data/ride_snapshot_store.dart';
import 'package:movera_rider/features/ride_booking/domain/ride_status.dart';
import 'package:movera_rider/features/ride_complete/data/last_completed_ride.dart';
import 'package:movera_rider/features/ride_complete/presentation/ride_completed.dart';

enum RestoredSurface { home, finding, waiting, complete }

class RideRestoreCoordinator {
  RideRestoreCoordinator({
    RideSnapshotStoreReader? reader,
    bool Function()? skipRestore,
  }) : _reader = reader ?? RideSnapshotStore.read,
       _skipRestore = skipRestore ?? defaultSkipRestore;

  final Future<RideSnapshot?> Function() _reader;
  final bool Function() _skipRestore;
  RestoredSurface showing = RestoredSurface.home;
  int restores = 0;
  void Function(Widget page)? onReplaceRoot;

  /// Set when a ride search was dropped rather than restored, so Home can say
  /// so instead of just appearing empty as though nothing had been going on.
  bool _searchInterrupted = false;

  /// Reads the flag and clears it, so the rider is told once.
  bool takeSearchInterrupted() {
    if (!_searchInterrupted) return false;
    _searchInterrupted = false;
    return true;
  }

  /// Record that a live ride was dropped rather than resumed.
  void noteSearchInterrupted() => _searchInterrupted = true;

  void _noteDropped(RestoredSurface surface) {
    if (surface == RestoredSurface.finding ||
        surface == RestoredSurface.waiting) {
      noteSearchInterrupted();
    }
  }

  /// Tests: pretend Profile/Wallet is open so resume must not navigate.
  bool Function()? debugAtRoot;

  static final instance = RideRestoreCoordinator();

  /// A live ride in this browser must survive reload, crash, PWA eviction
  /// and Safari tab recovery. localStorage is per-browser, so a stranger
  /// tapping the public link never sees someone else's trip.
  static bool defaultSkipRestore() => false;

  void goHome({bool replaceRoot = true}) {
    // Deliberately back to Home: nothing to explain on the next load.
    clearSearchLive();
    showing = RestoredSurface.home;
    reportRestoreSurface(RestoredSurface.home.name);
    unawaited(() async {
      try {
        await RideSnapshotStore.clear();
      } catch (_) {}
    }());
    // Normal pushed ride flows already reveal the existing Home when the
    // navigator pops to root. Rebuilding the root Home again causes a visible
    // double transition and unnecessary map/controller churn. Cold-restored
    // ride surfaces still need an explicit root replacement.
    if (replaceRoot) onReplaceRoot?.call(const Home());
  }

  bool replaceRootSurface(Widget page, RestoredSurface surface) {
    final replace = onReplaceRoot;
    if (replace == null) return false;
    showing = surface;
    reportRestoreSurface(surface.name);
    replace(page);
    return true;
  }

  /// Chrome Refresh / bfcache leave fires pagehide. The live snapshot stays
  /// so a crash or reload can reopen the same trip.
  void onPageHide() {
    unawaited(() async {
      try {
        await RideSnapshotStore.touchCurrent();
      } catch (_) {}
    }());
  }

  RestoredSurface surfaceFor(RideSnapshot? snapshot) {
    if (snapshot == null || snapshot.status.isTerminal || !snapshot.isFresh) {
      return RestoredSurface.home;
    }
    switch (snapshot.status) {
      case RideStatus.findingDriver:
      case RideStatus.searchDelayed:
      case RideStatus.bookingRequested:
        return RestoredSurface.finding;
      case RideStatus.driverAssigned:
      case RideStatus.driverArriving:
      case RideStatus.driverWaiting:
      case RideStatus.tripStarted:
      case RideStatus.tripInProgress:
      case RideStatus.approachingDropoff:
        return RestoredSurface.waiting;
      default:
        if (snapshot.status.isCompletedSurface) {
          return RestoredSurface.complete;
        }
        return RestoredSurface.home;
    }
  }

  Widget pageFor(RideSnapshot? snapshot) {
    final surface = surfaceFor(snapshot);
    showing = surface;
    restores += 1;
    reportRestoreSurface(surface.name);
    if (snapshot == null || surface == RestoredSurface.home) {
      return const Home();
    }
    // Rebuilding the screen is not enough: the ride's identity lives in
    // AppScope, and a cold restore starts with it empty. Without this the
    // restored search has no rideId, so Cancel reaches no ride to cancel and
    // raising the offer refuses because it cannot name the ride it belongs to.
    AppScope.instance.ride.backendReconcile(
      snapshot.status,
      id: snapshot.rideId,
    );
    final pickup = LatLng(snapshot.pickupLat, snapshot.pickupLng);
    final drop = LatLng(snapshot.destinationLat, snapshot.destinationLng);
    switch (surface) {
      case RestoredSurface.finding:
        return FindingDrivers(
          pickupAddress: snapshot.pickupAddress,
          destinationAddress: snapshot.destinationAddress,
          pickupPosition: pickup,
          destinationPosition: drop,
          rideType: snapshot.rideType,
          price: snapshot.price,
          paymentMethod: snapshot.paymentMethod,
          notes: snapshot.notes,
        );
      case RestoredSurface.waiting:
        return WaitingForDriver(
          pickupAddress: snapshot.pickupAddress,
          destinationAddress: snapshot.destinationAddress,
          pickupPosition: pickup,
          destinationPosition: drop,
          rideType: snapshot.rideType,
          price: snapshot.price,
          paymentMethod: snapshot.paymentMethod,
          notes: snapshot.notes,
          driver: snapshot.driver,
        );
      case RestoredSurface.complete:
        // Cold restore rebuilds this in-memory completion context from the
        // still-owned snapshot so driver/vehicle/route/booked-price cards are
        // truthful after reload or process death.
        LastCompletedRide.remember(snapshot);
        return RideCompleted(
          status: snapshot.status,
          rideId: snapshot.rideId,
        );
      case RestoredSurface.home:
        return const Home();
    }
  }

  Future<Widget> root() async {
    reportRestoreSurface('hold');
    if (_skipRestore()) {
      try {
        _noteDropped(surfaceFor(await _reader()));
      } catch (_) {}
      showing = RestoredSurface.home;
      reportRestoreSurface(RestoredSurface.home.name);
      unawaited(RideSnapshotStore.clear());
      return const Home();
    }
    try {
      final snapshot = await _reader();
      AppLog.info(
        'ride.restore.cold',
        extra: {'status': snapshot?.status.name ?? 'none'},
      );
      return pageFor(snapshot);
    } catch (error) {
      AppLog.error('ride.restore.corrupt', extra: {'reason': error.toString()});
      showing = RestoredSurface.home;
      reportRestoreSurface(RestoredSurface.home.name);
      return const Home();
    }
  }

  bool get atRoot {
    final override = debugAtRoot;
    if (override != null) return override();
    try {
      final nav = moveraNavigatorKey.currentState;
      if (nav == null) return true;
      return !nav.canPop();
    } catch (_) {
      return true;
    }
  }

  /// Immediately gives a newly created on-demand ride a visible owner when
  /// the Select Ride surface disappears before it can push Finding.
  ///
  /// This is a post-create recovery path, not normal resume. The backend ride
  /// already exists, so silently waiting for a later app lifecycle event would
  /// leave a live orphan ride.
  Future<bool> recoverCreatedFinding(
    String rideId, {
    RideRealtime? realtime,
  }) async {
    final expectedId = rideId.trim();
    if (expectedId.isEmpty) return false;

    final snapshot = await _reader();
    if (snapshot == null ||
        snapshot.rideId?.trim() != expectedId ||
        snapshot.status.isTerminal ||
        !snapshot.isFresh) {
      return false;
    }

    AppScope.instance.ride.backendReconcile(
      snapshot.status,
      id: expectedId,
    );

    final finding = FindingDrivers(
      pickupAddress: snapshot.pickupAddress,
      destinationAddress: snapshot.destinationAddress,
      pickupPosition: LatLng(snapshot.pickupLat, snapshot.pickupLng),
      destinationPosition: LatLng(
        snapshot.destinationLat,
        snapshot.destinationLng,
      ),
      rideType: snapshot.rideType,
      price: snapshot.price,
      paymentMethod: snapshot.paymentMethod,
      notes: snapshot.notes,
      realtime: realtime,
    );

    final nav = moveraNavigatorKey.currentState;
    final replace = onReplaceRoot;
    if (replace != null) {
      // Default app topology: remove Home's platform map for one full frame
      // before the recovered Finding map mounts.
      showing = RestoredSurface.finding;
      reportRestoreSurface('recoveringFinding');
      replace(const _RideRecoveryBarrier());
      if (nav != null && nav.canPop()) {
        nav.popUntil((route) => route.isFirst);
      }
      await WidgetsBinding.instance.endOfFrame;
      replace(finding);
      reportRestoreSurface(RestoredSurface.finding.name);
      return true;
    }

    // Isolated hosts/tests may not mount RideRestoreGate. The navigator is
    // still a valid immediate recovery owner in that topology.
    if (nav == null) return false;
    showing = RestoredSurface.finding;
    reportRestoreSurface(RestoredSurface.finding.name);
    unawaited(
      nav.push<void>(
        RideStageTransition(
          finding,
          settings: const RouteSettings(name: AppRoutes.findingDriver),
        ),
      ),
    );
    return true;
  }

  Future<Widget?> resumeIfNeeded() async {
    if (_skipRestore()) {
      unawaited(RideSnapshotStore.clear());
      if (showing == RestoredSurface.finding ||
          showing == RestoredSurface.waiting) {
        _noteDropped(showing);
        goHome();
      } else {
        showing = RestoredSurface.home;
      }
      return null;
    }
    var snapshot = await _reader();
    final id = snapshot?.rideId;
    if (id != null) {
      try {
        await AppScope.instance.rideRealtime.reconnectAndResync(id);
      } catch (_) {}
      try {
        snapshot = await _reader();
      } catch (_) {}
    }
    if (!atRoot) return null;
    if (AppScope.instance.ride.suppressRestore) {
      unawaited(RideSnapshotStore.clear());
      return null;
    }
    final next = surfaceFor(snapshot);
    if (next == showing) return null;
    final page = pageFor(snapshot);
    onReplaceRoot?.call(page);
    return page;
  }
}

typedef RideSnapshotStoreReader = Future<RideSnapshot?> Function();


class _RideRecoveryBarrier extends StatelessWidget {
  const _RideRecoveryBarrier();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFF6F5F1),
      child: Center(
        child: Semantics(
          label: 'Restoring active ride',
          child: const CircularProgressIndicator(),
        ),
      ),
    );
  }
}
