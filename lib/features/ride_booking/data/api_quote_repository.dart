import 'package:movera_rider/core/api/api_client.dart';
import 'package:movera_rider/core/logging/app_log.dart';
import 'package:movera_rider/features/ride_booking/data/mock_quote_repository.dart';
import 'package:movera_rider/features/ride_booking/domain/entities/quote.dart';

class ApiQuoteRepository implements QuoteRepository {
  ApiQuoteRepository({required this.api});

  final ApiClient api;
  bool lastUsedFallback = false;

  @override
  Future<RideQuote> quote({
    required String rideType,
    required int distanceMeters,
    int durationSeconds = 600,
    String? pickup,
    String? destination,
  }) async {
    lastUsedFallback = false;
    try {
      final json = await api.post(
        '/api/v1/quotes',
        body: {
          'rideType': rideType,
          'distanceMeters': distanceMeters,
          'durationSeconds': durationSeconds,
          'pickup': pickup,
          'destination': destination,
          'apiVersion': 'v1',
        },
      );
      final raw = json['quote'];
      if (raw is! Map) {
        throw const FormatException('malformed quote');
      }
      final map = Map<String, dynamic>.from(raw);
      final total = (map['totalMinor'] ?? map['amountMinor']) as num?;
      if (total == null) throw const FormatException('malformed quote');
      final expires = DateTime.tryParse(map['expiresAt'] as String? ?? '');
      final quote = RideQuote(
        id: (map['quoteId'] ?? map['id'] ?? 'q_$rideType').toString(),
        rideType: (map['rideType'] ?? rideType).toString(),
        totalMinor: total.round(),
        currency: (map['currency'] ?? 'SEK').toString(),
        expiresAt: expires ?? DateTime.now().add(const Duration(minutes: 2)),
        baseMinor:
            (map['breakdown'] is Map
                    ? (map['breakdown']['baseMinor'] as num?)
                    : null)
                ?.round() ??
            total.round(),
        distanceMinor:
            (map['breakdown'] is Map
                    ? (map['breakdown']['distanceMinor'] as num?)
                    : null)
                ?.round() ??
            0,
        timeMinor:
            (map['breakdown'] is Map
                    ? (map['breakdown']['timeMinor'] as num?)
                    : null)
                ?.round() ??
            0,
        bookingFeeMinor:
            (map['breakdown'] is Map
                    ? (map['breakdown']['bookingFeeMinor'] as num?)
                    : null)
                ?.round() ??
            0,
        signedPayload: map['signedPayload'] as String? ?? 'mock-api',
      );
      if (quote.expired) throw StateError('expired quote');
      return quote;
    } catch (error, stack) {
      lastUsedFallback = false;
      AppLog.error(
        'quote.unavailable',
        extra: {
          'rideType': rideType,
          'reason': error.toString(),
        },
      );
      AppLog.error('quote.unavailable.stack', extra: {'stack': stack.toString()});
      rethrow;
    }
  }
}
