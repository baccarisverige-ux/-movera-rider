import 'package:movera_rider/core/logging/app_log.dart';
import 'package:movera_rider/core/utils/stale_guard.dart';
import 'package:movera_rider/features/ride_booking/data/ride_snapshot_store.dart';
import 'package:movera_rider/features/ride_booking/domain/entities/quote.dart';
import 'package:movera_rider/features/ride_booking/domain/ride_status.dart';
import 'package:movera_rider/features/ride_booking/domain/ride_transition.dart';
import 'package:movera_rider/features/payments/domain/payment_status.dart';
import 'package:movera_rider/features/ratings/domain/rating_status.dart';
import 'package:movera_rider/features/trips/domain/ride_status_adapter.dart';
import 'package:movera_rider/features/trips/domain/trip_status.dart';

class RideSession {
  RideSession({this.rideId});

  String? rideId;
  RideStatus status = RideStatus.idle;
  TripStatus tripStatus = TripStatus.draft;
  PaymentStatus paymentStatus = PaymentStatus.notStarted;
  RatingStatus ratingStatus = RatingStatus.notRequested;
  RideQuote? quote;
  final stale = StaleGuard();
  bool suppressRestore = false;

  /// Last authoritative backend ordering metadata accepted for this ride.
  int? authoritativeVersion;
  DateTime? authoritativeUpdatedAt;

  /// Strict client-side mutation path. Local/UI actions must obey the graph.
  RideStatus localTransition(RideStatus next) {
    status = transitionRide(status, next);
    _syncContractProjection();
    suppressRestore = status.isTerminal;
    AppLog.info(
      'ride.transition',
      extra: {'to': status.name, 'rideId': rideId},
    );
    return status;
  }

  /// Backwards-compatible alias for existing local callers.
  RideStatus apply(RideStatus next) => localTransition(next);

  /// Authoritative backend reconciliation path.
  ///
  /// Backend projections may legitimately jump over client-only intermediate
  /// states, but they must never move this session backwards in backend
  /// ordering. A new ride id starts a fresh ordering domain.
  bool backendReconcile(
    RideStatus backendStatus, {
    String? id,
    int? version,
    DateTime? updatedAt,
  }) {
    final incomingRideId = id?.trim();
    final currentRideId = rideId?.trim();
    final isNewRide =
        incomingRideId != null &&
        incomingRideId.isNotEmpty &&
        currentRideId != null &&
        currentRideId.isNotEmpty &&
        incomingRideId != currentRideId;

    // A realtime/resync projection for another ride must never take ownership
    // of an active session. A completed/terminal session may legitimately be
    // replaced by the next ride.
    if (isNewRide && status != RideStatus.idle && !status.isTerminal) {
      AppLog.warning(
        'ride.restore.wrong_ride',
        extra: {
          'currentRideId': currentRideId,
          'incomingRideId': incomingRideId,
          'status': backendStatus.name,
        },
      );
      return false;
    }

    if (isNewRide) {
      authoritativeVersion = null;
      authoritativeUpdatedAt = null;
    } else if (!_isFreshBackendProjection(
      backendStatus,
      version: version,
      updatedAt: updatedAt,
    )) {
      AppLog.info(
        'ride.restore.stale',
        extra: {
          'status': backendStatus.name,
          'rideId': id ?? rideId,
          'version': version,
          'updatedAt': updatedAt?.toIso8601String(),
        },
      );
      return false;
    }

    // Deliberately do not apply the local transition graph here. Backend
    // projections are authoritative and may skip client-only intermediate
    // states (for example driverArriving -> paymentFinalized after reconnect).
    // Ordering and ride identity are the safety boundaries for this path.

    rideId = id ?? rideId;
    status = backendStatus;
    _syncContractProjection();
    suppressRestore = backendStatus.isTerminal;
    if (version != null) authoritativeVersion = version;
    if (updatedAt != null) authoritativeUpdatedAt = updatedAt;
    return true;
  }

  /// Backwards-compatible adapter for restore/realtime callers that do not yet
  /// carry backend ordering metadata.
  void restoreFromBackend(RideStatus backendStatus, {String? id}) {
    backendReconcile(backendStatus, id: id);
  }

  bool _isFreshBackendProjection(
    RideStatus incomingStatus, {
    int? version,
    DateTime? updatedAt,
  }) {
    final currentVersion = authoritativeVersion;
    final currentUpdatedAt = authoritativeUpdatedAt;

    if (version != null && currentVersion != null) {
      if (version < currentVersion) return false;
      if (version > currentVersion) return true;

      // Same backend version is either a duplicate or a conflicting replay.
      if (incomingStatus == status) return false;
      if (updatedAt == null || currentUpdatedAt == null) return false;
      return updatedAt.isAfter(currentUpdatedAt);
    }

    if (updatedAt != null && currentUpdatedAt != null) {
      if (updatedAt.isBefore(currentUpdatedAt)) return false;
      if (updatedAt.isAtSameMomentAs(currentUpdatedAt) &&
          incomingStatus == status) {
        return false;
      }
    }

    return true;
  }

  void _syncContractProjection() {
    tripStatus = status.tripStatus;
    paymentStatus = status.paymentStatus;
    ratingStatus = status.ratingStatus;
  }

  Future<RideSnapshot?> loadSnapshot() => RideSnapshotStore.read();

  void dispose() => stale.dispose();
}
