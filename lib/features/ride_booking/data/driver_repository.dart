class DriverProfile {
  const DriverProfile({
    required this.name,
    required this.tagline,
    required this.vehicle,
    required this.rideNumber,
    required this.ratingLabel,
    required this.completedAt,
  });

  final String name;
  final String tagline;
  final String vehicle;
  final String rideNumber;
  final String ratingLabel;
  final String completedAt;
}

class DriverRepository {
  DriverProfile current() => const DriverProfile(
        name: 'Merle Feeney',
        tagline: 'Top rated driver',
        vehicle: 'Toyota HR-V . L-2323 F',
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
