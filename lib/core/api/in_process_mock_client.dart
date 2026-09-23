import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:movera_rider/core/api/safety_mock_api.dart';
import 'package:movera_rider/core/utils/request_id.dart';
import 'package:movera_rider/features/ride_booking/data/catalog_quote_repository.dart';

/// In-process `/api/v1` used on GitHub Pages and tests.
/// Swap [ApiClient] transport to a live HTTP client later — same paths.
class InProcessMockClient extends http.BaseClient {
  InProcessMockClient({this.latency = Duration.zero});

  final Duration latency;
  final Map<String, Map<String, dynamic>> idempotency = {};
  final Map<String, Map<String, dynamic>> rides = {};
  final Map<String, Map<String, dynamic>> quotes = {};
  final SafetyMockApi safety = safetyMockForProcess();
  bool failNext = false;
  Duration? timeoutNext;

  static const currency = 'SEK';

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (timeoutNext != null) {
      final wait = timeoutNext!;
      timeoutNext = null;
      await Future<void>.delayed(wait);
      throw TimeoutException('mock timeout');
    }
    if (latency > Duration.zero) {
      await Future<void>.delayed(latency);
    }
    final requestId = request.headers['X-Request-Id'] ?? newRequestId();
    final key = request.headers['Idempotency-Key'];
    final path = request.url.path;
    final method = request.method.toUpperCase();
    var body = <String, dynamic>{};
    if (request is http.Request && request.body.isNotEmpty) {
      final decoded = jsonDecode(request.body);
      if (decoded is Map<String, dynamic>) body = decoded;
    }

    if (failNext) {
      failNext = false;
      return _json(500, {
        'code': 'SERVER_ERROR',
        'message': 'Mock 500',
        'requestId': requestId,
      }, requestId);
    }

    if (key != null && key.isNotEmpty && idempotency.containsKey(key)) {
      return _json(200, idempotency[key]!, requestId);
    }

    late Map<String, dynamic> payload;
    var status = 200;
    final parts = path.split('/');

