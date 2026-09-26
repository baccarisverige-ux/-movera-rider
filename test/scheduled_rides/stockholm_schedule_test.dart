import 'package:flutter_test/flutter_test.dart';
import 'package:movera_rider/features/scheduled_rides/application/scheduled_rides_controller.dart';
import 'package:movera_rider/features/scheduled_rides/application/stockholm_schedule.dart';

void main() {
  // 2026-09-14 06:07 UTC = 08:07 Europe/Stockholm (CEST).
  final utc = DateTime.utc(2026, 9, 14, 6, 7);
  final minSlot = DateTime(2026, 9, 14, 8, 40);

  test('past input clamps to Stockholm now+30 rounded to 5', () {
    final past = DateTime(2026, 9, 13, 22, 35);
    expect(StockholmSchedule.clampPickup(past, utc), minSlot);
    expect(StockholmSchedule.isLegalPickup(past, utc), isFalse);
  });

  test('now+30 default is Stockholm now plus lead, rounded to 5', () {
    expect(StockholmSchedule.leadMinutes, 30);
    expect(StockholmSchedule.stockholmNow(utc), DateTime(2026, 9, 14, 8, 7));
    expect(StockholmSchedule.defaultPickup(utc), minSlot);
    expect(StockholmSchedule.minimumPickup(utc), minSlot);
  });

  test('Continue reject predicate is isLegalPickup', () {
    expect(StockholmSchedule.isLegalPickup(minSlot, utc), isTrue);
    expect(
      StockholmSchedule.isLegalPickup(
        minSlot.subtract(const Duration(minutes: 1)),
        utc,
      ),
      isFalse,
    );
    expect(
      StockholmSchedule.isLegalPickup(DateTime(2026, 9, 13, 22, 35), utc),
      isFalse,
    );
    expect(
      StockholmSchedule.isLegalPickup(DateTime(2026, 9, 23, 6, 55), utc),
      isTrue,
    );
  });

  test('future slots are left unchanged', () {
    final future = DateTime(2026, 9, 23, 6, 55);
    expect(StockholmSchedule.clampPickup(future, utc), future);
  });

  test('today time picker min is now+30; later days start at midnight', () {
    expect(
      StockholmSchedule.timePickerMinFor(DateTime(2026, 9, 14, 22, 35), utc),
      minSlot,
    );
    expect(
      StockholmSchedule.timePickerMinFor(DateTime(2026, 9, 15), utc),
      DateTime(2026, 9, 15),
    );
  });

  test('captureSchedule clamps stale scheduledAt', () {
    final session = ScheduledRideSession();
    session.captureSchedule(DateTime(2020, 1, 1, 12, 0));
    expect(session.scheduledAt, isNotNull);
    expect(StockholmSchedule.isLegalPickup(session.scheduledAt!), isTrue);
    expect(session.scheduledAt, StockholmSchedule.minimumPickup());
  });

  
}
