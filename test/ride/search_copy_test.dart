import 'package:flutter_test/flutter_test.dart';
import 'package:movera_rider/features/finding_driver/domain/search_copy.dart';

void main() {
  test('phase-local copy at the required elapsed boundaries', () {
    expect(SearchCopy.forElapsed(0).headline, 'Finding your driver');
    expect(SearchCopy.forElapsed(12).headline, 'Checking for nearby drivers');
    expect(SearchCopy.forElapsed(19).headline, 'Checking for nearby drivers');
    expect(SearchCopy.isDelayed(19), isFalse);
    expect(SearchCopy.forElapsed(20).headline, 'Still looking for the best match');
    expect(SearchCopy.forElapsed(24).headline, contains('best match'));
    expect(SearchCopy.isDelayed(59), isFalse);
    expect(SearchCopy.forElapsed(59).headline, 'Still looking for the best match');
    expect(SearchCopy.isDelayed(60), isTrue);
    expect(SearchCopy.forElapsed(60).headline, "It's busier than usual");
    expect(SearchCopy.forElapsed(72).headline, contains('little longer'));
  });

  test('does not promise a guaranteed arrival time', () {
    for (final bucket in [SearchCopy.initial, SearchCopy.waiting, SearchCopy.delayed]) {
      for (final copy in bucket) {
        expect(copy.headline.toLowerCase(), isNot(contains('1 minute')));
        expect(copy.subtitle.toLowerCase(), isNot(contains('guaranteed')));
      }
    }
  });
}
