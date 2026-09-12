
import 'package:movera_rider/features/ride_booking/domain/ride_status.dart';

class Ride {
  const Ride({required this.id, required this.status, required this.riderId});
  final String id;
  final RideStatus status;
  final String riderId;

  factory Ride.fromDto(Map<String, dynamic> dto) {
    final name = dto['status'] as String? ?? 'idle';
    final status = RideStatus.values.firstWhere(
      (value) => value.name == name,
      orElse: () => RideStatus.idle,
    );
    return Ride(
      id: dto['id'] as String? ?? '',
      status: status,
      riderId: dto['riderId'] as String? ?? '',
    );
  }
}
