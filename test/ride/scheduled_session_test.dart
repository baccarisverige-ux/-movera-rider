import 'package:flutter_test/flutter_test.dart';
import 'package:movera_rider/features/scheduled_rides/application/scheduled_rides_controller.dart';

void main() {
  test('scheduled session owns route time note payment and ids', () {
    final session = ScheduledRideSession();
    session.captureRoute(
      pickup: 'Current location',
      dropoff: 'Stockholm Central Station',
      stops: ['Odenplan'],
    );
    session.captureSchedule(DateTime(2026, 9, 13, 10, 30));
    session.captureNote('Ring the bell');
    session.capturePayment('Cash');
    session.captureRideType('movera', quoteId: 'q_sched_1');
    expect(session.pickup, 'Current location');
    expect(session.dropoff, 'Stockholm Central Station');
    expect(session.stops, ['Odenplan']);
    expect(session.scheduledAt, DateTime(2026, 9, 13, 10, 30));
    expect(session.timezone, 'Europe/Stockholm');
    expect(session.note, 'Ring the bell');
    expect(session.paymentMethod, 'Cash');
    expect(session.rideType, 'movera');
    expect(session.quoteId, 'q_sched_1');
    expect(session.bookingId, isNull);
  });
}
