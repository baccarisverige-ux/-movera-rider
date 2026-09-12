import 'dart:math' as math;

import 'package:movera_rider/core/maps/geo_point.dart';

class VelocityEstimator {
  double? estimateMps(GeoPoint from, GeoPoint to, Duration dt) {
    if (dt.inMilliseconds <= 0) return null;
    const metersPerDeg = 111320.0;
    final dy = (to.latitude - from.latitude) * metersPerDeg;
    final dx = (to.longitude - from.longitude) *
        metersPerDeg *
        math.cos(from.latitude * math.pi / 180);
    final dist = math.sqrt(dx * dx + dy * dy);
    return dist / (dt.inMilliseconds / 1000);
  }
}
