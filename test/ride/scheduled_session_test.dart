import 'package:flutter_test/flutter_test.dart';
import 'package:movera_rider/features/scheduled_rides/application/scheduled_rides_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('scheduled session owns route time note payment and ids', () {
    final session = ScheduledRideSession();
    session.captureRoute(
      pickup: 'Current location',
      dropoff: 'Stockholm Central Station',
      stops: ['Odenplan'],
    );
    session.captureSchedule(
      DateTime(2026, 9, 13, 10, 30),
      timezone: 'Europe/Stockholm',
    );
    session.captureNote('Ring the bell');
    session.capturePayment('Cash');
    session.captureRideType('movera');
    expect(session.pickup, 'Current location');
    expect(session.dropoff, 'Stockholm Central Station');
    expect(session.stops, ['Odenplan']);
    expect(session.scheduledAt, DateTime(2026, 9, 13, 10, 30));
    expect(session.timezone, 'Europe/Stockholm');
    expect(session.note, 'Ring the bell');
    expect(session.paymentMethod, 'Cash');
    expect(session.rideType, 'movera');
    expect(session.quoteId, 'q_sched_movera');
    expect(session.bookingId, isNull);
  });

  test('confirm writes booking id onto the session', () async {
    final session = ScheduledRideSession();
    session.captureRoute(
      pickup: 'Current location',
      dropoff: 'Stockholm Central Station',
      stops: const [],
    );
    session.captureSchedule(DateTime(2026, 9, 13, 10, 30));
    session.capturePayment('Wallet');
    session.captureRideType('movera', quoteId: 'q_sched_1');
    final id = await session.confirm(book: () async => 'b_sched_1');
    expect(id, 'b_sched_1');
    expect(session.bookingId, 'b_sched_1');
    expect(session.quoteId, 'q_sched_1');
    expect(session.submissionStatus, 'confirmed');
  });
}
