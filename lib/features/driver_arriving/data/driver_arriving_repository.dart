import 'package:movera_rider/features/driver_arriving/domain/driver_arrival_view.dart';
import 'package:movera_rider/features/ride_booking/data/driver_repository.dart';

class DriverArrivingRepository {
  DriverProfile driver() => DriverRepository().current();

  String eta() => '5 mins';

  DriverArrivalView arrival({String? rideType}) {
    final profile = driver();
    return DriverArrivalView(
      eta: eta(),
      name: profile.name,
      rating: profile.ratingLabel,
      tagline: profile.tagline,
      plate: profile.plate,
      vehicleLabel: rideType ?? profile.vehicle,
      vehicleImage: profile.vehicleImage,
      photoAsset: profile.photoAsset,
    );
  }
}
