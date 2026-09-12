import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:movera_rider/app/di.dart';
import 'package:movera_rider/app/navigator_key.dart';
import 'package:movera_rider/core/logging/app_log.dart';
import 'package:movera_rider/core/debug/web_qa_hooks.dart';
import 'package:movera_rider/features/active_ride/presentation/waiting_for_driver.dart';
import 'package:movera_rider/features/finding_driver/presentation/finding_drivers.dart';
import 'package:movera_rider/features/home/presentation/home.dart';
import 'package:movera_rider/features/ride_booking/data/ride_snapshot_store.dart';
import 'package:movera_rider/features/ride_booking/domain/ride_status.dart';
import 'package:movera_rider/features/ride_complete/presentation/ride_completed.dart';

enum RestoredSurface { home, finding, waiting, complete }

class RideRestoreCoordinator {
  RideRestoreCoordinator({RideSnapshotStoreReader? reader})
      : _reader = reader ?? RideSnapshotStore.read;

  final Future<RideSnapshot?> Function() _reader;
  RestoredSurface showing = RestoredSurface.home;
  int restores = 0;
  void Function(Widget page)? onReplaceRoot;

  /// Tests: pretend Profile/Wallet is open so resume must not navigate.
  bool Function()? debugAtRoot;

  static final instance = RideRestoreCoordinator();

  RestoredSurface surfaceFor(RideSnapshot? snapshot) {
    if (snapshot == null || snapshot.status.isTerminal || !snapshot.isFresh) {
      return RestoredSurface.home;
    }
    switch (snapshot.status) {
      case RideStatus.findingDriver:
      case RideStatus.bookingRequested:
        return RestoredSurface.finding;
      case RideStatus.driverAssigned:
      case RideStatus.driverArriving:
      case RideStatus.driverWaiting:
      case RideStatus.tripStarted:
      case RideStatus.tripInProgress:
        return RestoredSurface.waiting;
      case RideStatus.tripCompleted:
      case RideStatus.paymentProcessing:
      case RideStatus.paymentFinalized:
      case RideStatus.ratingPending:
        return RestoredSurface.complete;
      default:
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
        );
      case RestoredSurface.complete:
        return const RideCompleted();
      case RestoredSurface.home:
        return const Home();
    }
  }

  Future<Widget> root() async {
    reportRestoreSurface('hold');
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
    final next = surfaceFor(snapshot);
    if (next == showing) return null;
    final page = pageFor(snapshot);
    onReplaceRoot?.call(page);
    return page;
  }
}

typedef RideSnapshotStoreReader = Future<RideSnapshot?> Function();
