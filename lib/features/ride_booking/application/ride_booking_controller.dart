import 'package:movera_rider/features/ride_booking/data/ride_booking_repository.dart';
import 'package:movera_rider/features/ride_booking/data/ride_snapshot_store.dart';

class RideBookingController {
  RideBookingController({RideBookingRepository? store})
      : _store = store ?? RideBookingRepository();
  final RideBookingRepository _store;

  Future<RideSnapshot?> restore() => _store.restore();
  Future<void> save(RideSnapshot snapshot) => _store.save(snapshot);
  void clear() => _store.clear();
}
