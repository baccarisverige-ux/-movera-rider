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
  DriverProfile current() => const DriverProfile(
        name: 'Merle Feeney',
        tagline: 'Top rated driver',
        vehicle: 'Toyota HR-V . L-2323 F',
        plate: 'L - 2323 F',
        rideNumber: '#IL19051950015',
        ratingLabel: '5.0',
        completedAt: '22 May, 2025 . 12:30 pm ',
      );
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
  TripReceipt last() => const TripReceipt(
        pickup: 'I11/Street 15 - h350',
        destination: 'Skypulse solution',
        total: '\$10.12',
        method: 'Cash',
      );
}
