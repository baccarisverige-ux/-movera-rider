import 'package:movera_rider/features/active_ride/application/active_ride_controller.dart';
import 'package:movera_rider/features/ride_booking/data/driver_repository.dart';
import 'package:movera_rider/features/ride_complete/data/ride_complete_repository.dart';

class RideCompleteController {
  RideCompleteController({
    ActiveRideController? ride,
    DriverRepository? drivers,
    TripReceiptRepository? trips,
    TipCatalog? tips,
  })  : _ride = ride ?? ActiveRideController(),
        _drivers = drivers ?? DriverRepository(),
        _trips = trips ?? TripReceiptRepository(),
        _tips = tips ?? TipCatalog();

  final ActiveRideController _ride;
  final DriverRepository _drivers;
  final TripReceiptRepository _trips;
  final TipCatalog _tips;

  void close() => _ride.markClosed();
  DriverProfile driver() => _drivers.current();
  TripReceipt receipt() => _trips.last();
  List<String> tips() => _tips.amounts();
}
