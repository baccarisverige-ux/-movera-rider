import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('scheduled ride UI contains no unpublished assignment or fare guarantee', () {
    final history = File(
      'lib/features/history/presentation/ride_history.dart',
    ).readAsStringSync();
    final policy = File(
      'lib/features/reservations/data/reservation_policy_catalog.dart',
    ).readAsStringSync();

    expect(history.contains('lock in your fare'), isFalse);
    expect(history.contains('a driver will meet you'), isFalse);
    expect(policy.contains('A driver is assigned closer to pickup'), isFalse);
    expect(
      policy.contains('applied according to Movera rules at the time a driver is assigned'),
      isFalse,
    );
    expect(policy.contains('Assignment timing is not published yet'), isTrue);
  });

  test('scheduled session does not fabricate a quote id', () {
    final session = File(
      'lib/features/scheduled_rides/application/scheduled_rides_controller.dart',
    ).readAsStringSync();

    expect(session.contains("q_sched_"), isFalse);
    expect(session.contains('quoteId ?? this.quoteId'), isTrue);
  });
}
