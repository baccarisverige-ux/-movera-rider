import 'package:flutter_test/flutter_test.dart';
import 'package:movera_rider/core/motion/bearing.dart';

void main() {
  test('0 to 10 is +10', () {
    expect(shortestTurn(0, 10), 10);
  });

  test('350 to 10 crosses zero as +20', () {
    expect(shortestTurn(350, 10), 20);
  });

  test('10 to 350 is -20', () {
    expect(shortestTurn(10, 350), -20);
  });

  test('359 to 1 is +2', () {
    expect(shortestTurn(359, 1), closeTo(2, 0.001));
  });

  test('normalize wraps negatives', () {
    expect(normalizeHeading(-10), 350);
  });
}
