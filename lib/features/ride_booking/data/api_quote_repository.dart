import 'package:movera_rider/core/api/api_client.dart';
import 'package:movera_rider/core/logging/app_log.dart';
import 'package:movera_rider/core/utils/stale_guard.dart';
import 'package:movera_rider/features/ride_booking/data/catalog_quote_repository.dart';
import 'package:movera_rider/features/ride_booking/data/mock_quote_repository.dart';
import 'package:movera_rider/features/ride_booking/domain/entities/quote.dart';

class ApiQuoteRepository implements QuoteRepository {
  ApiQuoteRepository({
    required this.api,
    QuoteRepository? fallback,
  }) : fallback = fallback ?? CatalogQuoteRepository();

  final ApiClient api;
  final QuoteRepository fallback;
  final StaleGuard stale = StaleGuard();
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
    final generation = stale.next();
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
      if (!stale.isCurrent(generation)) {
        throw const FormatException('stale quote');
      }
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
        baseMinor: (map['breakdown'] is Map
                ? (map['breakdown']['baseMinor'] as num?)
                : null)
            ?.round() ??
            total.round(),
        distanceMinor: (map['breakdown'] is Map
                ? (map['breakdown']['distanceMinor'] as num?)
                : null)
            ?.round() ??
            0,
        timeMinor: (map['breakdown'] is Map
                ? (map['breakdown']['timeMinor'] as num?)
                : null)
            ?.round() ??
            0,
        bookingFeeMinor: (map['breakdown'] is Map
                ? (map['breakdown']['bookingFeeMinor'] as num?)
                : null)
            ?.round() ??
            0,
        signedPayload: map['signedPayload'] as String? ?? 'mock-api',
      );
      if (quote.expired) throw StateError('expired quote');
      return quote;
    } catch (error, stack) {
      lastUsedFallback = true;
      AppLog.error(
        'quote.fallback',
        extra: {
          'rideType': rideType,
          'reason': error.toString(),
          'fallback': true,
        },
      );
      AppLog.error('quote.fallback.stack', extra: {'stack': stack.toString()});
      return fallback.quote(
        rideType: rideType,
        distanceMeters: distanceMeters,
        pickup: pickup,
        destination: destination,
      );
    }
  }
}