    if (path == '/api/v1/routes' && method == 'POST') {
      final from = body['from'];
      final to = body['to'];
      final fromMap = from is Map ? Map<String, dynamic>.from(from) : const <String, dynamic>{};
      final toMap = to is Map ? Map<String, dynamic>.from(to) : const <String, dynamic>{};
      payload = {
        'code': 'OK',
        'points': [
          {'lat': fromMap['lat'], 'lng': fromMap['lng']},
          {'lat': toMap['lat'], 'lng': toMap['lng']},
        ],
        'provider': 'movera-controlled',
        'requestId': requestId,
      };
    } else if (path == '/api/v1/quotes' && method == 'POST') {
      final quote = _quote(body);
      quotes[quote['id'] as String] = quote;
      payload = {'code': 'OK', 'quote': quote, 'requestId': requestId};
    } else if (path == '/api/v1/rides' && method == 'POST') {
      final validation = _validateQuoteBinding(body);
      if (validation != null) {
        status = 409;
        payload = {
          'code': validation,
          'message': 'Booking quote is missing, expired or does not match.',
          'requestId': requestId,
        };
      } else {
        final ride = _ride(body, requestId);
        rides[ride['id'] as String] = ride;
        payload = {'code': 'OK', 'ride': ride, 'requestId': requestId};
      }
    } else if (parts.length >= 6 &&
        parts[1] == 'api' &&
        parts[3] == 'rides' &&
        parts.last == 'disputes' &&
        method == 'POST') {
      final id = parts[4];
      final reason = body['reason'];
      if (reason is! String || reason.trim().isEmpty) {
        status = 400;
        payload = {'code': 'INVALID_DISPUTE', 'requestId': requestId};
      } else {
        payload = {
          'code': 'OK',
          'dispute': {
            'rideId': id,
            'reason': reason,
            if (body['detail'] is String) 'detail': body['detail'],
            'status': 'submitted',
          },
          'requestId': requestId,
        };
      }
    } else if (parts.length >= 6 &&
        parts[1] == 'api' &&
        parts[3] == 'rides' &&
        parts.last == 'cancel' &&
        method == 'POST') {
      final id = parts[4];
      final ride = rides[id];
      if (ride == null) {
        status = 404;
        payload = {'code': 'NOT_FOUND', 'requestId': requestId};
      } else if (ride['status'] == 'cancelledByRider') {
        payload = {'code': 'OK', 'ride': ride, 'requestId': requestId};
      } else {
        ride['status'] = 'cancelledByRider';
        if (body['reason'] is String) ride['cancellationReason'] = body['reason'];
        payload = {'code': 'OK', 'ride': ride, 'requestId': requestId};
      }
    } else if (parts.length >= 6 &&
        parts[1] == 'api' &&
        parts[3] == 'rides' &&
        parts.last == 'nearby' &&
        method == 'GET') {
      final id = parts[4];
      payload = {
        'code': 'OK',
        'vehicles': _nearby(rides[id]),
        'requestId': requestId,
      };
    } else if (parts.length >= 6 &&
        parts[1] == 'api' &&
        parts[3] == 'rides' &&
        parts.last == 'status' &&
        method == 'POST') {
      final id = parts[4];
      final ride = rides[id] ?? {'id': id, 'version': 0};
      ride['status'] = body['status'] ?? ride['status'];
      ride['version'] = ((ride['version'] as num?)?.toInt() ?? 0) + 1;
      ride['updatedAt'] = DateTime.now().toUtc().toIso8601String();
      if (body['driver'] is Map) ride['driver'] = body['driver'];
      if (body['lat'] != null) ride['driverLat'] = body['lat'];
      if (body['lng'] != null) ride['driverLng'] = body['lng'];
      rides[id] = ride;
      payload = {'code': 'OK', 'ride': ride, 'requestId': requestId};
    } else if (parts.length == 5 &&
        parts[1] == 'api' &&
        parts[3] == 'rides' &&
        method == 'PATCH') {
      final id = parts[4];
      final ride = rides[id];
      if (ride == null) {
        status = 404;
        payload = {'code': 'NOT_FOUND', 'requestId': requestId};
      } else {
        final currentStatus = ride['status'] as String?;
        final searching =
            currentStatus == 'findingDriver' || currentStatus == 'searchDelayed';
        if (!searching) {
          status = 409;
          payload = {
            'code': 'RIDE_NOT_SEARCHING',
            'message': 'Ride can only be edited while searching',
            'ride': ride,
            'requestId': requestId,
          };
        } else {
          if (body['price'] != null) ride['price'] = body['price'];
          if (body['offerIncreaseKr'] != null) {
            ride['offerIncreaseKr'] = body['offerIncreaseKr'];
          }
          if (body['pickupAddress'] != null) {
            ride['pickupAddress'] = body['pickupAddress'];
          }
          if (body['pickupLat'] != null) ride['pickupLat'] = body['pickupLat'];
          if (body['pickupLng'] != null) ride['pickupLng'] = body['pickupLng'];
          if (body['destinationAddress'] != null) {
            ride['destinationAddress'] = body['destinationAddress'];
          }
          if (body['destinationLat'] != null) {
            ride['destinationLat'] = body['destinationLat'];
          }
          if (body['destinationLng'] != null) {
            ride['destinationLng'] = body['destinationLng'];
          }
          payload = {'code': 'OK', 'ride': ride, 'requestId': requestId};
        }
      }
    } else if (path.startsWith('/api/v1/rides/') &&
        method == 'GET' &&
        parts.length == 5) {
      final id = parts.last;
      final ride = rides[id];
      if (ride == null) {
        status = 404;
        payload = {'code': 'NOT_FOUND', 'requestId': requestId};
      } else {
        payload = {'code': 'OK', 'ride': ride, 'requestId': requestId};
      }
    } else if (path == '/api/v1/payments' && method == 'POST') {
      payload = {
        'code': 'OK',
        'intent': {
          'id': 'pi_$requestId',
          'status': 'succeeded',
          'amountMinor': body['amountMinor'] ?? 0,
        },
        'requestId': requestId,
      };
    } else if (path == '/api/v1/wallet/topup' && method == 'POST') {
      payload = {
        'code': 'OK',
        'status': 'succeeded',
        'amountMinor': body['amountMinor'] ?? 0,
        'requestId': requestId,
      };
    } else if (path == '/health' && method == 'GET') {
      payload = {'ok': true, 'requestId': requestId};
    } else {
      final safetyHit = safety.handle(
        method: method,
        path: path,
        body: body,
        requestId: requestId,
      );
      if (safetyHit != null) {
        status = safetyHit.status;
        payload = safetyHit.payload;
      } else {
        status = 404;
        payload = {'code': 'NOT_FOUND', 'path': path, 'requestId': requestId};
      }
    }

