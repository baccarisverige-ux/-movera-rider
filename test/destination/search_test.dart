import 'package:flutter_test/flutter_test.dart';
import 'package:movera_rider/core/location/place_search.dart';

void main() {
  test('place search keeps the latest generation', () async {
    final search = PlaceSearchService(delay: const Duration(milliseconds: 1));
    search.query('a', (_, __) {});
    var latest = '';
    search.query('ab', (text, generation) {
      if (search.isCurrent(generation)) latest = text;
    });
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(latest, 'ab');
    search.dispose();
  });
}
