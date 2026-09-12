import 'package:flutter_test/flutter_test.dart';
import 'package:movera_rider/core/maps/geo_point.dart';
import 'package:movera_rider/core/motion/interpolator.dart';

void main() {
  test('progress is 0 at start and 1 after window', () {
    final interpolator = PositionInterpolator();
    final start = DateTime(2026, 1, 1, 12);
    final from = const GeoPoint(59.33, 18.06);
    final to = const GeoPoint(59.34, 18.07);
    final first = interpolator.lerp(
      from: from,
      to: to,
      fromHeading: 0,
      toHeading: 10,
      startedAt: start,
      now: start,
      window: const Duration(milliseconds: 400),
    );
    expect(first.progress, 0);
    final last = interpolator.lerp(
      from: from,
      to: to,
      fromHeading: 0,
      toHeading: 10,
      startedAt: start,
      now: start.add(const Duration(milliseconds: 400)),
      window: const Duration(milliseconds: 400),
    );
    expect(last.progress, 1);
    expect(last.heading, 10);
  });
}
