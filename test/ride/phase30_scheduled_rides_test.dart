import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('scheduled booking never indexes an empty payment catalog', () {
    final source = File(
      'lib/features/ride_selection/application/scheduled_ride_booking.dart',
    ).readAsStringSync();

    expect(source, contains('selection.selectedPaymentItem()'));
    expect(
      source,
      contains("StateError('scheduled booking needs an available payment method')"),
    );
    expect(
      source,
      isNot(contains('payments[selection.selectedPayment.clamp')),
    );
  });

  test('scheduled checkout and booking share the same payment invariant', () {
    final booking = File(
      'lib/features/ride_selection/application/scheduled_ride_booking.dart',
    ).readAsStringSync();
    final checkout = File(
      'lib/features/reservations/application/scheduled_ride_checkout.dart',
    ).readAsStringSync();

    expect(booking, contains('selection.selectedPaymentItem()'));
    expect(checkout, contains('selection.selectedPaymentItem()'));
    expect(
      checkout,
      contains("StateError('scheduled checkout needs an available payment method')"),
    );
  });
}
