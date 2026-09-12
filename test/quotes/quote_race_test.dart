import 'package:flutter_test/flutter_test.dart';
import 'package:movera_rider/core/api/api_client.dart';
import 'package:movera_rider/core/api/in_process_mock_client.dart';
import 'package:movera_rider/features/ride_booking/data/api_quote_repository.dart';
import 'package:movera_rider/features/ride_booking/data/catalog_quote_repository.dart';
import 'package:movera_rider/features/ride_booking/data/mock_quote_repository.dart';
import 'package:movera_rider/features/ride_booking/domain/entities/quote.dart';
import 'package:movera_rider/features/ride_selection/application/ride_selection_controller.dart';
import 'package:movera_rider/features/ride_selection/data/ride_selection_repository.dart';

class _SlowThenFast implements QuoteRepository {
  _SlowThenFast(this.fast);
  final QuoteRepository fast;
  int calls = 0;

  @override
  Future<RideQuote> quote({
    required String rideType,
    required int distanceMeters,
    int durationSeconds = 600,
    String? pickup,
    String? destination,
  }) async {
    calls += 1;
    final delay = calls == 1 ? const Duration(milliseconds: 40) : Duration.zero;
    await Future<void>.delayed(delay);
    return RideQuote(
      id: 'q_$calls',
      rideType: rideType,
      totalMinor: calls == 1 ? 11100 : 25900,
      currency: 'SEK',
      expiresAt: DateTime.now().add(const Duration(minutes: 2)),
      signedPayload: 'mock-api',
    );
  }
}

void main() {
  test('quote id equals quoteId', () async {
    final client = InProcessMockClient();
    final api = ApiClient(client: client);
    final json = await api.post('/api/v1/quotes', body: {'rideType': 'movera'});
    expect(json['quote']['id'], json['quote']['quoteId']);
    expect(json['quote']['totalMinor'], 25900);
    expect(json['quote']['currency'], 'SEK');
  });

  test('later quote generation wins', () async {
    final quotes = _SlowThenFast(CatalogQuoteRepository());
    final selection = RideSelectionController(
      store: RideSelectionRepository(),
      quotes: quotes,
    );
    final first = selection.beginQuotes();
    final firstLoad = selection.loadQuotes(
      generation: first,
      pickup: 'A',
      destination: 'B',
    );
    await Future<void>.delayed(const Duration(milliseconds: 5));
    final second = selection.beginQuotes();
    final secondLoad = selection.loadQuotes(
      generation: second,
      pickup: 'A',
      destination: 'C',
    );
    await Future.wait([firstLoad, secondLoad]);
    expect(selection.offeredPrices['movera'], 259);
  });

  test('api quote repository parses mock contract', () async {
    final repo = ApiQuoteRepository(
      api: ApiClient(client: InProcessMockClient()),
      fallback: CatalogQuoteRepository(),
    );
    final quote = await repo.quote(
      rideType: 'xl',
      distanceMeters: 3000,
      pickup: 'A',
      destination: 'B',
    );
    expect(quote.id.startsWith('q_xl_'), isTrue);
    expect(quote.signedPayload, 'mock-api');
  });
}
