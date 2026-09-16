import 'dart:async';

import 'package:movera_rider/app/di.dart';
import 'package:movera_rider/core/api/idempotency.dart';
import 'package:movera_rider/core/logging/app_log.dart';
import 'package:movera_rider/features/finding_driver/application/finding_driver_controller.dart';
import 'package:movera_rider/features/history/data/on_demand_ride_history_store.dart';
import 'package:movera_rider/features/ride_booking/data/ride_snapshot_store.dart';
import 'package:movera_rider/features/ride_booking/domain/ride_status.dart';

/// Commit cancel immediately (matching + snapshot), before any why-sheet.
Future<void> commitCancelFirst({String? reasonId}) async {
  try {
    final active = FindingDriverController.active;
    if (active != null) {
      await active.cancelSearch(reasonId: reasonId);
      return;
    }
    final ride = AppScope.instance.ride;
    final id = ride.rideId;
    ride.restoreFromBackend(RideStatus.cancelledByRider);
    AppScope.instance.rideRealtime.cancelRide();
    if (id != null) {
      unawaited(_cancelViaAdapter(id, reasonId));
    }
    await OnDemandRideHistoryStore.archiveCancelledThenClear(
      reasonId: reasonId,
    );
  } catch (_) {
    try {
      await RideSnapshotStore.clear();
    } catch (_) {}
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
