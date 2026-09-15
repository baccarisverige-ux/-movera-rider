class DriverProfile {
  const DriverProfile({
    required this.name,
    required this.tagline,
    required this.vehicle,
    required this.plate,
    required this.rideNumber,
    required this.ratingLabel,
    required this.completedAt,
    this.vehicleImage = 'assets/images/comfort_ride.png',
    this.photoAsset = 'assets/images/profile_img.png',
  });

  final String name;
  final String tagline;
  final String vehicle;
  final String plate;
  final String rideNumber;
  final String ratingLabel;
  final String completedAt;
  final String vehicleImage;
  final String photoAsset;
}

class DriverRepository {
  const DriverRepository({DriverProfile? current}) : _current = current;

  final DriverProfile? _current;

  DriverProfile? current() => _current;
}

class TripReceipt {
  const TripReceipt({
    required this.pickup,
    required this.destination,
    required this.total,
    required this.method,
  });

  final String pickup;
  final String destination;
  final String total;
  final String method;
}

class TripReceiptRepository {
  const TripReceiptRepository({TripReceipt? last}) : _last = last;

  final TripReceipt? _last;

  TripReceipt? last() => _last;
}
