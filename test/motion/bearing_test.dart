import 'package:flutter_test/flutter_test.dart';
import 'package:movera_rider/core/motion/bearing.dart';
import 'package:movera_rider/core/motion/interpolator.dart';
import 'package:movera_rider/core/maps/geo_point.dart';

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

  test('1 to 359 is -2', () {
    expect(shortestTurn(1, 359), closeTo(-2, 0.001));
  });

  test('normalize wraps negatives', () {
    expect(normalizeHeading(-10), 350);
  });

  test('blend 350 toward 10 steps through 0', () {
    final next = blendHeading(350, 10);
    expect(shortestTurn(350, next), greaterThan(0));
    expect(next, greaterThan(350));
    expect(next, lessThan(360));
  });

  test('lerp heading 359 to 1 at t=1 is 1', () {
    expect(lerpHeading(359, 1, 1), closeTo(1, 0.01));
  });

  test('time based interpolation is Hz independent', () {
    final lerp = PositionInterpolator();
    final start = DateTime(2026, 1, 1, 12);
    final a = lerp.lerp(
      from: const GeoPoint(59.33, 18.06),
      to: const GeoPoint(59.34, 18.07),
      fromHeading: 0,
      toHeading: 10,
      startedAt: start,
      now: start.add(const Duration(milliseconds: 210)),
      window: const Duration(milliseconds: 420),
    );
    expect(a.progress, closeTo(0.5, 0.02));
  });
}
