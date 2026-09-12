import 'package:movera_rider/core/location/location_point.dart';
import 'package:movera_rider/core/maps/geo_point.dart';
import 'package:movera_rider/core/motion/direction_cone.dart';
import 'package:movera_rider/core/motion/interpolator.dart';
import 'package:movera_rider/core/motion/location_smoother.dart';

class MotionOutput {
  const MotionOutput({
    required this.position,
    required this.heading,
    required this.cone,
    this.velocityMps,
    this.progress = 1,
  });

  final GeoPoint position;
  final double heading;
  final DirectionConeState cone;
  final double? velocityMps;
  final double progress;
}

/// Isolated from widgets and Google Maps.
class MotionEngine {
  MotionEngine({
    LocationSmoother? smoother,
    PositionInterpolator? interpolator,
  })  : _smoother = smoother ?? LocationSmoother(),
        _interpolator = interpolator ?? PositionInterpolator();

  final LocationSmoother _smoother;
  final PositionInterpolator _interpolator;
  LocationPoint? _from;
  LocationPoint? _to;

  MotionOutput? ingest(LocationPoint raw, {DateTime? now}) {
    final sample = _smoother.accept(raw);
    if (sample == null) return null;
    _from = _to ?? sample;
    _to = sample;
    final clock = now ?? DateTime.now();
    final pose = _interpolator.lerp(
      from: _from!.point,
      to: _to!.point,
      fromHeading: _from!.heading ?? 0,
      toHeading: _to!.heading ?? _from!.heading ?? 0,
      startedAt: _from!.timestamp,
      now: clock,
      window: const Duration(milliseconds: 420),
    );
    return MotionOutput(
      position: pose.point,
      heading: pose.heading,
      cone: DirectionConeState(
        heading: pose.heading,
        accuracy: sample.accuracyMeters,
      ),
      velocityMps: sample.speedMps,
      progress: pose.progress,
    );
  }
}
