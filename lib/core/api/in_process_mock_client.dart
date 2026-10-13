import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

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
  final Map<String, Map<String, dynamic>> otpSessions = {};

  /// Phones that have verified a code before: their riders are returning.
  final Set<String> knownPhones = {};

  /// Apple/Google accounts that already have a verified phone.
  final Set<String> linkedProviders = {};

  /// Link tokens issued for provider sign-ins still waiting for a phone.
  final Map<String, String> pendingLinks = {};
  final Map<String, Map<String, dynamic>> pushDevices = {};
  final Map<String, Map<String, dynamic>> paymentIntents = {};

  /// The demo rider's promotion; tests may replace or clear it.
  Map<String, dynamic>? activePromotion = {
    'id': 'promo_demo_30',
    'title': '30% off your next 5 rides',
    'percentOff': 30,
    'ridesLeft': 4,
    'ridesTotal': 5,
    'endsAt': '2026-11-30T23:59:00Z',
    'maxDiscountMinor': 5000,
    'rideTypes': ['comfort', 'priority', 'premium'],
    'rules': [
      'Applies to Comfort, Priority and Premium.',
      'Up to kr 50 off each ride.',
    ],
  };
  final Map<String, dynamic> accountSecurity = {
    'phone': '',
    'email': '',
    'phoneVerifiedAt': null,
    'emailVerifiedAt': null,
    'passkeyEnabled': false,
    'twoStepEnabled': false,
    'authenticatorEnabled': false,
    'passwordUpdatedAt': null,
    'recoveryPhone': null,
    'googleConnected': false,
    'appleConnected': false,
    'reauthenticatedAt': null,
    'capabilities': {
      'passkeys': false,
      'password': false,
      'authenticator': false,
      'twoStep': false,
      'recoveryPhone': false,
      'connectedAccounts': false,
      'reauthentication': false,
      'signOutOtherDevices': false,
    },
    'sessions': [
      {
        'id': 'session_current',
        'device': 'This device',
        'place': '',
        'source': 'Movera',
        'current': true,
      },
    ],
  };
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

    if (path == '/api/v1/locations/reverse-geocode' && method == 'POST') {
      final latitude = body['latitude'];
      final longitude = body['longitude'];
      if (latitude is! num || longitude is! num) {
        status = 400;
        payload = {'code': 'INVALID_COORDINATES', 'requestId': requestId};
      } else {
        payload = {
          'code': 'OK',
          'data': {
            'latitude': latitude.toDouble(),
            'longitude': longitude.toDouble(),
            // The in-process transport has no external geocoder. Preserve the
            // real device coordinates and expose a neutral label instead of
            // failing the entire location pipeline.
            'address': 'Current location',
          },
          'requestId': requestId,
        };
      }
    } else if (path == '/api/v1/locations/geocode' && method == 'POST') {
      final query = body['query'];
      if (query is! String || query.trim().isEmpty) {
        status = 400;
        payload = {'code': 'INVALID_QUERY', 'requestId': requestId};
      } else {
        final normalized = query.trim();
        // A known demo place geocodes to where it really is (Arlanda is not
        // next to Stockholm Central); anything else gets a stable made-up
        // point so demo bookings still work.
        final known = _demoSuggestions(
          normalized,
          typedFallback: false,
        ).firstOrNull;
        if (known != null) {
          payload = {
            'code': 'OK',
            'data': {
              'address': normalized,
              'latitude': known['latitude'],
              'longitude': known['longitude'],
            },
            'requestId': requestId,
          };
          return _json(status, payload, requestId);
        }
        final hash = normalized.toLowerCase().codeUnits.fold<int>(
          0,
          (value, unit) => ((value * 31) + unit) & 0x7fffffff,
        );
        // Deterministic demo coordinates keep the frontend booking contract
        // operational on GitHub Pages until the real geocoder is connected.
        final latitude = 59.3293 + (((hash % 1201) - 600) / 100000.0);
        final longitude = 18.0686 + ((((hash ~/ 1201) % 1601) - 800) / 100000.0);
        payload = {
          'code': 'OK',
          'data': {
            'address': normalized,
            'latitude': latitude,
            'longitude': longitude,
          },
          'requestId': requestId,
        };
      }
    } else if (path == '/api/v1/locations/autocomplete' && method == 'POST') {
      final query = body['query'];
      payload = {
        'code': 'OK',
        'suggestions': query is String ? _demoSuggestions(query) : const [],
        'requestId': requestId,
      };
    } else if (path == '/api/v1/auth/otp/request' && method == 'POST') {
      final phone = body['phone'];
      final linkToken = body['linkToken'];
      if (phone is! String || phone.trim().isEmpty) {
        status = 400;
        payload = {'code': 'INVALID_PHONE', 'requestId': requestId};
      } else if (linkToken != null &&
          (linkToken is! String || !pendingLinks.containsKey(linkToken))) {
        status = 400;
        payload = {'code': 'INVALID_LINK', 'requestId': requestId};
      } else {
        final sessionId = 'otp_${newRequestId()}';
        final expiresAt = DateTime.now()
            .toUtc()
            .add(const Duration(minutes: 5));
        otpSessions[sessionId] = {
          'phone': phone.trim(),
          if (linkToken is String) 'linkToken': linkToken,
          'code': '1234',
          'expiresAt': expiresAt.toIso8601String(),
        };
        payload = {
          'code': 'OK',
          'requestId': requestId,
          'sessionId': sessionId,
          'expiresAt': expiresAt.toIso8601String(),
          'retryAfterSeconds': 30,
        };
      }
    } else if (path == '/api/v1/auth/otp/verify' && method == 'POST') {
      final phone = body['phone'];
      final sessionId = body['sessionId'];
      final code = body['code'];
      final session = sessionId is String ? otpSessions[sessionId] : null;
      if (session == null ||
          phone is! String ||
          code is! String ||
          session['phone'] != phone.trim()) {
        status = 400;
        payload = {'code': 'INVALID_OTP_SESSION', 'requestId': requestId};
      } else {
        final expiresAt = DateTime.tryParse('${session['expiresAt'] ?? ''}');
        if (expiresAt == null || !expiresAt.isAfter(DateTime.now().toUtc())) {
          status = 410;
          payload = {'code': 'OTP_EXPIRED', 'requestId': requestId};
        } else if (session['code'] != code.trim()) {
          status = 401;
          payload = {'code': 'INVALID_OTP', 'requestId': requestId};
        } else {
          otpSessions.remove(sessionId);
          final normalizedPhone = phone.trim();
          final isNewRider = knownPhones.add(normalizedPhone);
          final linkToken = session['linkToken'];
          final provider = linkToken is String ? pendingLinks.remove(linkToken) : null;
          if (provider != null) {
            // The provider account now has a verified phone.
            linkedProviders.add(provider);
          }
          final kind = provider ?? 'phone';
          payload = {
            'code': 'OK',
            'accessToken': 'mock-access-$kind-$sessionId',
            'refreshToken': 'mock-refresh-$kind-$sessionId',
            'isNewRider': isNewRider,
            'requestId': requestId,
          };
        }
      }
    } else if (path == '/api/v1/auth/provider' && method == 'POST') {
      final provider = body['provider'];
      if (provider is! String || provider.trim().isEmpty) {
        status = 400;
        payload = {'code': 'INVALID_PROVIDER', 'requestId': requestId};
      } else if (!linkedProviders.contains(provider.trim())) {
        // First sign-in with this account: no session until a phone is
        // verified, only a short-lived link token.
        final linkToken = 'link_${provider.trim()}_${newRequestId()}';
        pendingLinks[linkToken] = provider.trim();
        payload = {
          'code': 'PHONE_REQUIRED',
          'linkToken': linkToken,
          'requestId': requestId,
        };
      } else {
        payload = {
          'code': 'OK',
          'accessToken': 'mock-access-${provider.trim()}',
          'refreshToken': 'mock-refresh-${provider.trim()}',
          'requestId': requestId,
        };
      }
    } else if (path == '/api/v1/auth/refresh' && method == 'POST') {
      final refreshToken = body['refreshToken'];
      if (refreshToken is! String || !refreshToken.startsWith('mock-refresh-')) {
        status = 401;
        payload = {'code': 'INVALID_REFRESH', 'requestId': requestId};
      } else {
        payload = {
          'code': 'OK',
          'accessToken': 'mock-access-refreshed-${newRequestId()}',
          'refreshToken': 'mock-refresh-rotated-${newRequestId()}',
          'requestId': requestId,
        };
      }
    } else if (path == '/api/v1/auth/sign-out' && method == 'POST') {
      payload = {'code': 'OK', 'requestId': requestId};
    } else if (path == '/api/v1/push/devices' && method == 'POST') {
      final token = body['token'];
      final provider = body['provider'];
      final platform = body['platform'];
      if (token is! String ||
          token.trim().isEmpty ||
          provider != 'fcm' ||
          platform is! String ||
          platform.trim().isEmpty) {
        status = 400;
        payload = {'code': 'INVALID_PUSH_DEVICE', 'requestId': requestId};
      } else {
        final normalized = token.trim();
        pushDevices[normalized] = {
          'token': normalized,
          'provider': 'fcm',
          'platform': platform.trim(),
        };
        payload = {
          'code': 'OK',
          'status': 'registered',
          'requestId': requestId,
        };
      }
    } else if (path == '/api/v1/push/devices/unregister' &&
        method == 'POST') {
      final token = body['token'];
      if (token is! String || token.trim().isEmpty) {
        status = 400;
        payload = {'code': 'INVALID_PUSH_DEVICE', 'requestId': requestId};
      } else {
        pushDevices.remove(token.trim());
        payload = {
          'code': 'OK',
          'status': 'unregistered',
          'requestId': requestId,
        };
      }
    } else if (path == '/api/v1/account/security' && method == 'GET') {
      payload = {
        'code': 'OK',
        'security': accountSecurity,
        'requestId': requestId,
      };
    } else if (path == '/api/v1/account/security/sessions/sign-out-others' &&
        method == 'POST') {
      final reauthenticatedAt = DateTime.tryParse(
        '${accountSecurity['reauthenticatedAt'] ?? ''}',
      );
      final now = DateTime.now().toUtc();
      final age = reauthenticatedAt == null
          ? null
          : now.difference(reauthenticatedAt.toUtc());
      final fresh = age != null &&
          !age.isNegative &&
          age <= const Duration(minutes: 5);
      if (!fresh) {
        status = 403;
        payload = {
          'code': 'REAUTH_REQUIRED',
          'message': 'Fresh reauthentication is required.',
          'requestId': requestId,
        };
      } else {
        final sessions = accountSecurity['sessions'];
        if (sessions is List) {
          accountSecurity['sessions'] = sessions
              .whereType<Map>()
              .where((item) => item['current'] == true)
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
        }
        accountSecurity['reauthenticatedAt'] = null;
        payload = {
          'code': 'OK',
          'security': accountSecurity,
          'requestId': requestId,
        };
      }
    } else if (path == '/api/v1/routes' && method == 'POST') {
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
    } else if (parts.length == 6 &&
        parts[1] == 'api' &&
        parts[3] == 'rides' &&
        parts.last == 'feedback' &&
        method == 'POST') {
      final ride = rides[parts[4]];
      final rating = body['rating'];
      final tipMinor = body['tipMinor'];
      if (ride == null) {
        status = 404;
        payload = {'code': 'NOT_FOUND', 'requestId': requestId};
      } else if (!['tripCompleted', 'paymentFinalized', 'ratingPending'].contains(ride['status'])) {
        status = 409;
        payload = {'code': 'RIDE_NOT_COMPLETE', 'requestId': requestId};
      } else if ((rating == null && tipMinor == null) ||
          (rating != null && (rating is! num || rating < 1 || rating > 5 || rating * 2 != (rating * 2).round())) ||
          (tipMinor != null && (tipMinor is! int || tipMinor <= 0 || tipMinor > 999900 || body['currency'] != 'SEK'))) {
        status = 400;
        payload = {'code': 'INVALID_FEEDBACK', 'requestId': requestId};
      } else {
        ride['feedback'] = {
          if (rating != null) 'rating': rating,
          if (tipMinor != null) 'tipMinor': tipMinor,
          if (tipMinor != null) 'currency': 'SEK',
        };
        payload = {'code': 'OK', 'status': 'accepted', 'requestId': requestId};
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
    } else if (parts.length == 6 &&
        parts[1] == 'api' &&
        parts[3] == 'rides' &&
        parts.last == 'route-quote' &&
        method == 'POST') {
      // Prices a route change (new pickup, destination or stops) without
      // applying it, so the rider sees the new price before confirming.
      final ride = rides[parts[4]];
      if (ride == null) {
        status = 404;
        payload = {'code': 'NOT_FOUND', 'requestId': requestId};
      } else {
        final denied = _routeChangeDenied(ride, body);
        if (denied != null) {
          status = 409;
          payload = {'code': denied, 'ride': ride, 'requestId': requestId};
        } else {
          payload = {
            'code': 'OK',
            ..._routeChangePricing(ride, body),
            'requestId': requestId,
          };
        }
      }
    } else if (parts.length == 5 &&
        parts[1] == 'api' &&
        parts[3] == 'rides' &&
        method == 'PATCH') {
      final id = parts[4];
      final ride = rides[id];
      final routeChange = body['routeChange'] == true;
      if (ride == null) {
        status = 404;
        payload = {'code': 'NOT_FOUND', 'requestId': requestId};
      } else if (routeChange) {
        final denied = _routeChangeDenied(ride, body);
        if (denied != null) {
          status = 409;
          payload = {'code': denied, 'ride': ride, 'requestId': requestId};
        } else {
          final pricing = _routeChangePricing(ride, body);
          if (body['pickupAddress'] != null) {
            ride['pickupAddress'] = body['pickupAddress'];
            ride['pickupLat'] = body['pickupLat'];
            ride['pickupLng'] = body['pickupLng'];
          }
          ride['destinationAddress'] = body['destinationAddress'];
          ride['destinationLat'] = body['destinationLat'];
          ride['destinationLng'] = body['destinationLng'];
          ride['stops'] = pricing['stops'];
          ride['price'] = pricing['newPriceKr'];
          ride['version'] = ((ride['version'] as num?)?.toInt() ?? 0) + 1;
          ride['updatedAt'] = DateTime.now().toUtc().toIso8601String();
          // The driver app is told on its next poll; the log is what admin
          // reads later.
          ride['driverNotifiedAt'] = ride['updatedAt'];
          // Pay in car only shows the new price; any other method is
          // charged or refunded the difference right away.
          final method = (body['paymentMethod'] ?? '').toString();
          final cash =
              method.toLowerCase() == 'cash' ||
              method.toLowerCase().contains('pay in car');
          final difference = pricing['differenceKr'] as double;
          if (!cash && difference.abs() >= 0.5) {
            (ride['paymentAdjustments'] ??= <Map<String, dynamic>>[]).add({
              'at': ride['updatedAt'],
              'method': method,
              'amountKr': difference,
              'status': difference > 0 ? 'captured' : 'refunded',
            });
          }
          (ride['routeChanges'] ??= <Map<String, dynamic>>[]).add({
            'at': ride['updatedAt'],
            'destinationAddress': body['destinationAddress'],
            'stops': pricing['stops'],
            'newPriceKr': pricing['newPriceKr'],
            'differenceKr': pricing['differenceKr'],
          });
          payload = {
            'code': 'OK',
            'ride': ride,
            ...pricing,
            'requestId': requestId,
          };
        }
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
        } else if (body.containsKey('offerIncreaseKr') &&
            !_validOfferIncrease(body['offerIncreaseKr'], ride['price'])) {
          status = 422;
          payload = {
            'code': 'INVALID_OFFER',
            'message': 'Offer increase must be a positive whole amount',
            'requestId': requestId,
          };
        } else {
          // D-012: the server prices an offer bump itself from the rider's
          // intent (offerIncreaseKr). A client-sent `price` is never treated
          // as authority and is ignored. (A real backend must also bound the
          // bump; this in-process mock does not model fare limits.)
          final increase = body['offerIncreaseKr'];
          if (increase is num) {
            ride['price'] = (ride['price'] as num) + increase;
            ride['offerIncreaseKr'] = increase;
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
      final amountMinor = body['amountMinor'];
      final currency = body['currency'];
      if (amountMinor is! int ||
          amountMinor <= 0 ||
          currency is! String ||
          currency.trim().toUpperCase() != 'SEK') {
        status = 400;
        payload = {
          'code': 'INVALID_PAYMENT_INTENT',
          'requestId': requestId,
        };
      } else {
        final intent = <String, dynamic>{
          'id': 'pi_$requestId',
          'status': 'requires_confirmation',
          'amountMinor': amountMinor,
          'currency': 'SEK',
        };
        paymentIntents[intent['id'] as String] = intent;
        payload = {
          'code': 'OK',
          'intent': Map<String, dynamic>.from(intent),
          'requestId': requestId,
        };
      }
    } else if (parts.length == 6 &&
        parts[1] == 'api' &&
        parts[3] == 'payments' &&
        parts.last == 'confirm' &&
        method == 'POST') {
      final intent = paymentIntents[parts[4]];
      if (intent == null) {
        status = 404;
        payload = {'code': 'PAYMENT_NOT_FOUND', 'requestId': requestId};
      } else {
        intent['status'] = 'succeeded';
        payload = {
          'code': 'OK',
          'status': 'succeeded',
          'intent': Map<String, dynamic>.from(intent),
          'requestId': requestId,
        };
      }
    } else if (parts.length == 5 &&
        parts[1] == 'api' &&
        parts[3] == 'payments' &&
        method == 'GET') {
      final intent = paymentIntents[parts[4]];
      if (intent == null) {
        status = 404;
        payload = {'code': 'PAYMENT_NOT_FOUND', 'requestId': requestId};
      } else {
        payload = {
          'code': 'OK',
          'status': intent['status'],
          'intent': Map<String, dynamic>.from(intent),
          'requestId': requestId,
        };
      }
    } else if (path == '/api/v1/wallet/topup' && method == 'POST') {
      payload = {
        'code': 'OK',
        'status': 'succeeded',
        'amountMinor': body['amountMinor'] ?? 0,
        'requestId': requestId,
      };
    } else if (path == '/api/v1/rider/promotions/active' && method == 'GET') {
      // Demo transport only: a sample admin promotion so the ticket can be
      // seen on GitHub Pages. The live API returns the rider's real one.
      payload = {
        'code': 'OK',
        'promotion': activePromotion,
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

  /// Demo-only places around Södertälje and Stockholm, so address search can
  /// be tried on GitHub Pages. The live API searches real addresses.
  static const List<(String, String, double, double)> _demoPlaces = [
    ('Klockarvägen 37', '151 59 Södertälje', 59.1955, 17.6253),
    ('Klockarvägen 98', 'Södertälje', 59.1949, 17.6301),
    ('Klockarvägen 104', 'Södertälje', 59.1946, 17.6318),
    ('Klockarvägen 110', 'Södertälje', 59.1941, 17.6336),
    ('Klostergatan 3', 'Södertälje', 59.1991, 17.6262),
    ('Albyvägen 5', '145 59 Norsborg', 59.2448, 17.8562),
    ('Alby Centrum', 'Albyvägen 6, Norsborg', 59.2393, 17.8457),
    ('Drottninggatan 5', '111 51 Stockholm', 59.3326, 18.0649),
    ('Drottninggatan 5', '753 10 Uppsala', 59.8586, 17.6389),
    ('Stockholm Central', 'Centralplan 15, Stockholm', 59.3303, 18.0590),
    ('Stockholm Arlanda Airport', 'Arlanda', 59.6498, 17.9238),
    ('Arlanda Airport Terminal 5', 'Arlanda', 59.6519, 17.9297),
    ('Södertälje Centrum', 'Storgatan, Södertälje', 59.1960, 17.6260),
    ('Svarvarvägen 5', '142 50 Stockholm', 59.2089, 17.9466),
    ('Mall of Scandinavia', 'Stjärntorget 2, Solna', 59.3700, 18.0050),
  ];

  static String _fold(String value) {
    const from = 'åäöéèêëàâüïîôç';
    const to = 'aaoeeeeaauiioc';
    final out = StringBuffer();
    for (final char in value.toLowerCase().split('')) {
      final i = from.indexOf(char);
      out.write(i < 0 ? char : to[i]);
    }
    return out.toString();
  }

  List<Map<String, dynamic>> _demoSuggestions(
    String query, {
    bool typedFallback = true,
  }) {
    final words = _fold(query.trim()).split(RegExp(r'[\s,]+'))
      ..removeWhere((w) => w.isEmpty);
    if (words.isEmpty) return const [];
    final found = <Map<String, dynamic>>[];
    for (final (title, subtitle, lat, lng) in _demoPlaces) {
      final hay = _fold('$title $subtitle');
      final tokens = hay.split(RegExp(r'[\s,]+'));
      final all = words.every(
        (w) => tokens.any((t) => t.startsWith(w)) || hay.contains(w),
      );
      if (!all) continue;
      found.add({
        'title': title,
        'subtitle': subtitle,
        'latitude': lat,
        'longitude': lng,
      });
    }
    // Anything else typed is still offered, so demo bookings always work.
    final typed = query.trim();
    if (typedFallback && typed.length >= 3 && found.isEmpty) {
      final hash = _fold(typed).codeUnits.fold<int>(
        0,
        (value, unit) => ((value * 31) + unit) & 0x7fffffff,
      );
      found.add({
        'title': typed,
        'subtitle': 'Sweden',
        'latitude': 59.3293 + (((hash % 1201) - 600) / 100000.0),
        'longitude': 18.0686 + ((((hash ~/ 1201) % 1601) - 800) / 100000.0),
      });
    }
    return found.take(8).toList();
  }

  static const _terminalStatuses = {
    'tripCompleted',
    'paymentProcessing',
    'paymentFinalized',
    'ratingPending',
    'closed',
    'cancelledByRider',
    'cancelledByDriver',
    'cancelledBySystem',
    'noDriverFound',
  };

  /// Pickup can move until the driver is at the door; the destination and
  /// the stops can change until the trip is over.
  String? _routeChangeDenied(
    Map<String, dynamic> ride,
    Map<String, dynamic> body,
  ) {
    final current = ride['status'] as String? ?? '';
    if (_terminalStatuses.contains(current)) return 'RIDE_FINISHED';
    final pickupChanged =
        body['pickupAddress'] != null &&
        body['pickupAddress'] != ride['pickupAddress'];
    const pickupEditable = {
      'findingDriver',
      'searchDelayed',
      'driverAssigned',
      'driverArriving',
    };
    if (pickupChanged && !pickupEditable.contains(current)) {
      return 'PICKUP_LOCKED';
    }
    if (body['destinationLat'] is! num || body['destinationLng'] is! num) {
      return 'DESTINATION_REQUIRED';
    }
    return null;
  }

  static double _km(num lat1, num lng1, num lat2, num lng2) {
    const r = 6371.0;
    final dLat = (lat2 - lat1) * math.pi / 180;
    final dLng = (lng2 - lng1) * math.pi / 180;
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * math.pi / 180) *
            math.cos(lat2 * math.pi / 180) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return 2 * r * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  /// New price for a changed route: the booked price, plus 25 kr per stop
  /// and 12 kr per extra kilometre beyond what was booked. Shorter routes
  /// get the difference back.
  Map<String, dynamic> _routeChangePricing(
    Map<String, dynamic> ride,
    Map<String, dynamic> body,
  ) {
    final bookedPrice =
        (ride['bookedPrice'] as num?)?.toDouble() ??
        (ride['price'] as num?)?.toDouble() ??
        0;
    final pLat = (body['pickupLat'] ?? ride['pickupLat']) as num?;
    final pLng = (body['pickupLng'] ?? ride['pickupLng']) as num?;
    final dLat = body['destinationLat'] as num;
    final dLng = body['destinationLng'] as num;
    final stops = <Map<String, dynamic>>[
      if (body['stops'] is List)
        for (final raw in body['stops'] as List)
          if (raw is Map && raw['lat'] is num && raw['lng'] is num)
            {
              'address': raw['address']?.toString() ?? '',
              'lat': raw['lat'],
              'lng': raw['lng'],
            },
    ];
    double routeKm = 0;
    if (pLat != null && pLng != null) {
      var lat = pLat;
      var lng = pLng;
      for (final stop in stops) {
        routeKm += _km(lat, lng, stop['lat'] as num, stop['lng'] as num);
        lat = stop['lat'] as num;
        lng = stop['lng'] as num;
      }
      routeKm += _km(lat, lng, dLat, dLng);
    }
    final bookedKm = (ride['bookedKm'] as num?)?.toDouble() ?? routeKm;
    final newPrice =
        (bookedPrice + stops.length * 25 + (routeKm - bookedKm) * 12)
            .clamp(bookedPrice * 0.5, double.infinity)
            .roundToDouble();
    final current = (ride['price'] as num?)?.toDouble() ?? bookedPrice;
    return {
      'newPriceKr': newPrice,
      'differenceKr': newPrice - current,
      'routeKm': double.parse(routeKm.toStringAsFixed(2)),
      'stops': stops,
    };
  }

  Map<String, dynamic> _quote(Map<String, dynamic> body) {
    final rideType = body['rideType'] as String? ?? 'movera';
    final kr = CatalogQuoteRepository.pricesKr[rideType] ?? 259;
    final fullMinor = kr * 100;
    // Demo promotion: discounts the ride types it names, capped per ride.
    final promo = activePromotion;
    final eligible =
        promo != null &&
        (promo['rideTypes'] as List? ?? const []).contains(rideType);
    final discountMinor = eligible
        ? ((fullMinor * (promo['percentOff'] as num) / 100).round()).clamp(
            0,
            (promo['maxDiscountMinor'] as num?)?.round() ?? fullMinor,
          )
        : 0;
    final minor = fullMinor - discountMinor;
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
        'discountMinor': discountMinor,
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
      'bookedPrice': body['price'],
      'bookedKm':
          body['pickupLat'] is num &&
              body['pickupLng'] is num &&
              body['destinationLat'] is num &&
              body['destinationLng'] is num
          ? _km(
              body['pickupLat'] as num,
              body['pickupLng'] as num,
              body['destinationLat'] as num,
              body['destinationLng'] as num,
            )
          : null,
      'stops': <Map<String, dynamic>>[
        if (body['stops'] is List)
          for (final raw in body['stops'] as List)
            if (raw is Map && raw['lat'] is num && raw['lng'] is num)
              {
                'address': raw['address']?.toString() ?? '',
                'lat': raw['lat'],
                'lng': raw['lng'],
              },
      ],
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

  static bool _validOfferIncrease(Object? increase, Object? currentPrice) =>
      increase is num &&
      increase > 0 &&
      increase == increase.roundToDouble() &&
      currentPrice is num;
}
