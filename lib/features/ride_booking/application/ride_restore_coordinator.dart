import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:movera_rider/app/di.dart';
import 'package:movera_rider/app/navigator_key.dart';
import 'package:movera_rider/core/debug/movera_qa.dart';
import 'package:movera_rider/core/logging/app_log.dart';
import 'package:movera_rider/core/web/web_search_interrupted.dart';
import 'package:movera_rider/core/debug/web_qa_hooks.dart';
import 'package:movera_rider/features/active_ride/presentation/waiting_for_driver.dart';
import 'package:movera_rider/features/finding_driver/presentation/finding_drivers.dart';
import 'package:movera_rider/features/home/presentation/home.dart';
import 'package:movera_rider/features/ride_booking/data/ride_snapshot_store.dart';
import 'package:movera_rider/features/ride_booking/domain/ride_status.dart';
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

  /// Public GitHub Pages has no QA hooks. A leftover mock snapshot must not
  /// open Driver found / Finding when someone taps the live link.
  static bool defaultSkipRestore() => kIsWeb && !moveraQaHooksEnabled;

  void goHome() {
    // Deliberately back to Home: nothing to explain on the next load.
    clearSearchLive();
    showing = RestoredSurface.home;
    reportRestoreSurface(RestoredSurface.home.name);
    unawaited(() async {
      try {
        await RideSnapshotStore.clear();
      } catch (_) {}
    }());
    onReplaceRoot?.call(const Home());
  }

  /// Chrome Refresh / bfcache leave fires pagehide (not visibilitychange).
  /// Always drop the snapshot; on public web also force Home if Finding/Waiting
  /// was still on screen from an incomplete reload.
  void onPageHide() {
    unawaited(() async {
      try {
        await RideSnapshotStore.clear();
      } catch (_) {}
    }());
    if (_skipRestore() &&
        (showing == RestoredSurface.finding ||
            showing == RestoredSurface.waiting)) {
      goHome();
    }
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
        return const RideCompleted();
      case RestoredSurface.home:
        return const Home();
    }
  }

  Future<Widget> root() async {
    reportRestoreSurface('hold');
    if (_skipRestore()) {
      // Read the snapshot before dropping it: on builds that keep it, this is
      // the evidence a search was in flight. (On web the snapshot is already
      // gone by now, so Home reads the session note instead.)
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
