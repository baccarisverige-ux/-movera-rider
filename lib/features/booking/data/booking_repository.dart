import 'package:movera_rider/features/booking/application/booking_coordinator.dart';

class BookingRepository {
  final BookingCoordinator _coordinator = BookingCoordinator();

  Future<String> submitFinding({
    required String pickupAddress,
    required String destinationAddress,
    required double pickupLat,
    required double pickupLng,
    required double destinationLat,
    required double destinationLng,
    required String rideType,
    required double price,
    required String paymentMethod,
  }) {
    return _coordinator.submitFinding(
      pickupAddress: pickupAddress,
      destinationAddress: destinationAddress,
      pickupLat: pickupLat,
      pickupLng: pickupLng,
      destinationLat: destinationLat,
      destinationLng: destinationLng,
      rideType: rideType,
      price: price,
      paymentMethod: paymentMethod,
    );
  }
}
