import 'package:movera_rider/core/location/location_point.dart';

class LocationSmoother {
  LocationPoint? _last;

  LocationPoint? accept(LocationPoint sample) {
    if (!sample.point.isValid) return _last;
    if (sample.accuracyMeters != null && sample.accuracyMeters! > 80) {
      return _last;
    }
    final previous = _last;
    if (previous != null) {
      if (!sample.timestamp.isAfter(previous.timestamp)) return previous;
      final dt = sample.timestamp.difference(previous.timestamp).inMilliseconds / 1000;
      if (dt > 0 && sample.speedMps != null && sample.speedMps! > 55) {
        return previous;
      }
    }
    _last = sample;
    return sample;
  }
}
