import 'package:movera_rider/core/maps/geo_point.dart';

class RouteResult {
  const RouteResult({
    required this.points,
    required this.distanceMeters,
    required this.duration,
  });

  final List<GeoPoint> points;
  final double distanceMeters;
  final Duration duration;
}

abstract class RoutingService {
  Future<RouteResult?> route(GeoPoint origin, GeoPoint destination);
}
