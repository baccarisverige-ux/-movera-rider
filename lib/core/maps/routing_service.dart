import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:movera_rider/core/maps/geo_point.dart';

/// The one place a drawn route comes from. Screens must not invent routes.
///
/// [line] remains a synchronous fallback for first paint. [roadLine] resolves
/// real road geometry and falls back to [line] if the routing provider is
/// unavailable, so map rendering never blocks the ride flow.
class RoutingService {
  RoutingService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  final Map<String, List<GeoPoint>> _roadCache = <String, List<GeoPoint>>{};

  List<GeoPoint> line({required GeoPoint from, required GeoPoint to}) => [
    from,
    to,
  ];

  Future<List<GeoPoint>> roadLine({
    required GeoPoint from,
    required GeoPoint to,
  }) async {
    final key = _cacheKey(from, to);
    final cached = _roadCache[key];
    if (cached != null && cached.length >= 2) return cached;

    try {
      final uri = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '${from.longitude},${from.latitude};'
        '${to.longitude},${to.latitude}'
        '?overview=full&geometries=geojson',
      );
      final response = await _client
          .get(uri, headers: const {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 5));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return line(from: from, to: to);
      }

      final body = jsonDecode(response.body);
      if (body is! Map<String, dynamic>) {
        return line(from: from, to: to);
      }
      final routes = body['routes'];
      if (routes is! List || routes.isEmpty || routes.first is! Map) {
        return line(from: from, to: to);
      }
      final geometry = (routes.first as Map)['geometry'];
      if (geometry is! Map) return line(from: from, to: to);
      final coordinates = geometry['coordinates'];
      if (coordinates is! List || coordinates.length < 2) {
        return line(from: from, to: to);
      }

      final points = <GeoPoint>[];
      for (final coordinate in coordinates) {
        if (coordinate is! List || coordinate.length < 2) continue;
        final lng = coordinate[0];
        final lat = coordinate[1];
        if (lat is num && lng is num) {
          points.add(GeoPoint(lat.toDouble(), lng.toDouble()));
        }
      }
      if (points.length < 2) return line(from: from, to: to);
      _roadCache[key] = points;
      return points;
    } catch (_) {
      return line(from: from, to: to);
    }
  }

  String _cacheKey(GeoPoint from, GeoPoint to) {
    String p(GeoPoint point) =>
        '${point.latitude.toStringAsFixed(5)},${point.longitude.toStringAsFixed(5)}';
    return '${p(from)}>${p(to)}';
  }

  void dispose() => _client.close();
}
