import 'package:flutter_test/flutter_test.dart';
import 'package:movera_rider/features/finding_driver/domain/search_copy.dart';

void main() {
  test('finding does not enter delayed phase before sixty seconds', () {
    for (final seconds in [0, 1, 2, 19, 20, 32, 59]) {
      expect(
        SearchCopy.isDelayed(seconds),
        isFalse,
        reason: '$seconds seconds',
      );
    }
  });

  test('waiting copy is used from twenty through fifty-nine seconds', () {
    expect(
      SearchCopy.forElapsed(20).headline,
      SearchCopy.waiting.first.headline,
    );
    expect(
      SearchCopy.delayed.any(
        (copy) => copy.headline == SearchCopy.forElapsed(59).headline,
      ),
      isFalse,
    );
  });

  test('finding enters delayed phase at sixty seconds', () {
    expect(SearchCopy.isDelayed(60), isTrue);
    expect(
      SearchCopy.forElapsed(60).headline,
      SearchCopy.delayed.first.headline,
    );
  });
}
