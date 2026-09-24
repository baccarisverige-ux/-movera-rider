import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

Future<String> _normalize(
  String address,
  Duration delay,
  List<String> started,
  List<String> completed,
) async {
  started.add(address);
  await Future<void>.delayed(delay);
  completed.add(address);
  return 'normalized:$address';
}

void main() {
  test('57B normalizes pickup destination and stops concurrently', () async {
    final started = <String>[];
    final completed = <String>[];

    final futures = <Future<String>>[
      _normalize('pickup', const Duration(milliseconds: 80), started, completed),
      _normalize(
        'destination',
        const Duration(milliseconds: 70),
        started,
        completed,
      ),
      _normalize('stop-1', const Duration(milliseconds: 60), started, completed),
      _normalize('stop-2', const Duration(milliseconds: 50), started, completed),
    ];

    expect(
      started,
      const ['pickup', 'destination', 'stop-1', 'stop-2'],
      reason:
          'all route normalization work must be launched before any individual result is awaited',
    );

    final watch = Stopwatch()..start();
    final normalized = await Future.wait(futures);
    watch.stop();

    expect(
      normalized,
      const [
        'normalized:pickup',
        'normalized:destination',
        'normalized:stop-1',
        'normalized:stop-2',
      ],
    );
    expect(completed.toSet(), {'pickup', 'destination', 'stop-1', 'stop-2'});
    expect(
      watch.elapsedMilliseconds,
      lessThan(150),
      reason:
          'parallel route preparation should be bounded by the slowest geocode, not the sum of all geocodes',
    );
  });
}
