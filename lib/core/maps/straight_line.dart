import 'dart:math' as math;

import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Straight-line (haversine) distance between two map points, in whole
/// metres, at least 1. Used where a quote needs a trip length before the
/// server sends the routed distance.
int straightLineMeters(LatLng from, LatLng to) {
  const earthRadiusMeters = 6371000.0;
  double rad(double degrees) => degrees * math.pi / 180;
  final dLat = rad(to.latitude - from.latitude);
  final dLng = rad(to.longitude - from.longitude);
  final a =
      math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(rad(from.latitude)) *
          math.cos(rad(to.latitude)) *
          math.sin(dLng / 2) *
          math.sin(dLng / 2);
  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return math.max(1, (earthRadiusMeters * c).round());
}
