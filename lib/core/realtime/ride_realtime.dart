import 'package:movera_rider/features/ride_booking/domain/ride_status.dart';

class RideRealtimeEvent {
  const RideRealtimeEvent({
    required this.rideId,
    required this.status,
    required this.sequence,
    required this.at,
  });

  final String rideId;
  final RideStatus status;
  final int sequence;
  final DateTime at;
}

abstract class RideRealtime {
  Stream<RideRealtimeEvent> subscribe(String rideId);
  Future<void> reconnectAndResync(String rideId);
  void unsubscribe();
  void dispose();
}
