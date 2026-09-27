import 'package:movera_rider/core/location/location_point.dart';

class LocationSmoother {
  /// Fixes worse than this are "low accuracy".
  static const lowAccuracyMeters = 80.0;

  /// A good fix older than this no longer outranks a low-accuracy one.
  static const goodFixShelfLife = Duration(seconds: 10);

  LocationPoint? _last;

  LocationPoint? accept(LocationPoint sample) {
    if (!sample.point.isValid) return _last;
    final previous = _last;
    if (_isLowAccuracy(sample) &&
        previous != null &&
        !_isLowAccuracy(previous)) {
      // U2: a low-accuracy fix used to be dropped forever, freezing the puck
      // on a stale point. Keep preferring a *recent* good fix, but once it
      // has aged out, show the low-accuracy one (with its accuracy circle)
      // rather than pretending nothing changed.
      final age = sample.timestamp.difference(previous.timestamp);
      if (age < goodFixShelfLife) return previous;
    }
    if (previous != null) {
      if (!sample.timestamp.isAfter(previous.timestamp)) return previous;
      final dt =
          sample.timestamp.difference(previous.timestamp).inMilliseconds / 1000;
      if (dt > 0 && sample.speedMps != null && sample.speedMps! > 55) {
        return previous;
      }
    }
    _last = sample;
    return sample;
  }

  static bool _isLowAccuracy(LocationPoint point) =>
      point.accuracyMeters != null && point.accuracyMeters! > lowAccuracyMeters;
}
