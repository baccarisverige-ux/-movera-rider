import 'package:movera_rider/features/ride_booking/domain/entities/matched_driver.dart';
import 'package:movera_rider/features/ride_booking/domain/ride_status.dart';

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
}

abstract class RideRealtime {
  Stream<RideRealtimeEvent> subscribe(String rideId);
  Future<void> reconnectAndResync(String rideId);
  void unsubscribe();
  void dispose();
}