    if (key != null && key.isNotEmpty && status < 400) {
      idempotency[key] = payload;
    }
    return _json(status, payload, requestId);
  }

  Map<String, dynamic> _quote(Map<String, dynamic> body) {
    final rideType = body['rideType'] as String? ?? 'movera';
    final kr = CatalogQuoteRepository.pricesKr[rideType] ?? 259;
    final minor = kr * 100;
    final id = 'q_${rideType}_${newRequestId()}';
    return {
      'id': id,
      'quoteId': id,
      'rideType': rideType,
      'totalMinor': minor,
      'amountMinor': minor,
      'currency': currency,
      'expiresAt': DateTime.now().add(const Duration(minutes: 2)).toIso8601String(),
      'expiresInSec': 120,
      'breakdown': {
        'baseMinor': minor,
        'distanceMinor': 0,
        'timeMinor': 0,
        'bookingFeeMinor': 0,
      },
      'signedPayload': 'mock-api',
      'pickup': body['pickup'],
      'destination': body['destination'],
    };
  }

  String? _validateQuoteBinding(Map<String, dynamic> body) {
    // Scheduled test bookings do not yet use the on-demand quote path.
    if (body['scheduledAt'] != null) return null;
    if (body['pickupAddress'] == null) return null;

    final quoteId = body['quoteId'] as String?;
    final signed = body['quoteSignedPayload'] as String?;
    final expiryRaw = body['quoteExpiresAt'] as String?;
    final quotedTotal = (body['quoteTotalMinor'] as num?)?.round();
    if (quoteId == null ||
        quoteId.isEmpty ||
        signed == null ||
        signed.isEmpty ||
        expiryRaw == null ||
        quotedTotal == null) {
      return 'QUOTE_REQUIRED';
    }

    final quote = quotes[quoteId];
    if (quote == null) return 'QUOTE_NOT_FOUND';
    if (quote['signedPayload'] != signed) return 'QUOTE_SIGNATURE_MISMATCH';

    final expiresAt = DateTime.tryParse(expiryRaw);
    final serverExpiry = DateTime.tryParse(quote['expiresAt'] as String? ?? '');
    if (expiresAt == null ||
        serverExpiry == null ||
        expiresAt.toUtc() != serverExpiry.toUtc() ||
        !serverExpiry.isAfter(DateTime.now())) {
      return 'QUOTE_EXPIRED';
    }

    final serverTotal = (quote['totalMinor'] as num?)?.round();
    if (serverTotal == null || serverTotal != quotedTotal) {
      return 'QUOTE_AMOUNT_MISMATCH';
    }

    final categoryId = (body['categoryId'] ?? '').toString();
    if (quote['rideType'] != categoryId) return 'QUOTE_CATEGORY_MISMATCH';

    final submittedPrice = (body['price'] as num?)?.toDouble();
    if (submittedPrice == null ||
        (submittedPrice * 100).round() != serverTotal) {
      return 'QUOTE_PRICE_MISMATCH';
    }

    return null;
  }

  Map<String, dynamic> _ride(Map<String, dynamic> body, String requestId) {
    final categoryId =
        (body['categoryId'] ?? body['rideType'] ?? 'movera').toString();
    final paymentMethodId =
        (body['paymentMethodId'] ?? body['paymentMethod'] ?? 'wallet').toString();
    return {
      'id': 'ride_$requestId',
      'status': body['scheduledAt'] != null ? 'bookingRequested' : 'findingDriver',
      'version': 1,
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
      'categoryId': categoryId,
      'paymentMethodId': paymentMethodId,
      // Transitional aliases keep older read-side tests compatible while every
      // new write uses the canonical backend vocabulary above.
      'rideType': categoryId,
      'paymentMethod': paymentMethodId,
      'price': body['price'],
      'quoteId': body['quoteId'],
      'quoteSignedPayload': body['quoteSignedPayload'],
      'quoteExpiresAt': body['quoteExpiresAt'],
      'quoteTotalMinor': body['quoteTotalMinor'],
      'pickupAddress': body['pickupAddress'],
      'destinationAddress': body['destinationAddress'],
      'pickupLat': body['pickupLat'],
      'pickupLng': body['pickupLng'],
      'destinationLat': body['destinationLat'],
      'destinationLng': body['destinationLng'],
      'scheduledAt': body['scheduledAt'],
      // Rider notes are part of the ride the driver is given, so the stand-in
      // backend stores them the way the real one will.
      'notes': body['notes'],
    };
  }

  List<Map<String, dynamic>> _nearby(Map<String, dynamic>? ride) {
    final lat = (ride?['pickupLat'] as num?)?.toDouble();
    final lng = (ride?['pickupLng'] as num?)?.toDouble();
    if (lat == null || lng == null) return const [];
    return [
      {'id': 'veh_a', 'lat': lat + 0.0021, 'lng': lng - 0.0014, 'bearing': 42},
      {'id': 'veh_b', 'lat': lat - 0.0016, 'lng': lng + 0.0022, 'bearing': 210},
      {'id': 'veh_c', 'lat': lat + 0.0008, 'lng': lng + 0.0018, 'bearing': 128},
    ];
  }

  http.StreamedResponse _json(
    int status,
    Map<String, dynamic> body,
    String requestId,
  ) {
    final bytes = utf8.encode(jsonEncode(body));
    return http.StreamedResponse(
      Stream<List<int>>.value(bytes),
      status,
      headers: {
        'content-type': 'application/json',
        'x-request-id': requestId,
      },
      contentLength: bytes.length,
    );
  }
}
