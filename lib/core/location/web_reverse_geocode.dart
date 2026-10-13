import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:movera_rider/core/maps/geo_point.dart';

/// Street address for a point from OpenStreetMap's Nominatim, used on the
/// web demo where the in-process transport has no geocoder of its own.
/// Returns null when nothing usable comes back.
Future<String?> openStreetMapReverse(
  GeoPoint point, {
  Duration timeout = const Duration(seconds: 6),
  http.Client? client,
}) async {
  final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
    'format': 'jsonv2',
    'lat': point.latitude.toStringAsFixed(6),
    'lon': point.longitude.toStringAsFixed(6),
    'zoom': '18',
    'addressdetails': '1',
  });
  final http.Client c = client ?? http.Client();
  try {
    final response = await c
        .get(uri, headers: const {'Accept': 'application/json'})
        .timeout(timeout);
    if (response.statusCode != 200) return null;
    final decoded = jsonDecode(response.body);
    if (decoded is! Map) return null;
    return formatOpenStreetMapAddress(
      Map<String, dynamic>.from(decoded['address'] as Map? ?? const {}),
    );
  } catch (_) {
    return null;
  } finally {
    if (client == null) c.close();
  }
}

/// "Klockarvägen 37, Geneta, Södertälje" from Nominatim's address parts.
String? formatOpenStreetMapAddress(Map<String, dynamic> address) {
  String? pick(List<String> keys) {
    for (final key in keys) {
      final value = address[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    return null;
  }

  final road = pick(['road', 'pedestrian', 'footway', 'path', 'square']);
  final number = pick(['house_number']);
  final area = pick(['suburb', 'neighbourhood', 'quarter', 'city_district']);
  final city = pick(['city', 'town', 'village', 'municipality', 'county']);
  final street = road == null
      ? null
      : number == null
      ? road
      : '$road $number';
  final parts = <String>[
    if (street != null) street,
    if (area != null && area != city) area,
    if (city != null) city,
  ];
  if (parts.isEmpty) return null;
  return parts.join(', ');
}
