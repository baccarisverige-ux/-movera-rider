import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:movera_rider/core/maps/geo_point.dart';
import 'package:movera_rider/core/maps/route_polyline.dart';
import 'package:movera_rider/core/maps/routing_service.dart';

/// Stands in for a real Directions provider: returns road geometry, not the
/// direct line between the two ends.
class _RoadRouting implements RoutingService {
  @override
  List<GeoPoint> line({required GeoPoint from, required GeoPoint to}) => [
    from,
    const GeoPoint(59.335, 18.062),
    const GeoPoint(59.332, 18.071),
    to,
  ];
}

void main() {
  const pickup = LatLng(59.3293, 18.0686);
  const destination = LatLng(59.3301, 18.058);

  test('today the drawn route is the direct line the seam returns', () {
    final route = routePolyline(
      id: 'route',
      from: pickup,
      to: destination,
      color: Colors.black,
      routing: RoutingService(),
    );
    expect(route.polylineId, const PolylineId('route'));
    expect(route.points, [pickup, destination]);
  });

  test('a real routing provider reaches the drawn line without touching the '
      'screens', () {
    final route = routePolyline(
      id: 'route',
      from: pickup,
      to: destination,
      color: Colors.black,
      routing: _RoadRouting(),
    );
    expect(route.points, hasLength(4));
    expect(route.points.first, pickup);
    expect(route.points[1], const LatLng(59.335, 18.062));
    expect(route.points.last, destination);
  });

  test('colour and width stay the screen\'s choice', () {
    final route = routePolyline(
      id: 'select',
      from: pickup,
      to: destination,
      color: const Color(0xFF1D252C),
      width: 6,
      routing: RoutingService(),
    );
    expect(route.color, const Color(0xFF1D252C));
    expect(route.width, 6);
  });
}
