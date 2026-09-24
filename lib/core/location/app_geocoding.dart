import 'dart:async';

import 'package:movera_rider/core/api/api_client.dart';
import 'package:movera_rider/core/location/geocoding_repository.dart';
import 'package:movera_rider/core/maps/geo_point.dart';

class AppGeocoding implements GeocodingRepository {
  AppGeocoding({
    ApiClient? api,
    this.cacheTtl = const Duration(minutes: 10),
    this.requestTimeout = const Duration(seconds: 8),
  }) : _api = api;

  final ApiClient? _api;
  final Duration cacheTtl;
  final Duration requestTimeout;
  final Map<String, _CachedValue<PlaceResult?>> _forwardCache = {};
  final Map<String, _CachedValue<String?>> _reverseCache = {};
  final Map<String, Future<PlaceResult?>> _forwardInFlight = {};
  final Map<String, Future<String?>> _reverseInFlight = {};
  int _forwardGeneration = 0;
  int _reverseGeneration = 0;

  @override
  Future<PlaceResult?> forward(String query) async {
    final normalized = query.trim();
    if (normalized.isEmpty) return null;
    final key = normalized.toLowerCase();
    final cached = _forwardCache[key];
    if (cached != null && cached.isFresh(cacheTtl)) return cached.value;

    final generation = ++_forwardGeneration;
    final future = _forwardInFlight[key] ??= _forwardFromApi(normalized);
    try {
      final result = await future;
      if (generation != _forwardGeneration) return null;
      _forwardCache[key] = _CachedValue(result);
      return result;
    } finally {
      if (identical(_forwardInFlight[key], future)) _forwardInFlight.remove(key);
    }
  }

  @override
  Future<String?> reverse(GeoPoint point) async {
    final key =
        '${point.latitude.toStringAsFixed(5)}:${point.longitude.toStringAsFixed(5)}';
    final cached = _reverseCache[key];
    if (cached != null && cached.isFresh(cacheTtl)) return cached.value;

    final generation = ++_reverseGeneration;
    final future = _reverseInFlight[key] ??= _reverseFromApi(point);
    try {
      final result = await future;
      if (generation != _reverseGeneration) return null;
      _reverseCache[key] = _CachedValue(result);
      return result;
    } finally {
      if (identical(_reverseInFlight[key], future)) _reverseInFlight.remove(key);
    }
  }

  Future<String?> reverseGeocodeAddress(double latitude, double longitude) {
    return reverse(GeoPoint(latitude, longitude));
  }

  Future<PlaceResult?> geocodeAddress(String address) => forward(address);

  Future<PlaceResult?> _forwardFromApi(String query) async {
    final api = _requireApi();
    final response = await api
        .post('/api/v1/locations/geocode', body: {'query': query})
        .timeout(requestTimeout);
    final data = _payload(response);
    final latitude = data['latitude'];
    final longitude = data['longitude'];
    if (latitude is! num || longitude is! num) return null;
    return PlaceResult(
      address: data['address'] as String? ?? query,
      point: GeoPoint(latitude.toDouble(), longitude.toDouble()),
    );
  }

  Future<String?> _reverseFromApi(GeoPoint point) async {
    final api = _requireApi();
    final response = await api.post(
      '/api/v1/locations/reverse-geocode',
      body: {
        'latitude': point.latitude,
        'longitude': point.longitude,
      },
    ).timeout(requestTimeout);
    final data = _payload(response);
    final address = data['address'];
    return address is String && address.trim().isNotEmpty ? address.trim() : null;
  }

  ApiClient _requireApi() {
    final api = _api;
    if (api == null) {
      throw StateError('AppGeocoding requires the authenticated Movera ApiClient');
    }
    return api;
  }

  static Map<String, dynamic> _payload(Map<String, dynamic> response) {
    final data = response['data'];
    return data is Map
        ? Map<String, dynamic>.from(data)
        : response;
  }
}

class _CachedValue<T> {
  _CachedValue(this.value) : storedAt = DateTime.now();

  final T value;
  final DateTime storedAt;

  bool isFresh(Duration ttl) => DateTime.now().difference(storedAt) <= ttl;
}
