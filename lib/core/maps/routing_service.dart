import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:movera_rider/core/maps/geo_point.dart';

/// The one place a drawn route comes from. Screens must not invent routes.
///
/// [line] stays deliberately synchronous for first paint and for lightweight
/// fakes used throughout the certified Rider test suite.
class RoutingService {
  List<GeoPoint> line({required GeoPoint from, required GeoPoint to}) => [
    from,
    to,
  ];
}

final Expando<http.Client> _roadClients = Expando<http.Client>(
  'movera-road-client',
);
final Expando<Map<String, List<GeoPoint>>> _roadCaches =
    Expando<Map<String, List<GeoPoint>>>('movera-road-cache');

/// Adds real road geometry without widening [RoutingService]'s interface.
///
/// Keeping this as an extension means existing test doubles that implement only
/// [RoutingService.line] remain valid. Runtime screens can call [roadLine] and
/// receive a road-following route, with the direct line retained as a safe
/// fallback when the provider is unavailable.
extension RoadRoutingService on RoutingService {
  Future<List<GeoPoint>> roadLine({
    required GeoPoint from,
    required GeoPoint to,
  }) async {
    final cache = _roadCaches[this] ??= <String, List<GeoPoint>>{};
    final key = _roadCacheKey(from, to);
    final cached = cache[key];
    if (cached != null && cached.length >= 2) return cached;

    final client = _roadClients[this] ??= http.Client();
    try {
      final uri = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '${from.longitude},${from.latitude};'
        '${to.longitude},${to.latitude}'
        '?overview=full&geometries=geojson',
      );
      final response = await client
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
      cache[key] = points;
      return points;
    } catch (_) {
      return line(from: from, to: to);
    }
  }
}

String _roadCacheKey(GeoPoint from, GeoPoint to) {
  String pointKey(GeoPoint point) =>
      '${point.latitude.toStringAsFixed(5)},${point.longitude.toStringAsFixed(5)}';
  return '${pointKey(from)}>${pointKey(to)}';
}
