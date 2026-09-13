import 'package:flutter_test/flutter_test.dart';
import 'package:movera_rider/features/finding_driver/domain/cancellation_reason.dart';

void main() {
  test('searching reasons stay optional and movera-worded', () {
    final reasons = CancellationReason.forPhase(CancelPhase.searching);
    expect(reasons.map((r) => r.id), containsAll(['wait_too_long', 'pickup_incorrect']));
    expect(reasons.map((r) => r.label).join(' '), isNot(contains('Selected wrong pickup')));
    expect(reasons, isNot(contains(CancellationReason.driverNotSuitable)));
  });

  test('matched reasons include driver details and drop search-only items', () {
    final reasons = CancellationReason.forPhase(CancelPhase.matched);
    expect(reasons.map((r) => r.id), contains('driver_not_suitable'));
    expect(reasons.map((r) => r.id), isNot(contains('wait_too_long')));
    expect(reasons.map((r) => r.id), isNot(contains('wrong_ride_option')));
  });

  test('keep vs cancel outcomes', () {
    expect(const CancelOutcome.keep().cancelled, isFalse);
    expect(const CancelOutcome.cancel(reasonId: 'plans_changed').reasonId, 'plans_changed');
  });
}
