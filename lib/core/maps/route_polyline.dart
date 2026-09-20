import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:movera_rider/app/di.dart';
import 'package:movera_rider/core/maps/geo_point.dart';
import 'package:movera_rider/core/maps/routing_service.dart';

/// Builds the route a screen draws on its map.
///
/// Screens used to hand-build `Polyline(points: [pickup, destination])`, which
/// meant the visible line and [RoutingService] — the app's one route seam —
/// were separate sources of truth. A real Directions provider dropped into
/// [RoutingService] would have changed the stored route and left every screen
/// still drawing its own straight line. Going through here keeps one source.
Polyline routePolyline({
  required String id,
  required LatLng from,
  required LatLng to,
  required Color color,
  int width = 4,
  RoutingService? routing,
}) {
  final service = routing ?? AppScope.instance.routing;
  final points = service.line(
    from: GeoPoint(from.latitude, from.longitude),
    to: GeoPoint(to.latitude, to.longitude),
  );
  return Polyline(
    polylineId: PolylineId(id),
    points: [
      for (final point in points) LatLng(point.latitude, point.longitude),
    ],
    color: color,
    width: width,
  );
}
