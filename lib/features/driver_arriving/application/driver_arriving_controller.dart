import 'package:movera_rider/features/active_ride/application/active_ride_controller.dart';
import 'package:movera_rider/features/driver_arriving/data/driver_arriving_repository.dart';
import 'package:movera_rider/features/ride_booking/data/driver_repository.dart';

class DriverArrivingController {
  DriverArrivingController({
    DriverArrivingRepository? store,
    ActiveRideController? ride,
  })  : _store = store ?? DriverArrivingRepository(),
        _ride = ride ?? ActiveRideController();

  final DriverArrivingRepository _store;
  final ActiveRideController _ride;

  DriverProfile driver() => _store.driver();
  String eta() => _store.eta();
  void markArriving() => _ride.markArriving();
}
