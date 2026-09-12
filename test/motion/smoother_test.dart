import 'package:flutter_test/flutter_test.dart';
import 'package:movera_rider/core/location/location_point.dart';
import 'package:movera_rider/core/maps/geo_point.dart';
import 'package:movera_rider/core/motion/location_smoother.dart';
import 'package:movera_rider/core/utils/stale_guard.dart';

void main() {
  test('drops impossible speed', () {
    final smoother = LocationSmoother();
    final first = LocationPoint(
      point: const GeoPoint(59.33, 18.06),
      timestamp: DateTime(2026, 1, 1, 12),
      speedMps: 1,
    );
    smoother.accept(first);
    final jump = LocationPoint(
      point: const GeoPoint(60.33, 19.06),
      timestamp: DateTime(2026, 1, 1, 12, 0, 1),
      speedMps: 90,
    );
    expect(smoother.accept(jump)?.point.latitude, 59.33);
  });

  test('stale guard ignores old generation', () {
    final guard = StaleGuard();
    final first = guard.next();
    final second = guard.next();
    expect(guard.isCurrent(first), isFalse);
    expect(guard.isCurrent(second), isTrue);
    guard.dispose();
    expect(guard.isCurrent(second), isFalse);
  });
}
