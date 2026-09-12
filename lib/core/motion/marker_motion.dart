import 'package:movera_rider/core/maps/geo_point.dart';
import 'package:movera_rider/core/motion/interpolator.dart';

class MarkerMotionController {
  MarkerMotionController({PositionInterpolator? interpolator})
      : _interpolator = interpolator ?? PositionInterpolator();

  final PositionInterpolator _interpolator;

  InterpolatedPose step({
    required GeoPoint from,
    required GeoPoint to,
    required double fromHeading,
    required double toHeading,
    required DateTime startedAt,
    required DateTime now,
  }) {
    return _interpolator.lerp(
      from: from,
      to: to,
      fromHeading: fromHeading,
      toHeading: toHeading,
      startedAt: startedAt,
      now: now,
      window: const Duration(milliseconds: 420),
    );
  }
}
