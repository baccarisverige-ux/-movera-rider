import 'package:movera_rider/core/maps/geo_point.dart';
import 'package:movera_rider/core/motion/bearing.dart';

class InterpolatedPose {
  const InterpolatedPose({
    required this.point,
    required this.heading,
    required this.progress,
  });

  final GeoPoint point;
  final double heading;
  final double progress;
}

/// Time-based interpolation between GPS samples (Hz-independent).
class PositionInterpolator {
  InterpolatedPose lerp({
    required GeoPoint from,
    required GeoPoint to,
    required double fromHeading,
    required double toHeading,
    required DateTime startedAt,
    required DateTime now,
    required Duration window,
  }) {
    final elapsed = now.difference(startedAt).inMilliseconds;
    final total = window.inMilliseconds <= 0 ? 1 : window.inMilliseconds;
    final t = (elapsed / total).clamp(0.0, 1.0);
    return InterpolatedPose(
      point: GeoPoint(
        from.latitude + (to.latitude - from.latitude) * t,
        from.longitude + (to.longitude - from.longitude) * t,
      ),
      heading: lerpHeading(fromHeading, toHeading, t),
      progress: t,
    );
  }
}
