import 'dart:async';

import 'package:movera_rider/app/di.dart';
import 'package:movera_rider/core/api/idempotency.dart';
import 'package:movera_rider/core/logging/app_log.dart';
import 'package:movera_rider/features/active_ride/data/active_ride_repository.dart';
import 'package:movera_rider/features/ride_booking/data/ride_snapshot_store.dart';
import 'package:movera_rider/features/ride_booking/domain/ride_status.dart';

class ActiveRideController {
  ActiveRideController({ActiveRideRepository? store})
    : _store = store ?? ActiveRideRepository();
  final ActiveRideRepository _store;

  void markArriving() {
    AppScope.instance.ride.restoreFromBackend(RideStatus.driverArriving);
  }

  Future<void> markCancelled({String? reasonId}) async {
    final ride = AppScope.instance.ride;
    final id = ride.rideId;
    ride.restoreFromBackend(RideStatus.cancelledByRider);
    AppScope.instance.rideRealtime.cancelRide();
    await _store.clear();
    if (id != null) {
      unawaited(_cancelViaAdapter(id, reasonId));
    }
  }

  Future<void> _cancelViaAdapter(String id, String? reasonId) async {
    try {
      await AppScope.instance.api.post(
        '/api/v1/rides/$id/cancel',
        body: {if (reasonId != null) 'reason': reasonId},
        idempotencyKey: newIdempotencyKey('ride-cancel'),
      );
    } catch (error) {
      AppLog.warning(
        'ride.cancel.adapter_failed',
        extra: {'rideId': id, 'error': error.toString()},
      );
    }
  }

  void markCompleted(RideStatus status) {
    AppScope.instance.ride.restoreFromBackend(status);
    unawaited(() async {
      final snap = await _store.restore();
      if (snap == null) return;
      await RideSnapshotStore.save(
        snap.copyWith(status: status, savedAt: DateTime.now()),
      );
    }());
  }

  void markClosed() {
    AppScope.instance.ride.restoreFromBackend(RideStatus.closed);
    unawaited(_store.clear());
  }
}
