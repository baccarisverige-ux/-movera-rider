import 'dart:async';

import 'package:movera_rider/app/di.dart';
import 'package:movera_rider/core/api/mutation_attempt.dart';
import 'package:movera_rider/core/logging/app_log.dart';
import 'package:movera_rider/features/active_ride/data/active_ride_repository.dart';
import 'package:movera_rider/features/history/data/on_demand_ride_history_store.dart';
import 'package:movera_rider/features/ride_complete/data/last_completed_ride.dart';
import 'package:movera_rider/features/ride_booking/data/ride_snapshot_store.dart';
import 'package:movera_rider/features/ride_booking/domain/ride_status.dart';

class ActiveRideController {
  ActiveRideController({ActiveRideRepository? store})
    : _store = store ?? ActiveRideRepository();
  final ActiveRideRepository _store;
  final MutationAttempt _cancelMutation = MutationAttempt('ride-cancel');

  void markArriving() {
    AppScope.instance.ride.localTransition(RideStatus.driverArriving);
  }

  Future<void> markCancelled({String? reasonId}) async {
    final snapshot = await _store.historyCandidate();
    final ride = AppScope.instance.ride;
    final id = ride.rideId;
    if (ride.status != RideStatus.cancelledByRider && !ride.status.isTerminal) {
      ride.localTransition(RideStatus.cancelledByRider);
    }
    AppScope.instance.rideRealtime.cancelRide();
    await _archive(
      snapshot,
      RideStatus.cancelledByRider,
      expectedRideId: id,
      cancellationReason: reasonId,
    );
    await _store.clear();
    if (id != null) {
      unawaited(_cancelViaAdapter(id, reasonId));
    }
  }

  Future<void> markExternalTerminal(RideStatus status) async {
    if (!status.isTerminal ||
        status.isCompletedSurface ||
        status == RideStatus.cancelledByRider ||
        status == RideStatus.closed) {
      throw ArgumentError.value(
        status,
        'status',
        'Expected a non-rider external terminal status.',
      );
    }
    final snapshot = await _store.historyCandidate();
    final ride = AppScope.instance.ride;
    final id = ride.rideId;
    ride.backendReconcile(status, id: id);
    if (status == RideStatus.cancelledByDriver ||
        status == RideStatus.cancelledBySystem) {
      await _archive(snapshot, status, expectedRideId: id);
    }
    await _store.clear();
  }

  Future<void> _cancelViaAdapter(String id, String? reasonId) async {
    final intent = '$id|${reasonId ?? ''}';
    try {
      await AppScope.instance.api.post(
        '/api/v1/rides/$id/cancel',
        body: {if (reasonId != null) 'reason': reasonId},
        idempotencyKey: _cancelMutation.keyFor(intent),
      );
      _cancelMutation.succeeded(intent);
    } catch (error) {
      AppLog.warning(
        'ride.cancel.adapter_failed',
        extra: {'rideId': id, 'error': error.toString()},
      );
    }
  }

  Future<void> markCompleted(RideStatus status) async {
    if (!status.isCompletedSurface) {
      throw ArgumentError.value(status, 'status', 'Expected a completed status.');
    }
    final snapshot = await _store.historyCandidate();
    final id = AppScope.instance.ride.rideId;
    AppScope.instance.ride.backendReconcile(status, id: id);
    if (snapshot == null) return;

    // Keep a restorable completion snapshot until the rider explicitly leaves
    // the completion surface. This protects payment/rating state across reload,
    // crash, PWA eviction and app resume.
    final completed = snapshot.copyWith(
      status: status,
      savedAt: DateTime.now(),
    );
    LastCompletedRide.remember(completed);
    await _archive(completed, status, expectedRideId: id);
    await _store.save(completed);
  }

  Future<void> persistCompletedStatus(
    RideStatus status, {
    required String rideId,
  }) async {
    if (!status.isCompletedSurface) {
      throw ArgumentError.value(status, 'status', 'Expected a completed status.');
    }
    final snapshot = await _store.historyCandidate();
    if (snapshot == null || snapshot.rideId?.trim() != rideId.trim()) return;
    final updated = snapshot.copyWith(
      status: status,
      savedAt: DateTime.now(),
    );
    LastCompletedRide.remember(updated);
    await _store.save(updated);
  }

  Future<void> _archive(
    RideSnapshot? snapshot,
    RideStatus status, {
    String? expectedRideId,
    String? cancellationReason,
  }) async {
    if (snapshot == null) return;
    final snapshotId = snapshot.rideId?.trim();
    if (expectedRideId != null &&
        expectedRideId.trim().isNotEmpty &&
        snapshotId != expectedRideId.trim()) {
      AppLog.warning(
        'ride.history.snapshot_mismatch',
        extra: {'rideId': expectedRideId, 'snapshotRideId': snapshotId},
      );
      return;
    }
    try {
      await OnDemandRideHistoryStore.archive(
        snapshot,
        terminalStatus: status,
        cancellationReason: cancellationReason,
      );
    } catch (error) {
      AppLog.warning(
        'ride.history.archive_failed',
        extra: {
          'rideId': snapshot.rideId,
          'status': status.name,
          'error': error.toString(),
        },
      );
    }
  }

  void markClosed() {
    AppScope.instance.ride.localTransition(RideStatus.closed);
    unawaited(_store.clear());
  }
}
