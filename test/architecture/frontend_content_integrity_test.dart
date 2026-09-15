import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('production frontend contains no known fabricated customer content', () {
    final source = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .map((file) => file.readAsStringSync())
        .join('\n')
        .toLowerCase();

    const banned = [
      'club vista mare',
      'jvc dubai',
      'dubai - united arab',
      r'$7.00',
      'bmw x7',
      '10 jun 25',
      '2 days 2hrs',
      'skypulse',
      'placeholder terms for the prototype',
    ];
    for (final value in banned) {
      expect(
        source,
        isNot(contains(value)),
        reason: 'Found fabricated frontend content: $value',
      );
    }
  });

  test('unused legacy scheduled-ride surfaces stay removed', () {
    const removed = [
      'lib/features/scheduled_rides/data/scheduled_rides_repository.dart',
      'lib/features/history/data/scheduled_ride_cards.dart',
      'lib/features/history/presentation/my_rides.dart',
      'lib/features/history/presentation/my_rides_requests.dart',
      'lib/features/history/presentation/my_rides_confirmed.dart',
    ];
    for (final path in removed) {
      expect(File(path).existsSync(), isFalse, reason: 'Legacy file returned');
    }
  });

  test('scheduled route summary reads the captured rider route', () {
    final source = File(
      'lib/features/scheduled_rides/presentation/schedule_ride.dart',
    ).readAsStringSync();
    expect(source, contains('location: _session.pickup'));
    expect(source, contains('_session.stops[0]'));
    expect(source, contains('_session.dropoff'));
  });
}
