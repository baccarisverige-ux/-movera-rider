import 'package:movera_rider/features/ride_booking/domain/entities/matched_driver.dart';

/// Drivers the mock matching service hands back when a ride is assigned.
///
/// This lives behind the API boundary on purpose. The rule this codebase works
/// to is that no screen, controller or repository may invent a record — but a
/// mock *backend* returning a matched driver is a simulated response, and it is
/// the exact thing the real matching service will replace. Without it the whole
/// ride shows "Driver details unavailable" from pickup to receipt.
abstract final class MockDriverPool {
  static const _drivers = <MatchedDriver>[
    MatchedDriver(
      id: 'drv_mock_001',
      firstName: 'Elin',
      rating: 4.9,
      tripCount: 2140,
      vehicleMake: 'Volvo',
      vehicleModel: 'XC40 Recharge',
      vehicleColor: 'Black',
      plate: 'MVR 204',
      photoAsset: 'assets/images/driver_img.webp',
      vehicleImageAsset: 'assets/images/rides/movera.webp',
      languages: ['Swedish', 'English'],
      yearsOnMovera: 3,
    ),
    MatchedDriver(
      id: 'drv_mock_002',
      firstName: 'Johan',
      rating: 4.8,
      tripCount: 1685,
      vehicleMake: 'Volvo',
      vehicleModel: 'V60',
      vehicleColor: 'Grey',
      plate: 'MVR 771',
      photoAsset: 'assets/images/driver_img.webp',
      vehicleImageAsset: 'assets/images/rides/comfort.webp',
      languages: ['Swedish'],
      yearsOnMovera: 2,
    ),
    MatchedDriver(
      id: 'drv_mock_003',
      firstName: 'Amina',
      rating: 5.0,
      tripCount: 934,
      vehicleMake: 'Tesla',
      vehicleModel: 'Model Y',
      vehicleColor: 'White',
      plate: 'MVR 316',
      photoAsset: 'assets/images/driver_img.webp',
      vehicleImageAsset: 'assets/images/rides/electric.webp',
      languages: ['Swedish', 'English', 'Arabic'],
      yearsOnMovera: 1,
    ),
  ];

  /// Keyed off the ride so one ride keeps one driver across reconnects and
  /// restores — a rider must never see their driver silently change.
  ///
  /// [attempt] advances when a driver drops the ride and dispatch looks again,
  /// so the rider is offered someone new rather than the driver who just
  /// cancelled on them.
  static MatchedDriver forRide(String rideId, {int attempt = 0}) {
    if (rideId.isEmpty) return _drivers[attempt % _drivers.length];
    var hash = 0;
    for (final unit in rideId.codeUnits) {
      hash = (hash * 31 + unit) & 0x7fffffff;
    }
    return _drivers[(hash + attempt) % _drivers.length];
  }
}
