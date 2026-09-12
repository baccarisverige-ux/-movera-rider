import 'package:movera_rider/core/maps/geo_point.dart';

class MarkerRecord {
  const MarkerRecord({
    required this.id,
    required this.point,
    this.heading = 0,
  });

  final String id;
  final GeoPoint point;
  final double heading;
}

/// Stable IDs. Update in place instead of recreating every GPS tick.
class MarkerStore {
  final Map<String, MarkerRecord> _markers = {};

  MarkerRecord upsert(String id, GeoPoint point, {double heading = 0}) {
    final record = MarkerRecord(id: id, point: point, heading: heading);
    _markers[id] = record;
    return record;
  }

  void remove(String id) => _markers.remove(id);

  MarkerRecord? operator [](String id) => _markers[id];

  Iterable<MarkerRecord> get values => _markers.values;
}
