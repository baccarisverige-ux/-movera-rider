import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:movera_rider/core/api/api_client.dart';
import 'package:movera_rider/core/location/geocoding_repository.dart';
import 'package:movera_rider/core/location/web_reverse_geocode.dart';
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

  @override
  Future<PlaceResult?> forward(String query) async {
    final normalized = query.trim();
    if (normalized.isEmpty) return null;
    final key = normalized.toLowerCase();
    final cached = _forwardCache[key];
    if (cached != null && cached.isFresh(cacheTtl)) return cached.value;

    final existing = _forwardInFlight[key];
    if (existing != null) return existing;

    final future = _forwardFromApi(normalized);
    _forwardInFlight[key] = future;
    try {
      final result = await future;
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

    final existing = _reverseInFlight[key];
    if (existing != null) return existing;

    final future = _reverseFromApi(point);
    _reverseInFlight[key] = future;
    try {
      final result = await future;
      if (result != null) _reverseCache[key] = _CachedValue(result);
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
    final named = address is String && address.trim().isNotEmpty
        ? address.trim()
        : null;
    // The web demo's in-process transport knows no street names and answers
    // with a neutral label; the rider still wants to read where they are.
    if (kIsWeb && (named == null || named == placeholderReverseLabel)) {
      final street = await openStreetMapReverse(point, timeout: requestTimeout);
      if (street != null) return street;
    }
    return named;
  }

  /// What a transport without a geocoder answers instead of an address.
  static const String placeholderReverseLabel = 'Current location';

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
