import 'package:flutter_test/flutter_test.dart';
import 'package:movera_rider/features/ride_selection/application/ride_selection_controller.dart';
import 'package:movera_rider/features/ride_selection/domain/booking_mode.dart';
import 'package:movera_rider/features/support/application/support_controller.dart';

void main() {
  test('ride catalog has seven Movera types', () {
    expect(RideSelectionController().rides().length, 7);
    expect(RideSelectionController().payments().length, 7);
  });

  test('book now and book later share the same seven categories', () {
    final now = RideSelectionController(bookingMode: BookingMode.now);
    final later = RideSelectionController(bookingMode: BookingMode.scheduled);
    expect(now.rides().map((ride) => ride.id).toList(), [
      'movera',
      'comfort',
      'premium',
      'priority',
      'xl',
      'electric',
      'pet',
    ]);
    expect(
      later.rides().map((ride) => ride.id),
      now.rides().map((ride) => ride.id),
    );
  });

  test('support rides catalog is six trips', () {
    expect(SupportController().rides().length, 6);
  });
}
