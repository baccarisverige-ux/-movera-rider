import 'package:movera_rider/core/maps/geo_point.dart';

/// Domain polyline. Screens must not invent routes.
class RoutingService {
  List<GeoPoint> line({required GeoPoint from, required GeoPoint to}) =>
      [from, to];
}
