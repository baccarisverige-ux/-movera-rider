import 'package:movera_rider/features/ride_booking/domain/entities/matched_driver.dart';
import 'package:movera_rider/features/ride_booking/domain/ride_status.dart';

enum RideRealtimeSignal {
  driverArrived,
  riderOnTheWay,
}

class RideRealtimeEvent {
  const RideRealtimeEvent({
    required this.rideId,
    required this.status,
    required this.sequence,
    required this.at,
    this.driver,
    this.latitude,
    this.longitude,
    this.etaSeconds,
    this.locationAt,
    this.signal,
    this.message,
  });

  final String rideId;
  final RideStatus status;
  final int sequence;
  final DateTime at;
  final MatchedDriver? driver;
  final double? latitude;
  final double? longitude;
  final int? etaSeconds;
  final DateTime? locationAt;
  final RideRealtimeSignal? signal;
  final String? message;
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
