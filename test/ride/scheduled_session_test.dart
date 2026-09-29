import 'package:flutter_test/flutter_test.dart';
import 'package:movera_rider/features/scheduled_rides/application/scheduled_rides_controller.dart';
import 'package:movera_rider/features/scheduled_rides/application/stockholm_schedule.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('scheduled session owns route time note payment and ids', () {
    final session = ScheduledRideSession();
    session.captureRoute(
      pickup: 'Current location',
      dropoff: 'Stockholm Central Station',
      stops: ['Odenplan'],
    );
    // Derived from the pickup rules, not a calendar date. A hardcoded
    // 2026-09-23 passed until that day arrived, after which captureSchedule
    // correctly clamped it to now+30 and this test failed for a reason that
    // had nothing to do with the session it is testing.
    final when = StockholmSchedule.roundToFive(
      StockholmSchedule.stockholmNow().add(const Duration(days: 7)),
    );
    session.captureSchedule(when, timezone: 'Europe/Stockholm');
    session.captureNote('Ring the bell');
    session.capturePayment('Cash');
    session.captureRideType('movera');
    expect(session.pickup, 'Current location');
    expect(session.dropoff, 'Stockholm Central Station');
    expect(session.stops, ['Odenplan']);
    expect(session.scheduledAt, when);
    expect(session.timezone, 'Europe/Stockholm');
    expect(session.note, 'Ring the bell');
    expect(session.paymentMethod, 'Cash');
    expect(session.rideType, 'movera');
    expect(session.quoteId, 'q_sched_movera');
    expect(session.bookingId, isNull);
  });

  test('captureSchedule clamps a past pickup to Stockholm now+30', () {
    final session = ScheduledRideSession();
    // Likewise relative: this one has to stay in the past to exercise the
    // clamp, which a fixed date only guarantees by luck.
    session.captureSchedule(
      StockholmSchedule.stockholmNow().subtract(const Duration(days: 1)),
    );
    expect(session.scheduledAt, isNotNull);
    expect(StockholmSchedule.isLegalPickup(session.scheduledAt!), isTrue);
    expect(session.scheduledAt, StockholmSchedule.minimumPickup());
  });

  test('confirm writes booking id onto the session', () async {
    final session = ScheduledRideSession();
    session.captureRoute(
      pickup: 'Current location',
      dropoff: 'Stockholm Central Station',
      stops: const [],
    );
    session.captureSchedule(
      StockholmSchedule.roundToFive(
        StockholmSchedule.stockholmNow().add(const Duration(days: 7)),
      ),
    );
    session.capturePayment('Wallet');
    session.captureRideType('movera', quoteId: 'q_sched_1');
    final id = await session.confirm(book: () async => 'b_sched_1');
    expect(id, 'b_sched_1');
    expect(session.bookingId, 'b_sched_1');
    expect(session.quoteId, 'q_sched_1');
    expect(session.submissionStatus, 'confirmed');
  });
}
