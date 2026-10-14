import 'package:movera_rider/core/contracts/trip_status.dart';
import 'package:movera_rider/features/ride_booking/domain/ride_status.dart';

class Ride {
  const Ride({required this.id, required this.status, required this.riderId});
  final String id;
  final RideStatus status;
  final String riderId;

  factory Ride.fromDto(Map<String, dynamic> dto) {
    final status = RideStatusWire.parse(dto['status']) ?? RideStatus.idle;
    return Ride(
      id: dto['id'] as String? ?? '',
      status: status,
      riderId: dto['riderId'] as String? ?? '',
    );
  }
}
