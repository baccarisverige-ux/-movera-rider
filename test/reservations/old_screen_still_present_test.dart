import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:movera_rider/features/scheduled_rides/presentation/ride_confirmed.dart';
import 'package:movera_rider/features/scheduled_rides/presentation/ride_pending.dart';

void main() {
  test('old confirmation screens stay reachable during migration', () {
    expect(
      File(
        'lib/features/scheduled_rides/presentation/ride_confirmed.dart',
      ).existsSync(),
      isTrue,
    );
    expect(
      File(
        'lib/features/scheduled_rides/presentation/ride_pending.dart',
      ).existsSync(),
      isTrue,
    );
    expect(
      File(
        'lib/features/scheduled_rides/presentation/confirm_booking.dart',
      ).existsSync(),
      isTrue,
    );
    expect(const ScheduleRideConfirmed(), isA<ScheduleRideConfirmed>());
    expect(const ScheduleRidePending(), isA<ScheduleRidePending>());
  });
}
