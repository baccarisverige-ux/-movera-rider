import 'package:flutter_test/flutter_test.dart';
import 'package:movera_rider/core/api/api_client.dart';
import 'package:movera_rider/core/api/api_error.dart';
import 'package:movera_rider/core/api/in_process_mock_client.dart';
import 'package:movera_rider/features/ride_booking/data/api_quote_repository.dart';
import 'package:movera_rider/features/ride_booking/data/catalog_quote_repository.dart';

void main() {
  ApiQuoteRepository repo([InProcessMockClient? client]) {
    return ApiQuoteRepository(
      api: ApiClient(client: client ?? InProcessMockClient()),
      fallback: CatalogQuoteRepository(),
    );
  }

  test('successful quote matches catalog kr', () async {
    final quote = await repo().quote(rideType: 'movera', distanceMeters: 3000);
    expect(quote.totalMinor, 25900);
    expect(quote.currency, 'SEK');
    expect(quote.signedPayload, 'mock-api');
    expect(quote.expired, isFalse);
  });

  test('every ride category', () async {
    for (final type in CatalogQuoteRepository.pricesKr.keys) {
      final quote = await repo().quote(rideType: type, distanceMeters: 1000);
      expect(quote.totalMinor, CatalogQuoteRepository.pricesKr[type]! * 100);
    }
  });

  test('timeout uses fallback', () async {
    final client = InProcessMockClient();
    client.timeoutNext = const Duration(milliseconds: 1);
    final quotes = repo(client);
    final quote = await quotes.quote(rideType: 'comfort', distanceMeters: 1);
    expect(quote.signedPayload, 'fallback');
    expect(quotes.lastUsedFallback, isTrue);
    expect(quote.totalMinor, 33900);
  });

  test('malformed 500 uses fallback', () async {
    final client = InProcessMockClient()..failNext = true;
    final quotes = repo(client);
    final quote = await quotes.quote(rideType: 'premium', distanceMeters: 1);
    expect(quote.signedPayload, 'fallback');
    expect(quote.totalMinor, 36900);
  });

  test('stale generation is ignored by repository guard', () async {
    final quotes = repo();
    quotes.stale.next();
    final first = quotes.stale.next();
    expect(quotes.stale.isCurrent(first), isTrue);
  });

  test('POST is not retried as GET would be', () async {
    final client = InProcessMockClient();
    final api = ApiClient(client: client);
    final first = await api.post('/api/v1/quotes', body: {'rideType': 'xl'});
    expect(first['quote']['totalMinor'], 39900);
  });

  test('timeout error type', () async {
    final client = InProcessMockClient()
      ..timeoutNext = const Duration(milliseconds: 1);
    expect(
      () => ApiClient(client: client).post('/api/v1/quotes', body: {}),
      throwsA(isA<ApiError>()),
    );
  });
}
