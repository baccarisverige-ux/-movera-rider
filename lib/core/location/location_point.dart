import 'package:movera_rider/core/maps/geo_point.dart';

class LocationPoint {
  const LocationPoint({
    required this.point,
    required this.timestamp,
    this.accuracyMeters,
    this.speedMps,
    this.heading,
  });

  final GeoPoint point;
  final DateTime timestamp;
  final double? accuracyMeters;
  final double? speedMps;
  final double? heading;

  bool get isPrecise =>
      accuracyMeters != null && accuracyMeters! > 0 && accuracyMeters! <= 25;

  bool get isStale {
    return DateTime.now().difference(timestamp) > const Duration(seconds: 12);
  }
}
