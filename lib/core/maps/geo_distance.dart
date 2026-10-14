import 'dart:math';

/// Great-circle distance and the urban drive-time estimate, shared by the
/// driver ETA (features) and the mock transport (core) so core does not
/// import a feature for plain geometry (ARCH-17).
abstract final class GeoDistance {
  static double metersBetween(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const radius = 6371000.0;
    final p1 = lat1 * pi / 180;
    final p2 = lat2 * pi / 180;
    final dLat = (lat2 - lat1) * pi / 180;
    final dLng = (lng2 - lng1) * pi / 180;
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(p1) * cos(p2) * sin(dLng / 2) * sin(dLng / 2);
    return 2 * radius * atan2(sqrt(a), sqrt(1 - a));
  }

  static int urbanSecondsForDistance(double meters) {
    const urbanMetersPerSecond = 8.3;
    return (meters / urbanMetersPerSecond).round().clamp(20, 1800);
  }
}
