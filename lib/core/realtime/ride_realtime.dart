import 'package:movera_rider/features/ride_booking/domain/entities/matched_driver.dart';
import 'package:movera_rider/features/ride_booking/domain/ride_status.dart';

enum RideRealtimeSignal {
  driverArrived,
  riderOnTheWay,
}

class RideRealtimeEvent {
  RideRealtimeEvent({
    String? rideId,
    String? tripId,
    required this.status,
    required this.sequence,
    DateTime? at,
    DateTime? occurredAt,
    String? eventId,
    this.version,
    this.serverTime,
    this.payload = const <String, Object?>{},
    this.driver,
    this.latitude,
    this.longitude,
    this.etaSeconds,
    this.locationAt,
    this.signal,
    this.message,
  })  : rideId = (tripId ?? rideId)!,
        at = occurredAt ?? at ?? DateTime.now(),
        eventId =
            eventId ??
            '${tripId ?? rideId}:$sequence:${status.name}';

  /// Backwards-compatible Rider identifier. New platform code should use
  /// [tripId] so Rider, Driver and Admin speak the same contract.
  final String rideId;

  String get tripId => rideId;

  final String eventId;
  final RideStatus status;

  /// Monotonic transport ordering for this trip stream.
  final int sequence;

  /// Optional persisted backend aggregate version.
  final int? version;

  /// Backwards-compatible local occurrence time.
  final DateTime at;

  DateTime get occurredAt => at;

  /// Server clock when the event was committed, when available.
  final DateTime? serverTime;

  /// Extensible contract payload for backend-authored event metadata.
  final Map<String, Object?> payload;

  final MatchedDriver? driver;
  final double? latitude;
  final double? longitude;
  final int? etaSeconds;
  final DateTime? locationAt;
  final RideRealtimeSignal? signal;
  final String? message;

  bool isNewerThan(RideRealtimeEvent other) {
    if (tripId != other.tripId) return true;
    final thisVersion = version;
    final otherVersion = other.version;
    if (thisVersion != null && otherVersion != null) {
      return thisVersion > otherVersion;
    }
    return sequence > other.sequence;
  }
}

abstract class RideRealtime {
  /// Whether this transport has an authoritative rider -> driver signal path.
  /// Surfaces must not claim a signal was sent when the transport cannot send it.
  bool get supportsRiderSignals => true;

  Stream<RideRealtimeEvent> subscribe(String rideId);
  Future<void> reconnectAndResync(String rideId);
  Future<void> sendSignal({
    required String rideId,
    required RideRealtimeSignal signal,
    String? message,
  });
  void unsubscribe();
  void cancelRide();

  /// Search again for the same ride after its driver dropped it before pickup.
  ///
  /// The rider keeps their ride, pickup, destination and price; only the driver
  /// changes. Implementations that cannot re-dispatch may no-op.
  void researchAfterDriverCancel() {}

  void dispose();
}
