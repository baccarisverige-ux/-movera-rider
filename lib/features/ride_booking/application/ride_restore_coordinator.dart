import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:movera_rider/core/logging/app_log.dart';
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

  static final instance = RideRestoreCoordinator();

  RestoredSurface surfaceFor(RideSnapshot? snapshot) {
    if (snapshot == null || snapshot.status.isTerminal || !snapshot.isFresh) {
      return RestoredSurface.home;
    }
    switch (snapshot.status) {
      case RideStatus.findingDriver:
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
    try {
      final snapshot = await _reader();
      AppLog.info(
        'ride.restore',
        extra: {'status': snapshot?.status.name ?? 'none'},
      );
      return pageFor(snapshot);
    } catch (error) {
      AppLog.error('ride.restore.corrupt', extra: {'reason': error.toString()});
      showing = RestoredSurface.home;
      return const Home();
    }
  }

  Future<Widget?> resumeIfNeeded() async {
    final snapshot = await _reader();
    final next = surfaceFor(snapshot);
    if (next == showing) return null;
    if (next == RestoredSurface.home) return null;
    return pageFor(snapshot);
  }
}

typedef RideSnapshotStoreReader = Future<RideSnapshot?> Function();
