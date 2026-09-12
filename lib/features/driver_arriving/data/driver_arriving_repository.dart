import 'package:movera_rider/features/ride_booking/data/driver_repository.dart';

class DriverArrivingRepository {
  DriverProfile driver() => DriverRepository().current();
}
