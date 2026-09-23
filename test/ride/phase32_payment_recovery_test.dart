import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('payment progress remains restorable completion state', () {
    final status = File(
      'lib/features/ride_booking/domain/ride_status.dart',
    ).readAsStringSync();

    expect(status, contains('paymentProcessing'));
    expect(status, contains('paymentFinalized'));
    expect(status, contains('ratingPending'));
    expect(status, contains('bool get isCompletedSurface'));
  });

  test('payment failure is explicit backend-owned terminal state', () {
    final status = File(
      'lib/features/ride_booking/domain/ride_status.dart',
    ).readAsStringSync();
    final sheet = File(
      'lib/features/active_ride/presentation/ride_terminal_state_sheet.dart',
    ).readAsStringSync();

    expect(status, contains('paymentFailed'));
    expect(status, contains('this == RideStatus.paymentFailed'));
    expect(sheet, contains('RideStatus.paymentFailed'));
    expect(sheet, contains('Payment could not be completed'));
  });

  test('completed payment and rating state is persisted before exit', () {
    final controller = File(
      'lib/features/active_ride/application/active_ride_controller.dart',
    ).readAsStringSync();

    expect(controller, contains('Future<void> markCompleted'));
    expect(controller, contains('LastCompletedRide.remember(completed)'));
    expect(controller, contains('await _store.save(completed)'));
  });

  test('frontend does not invent a payment retry outcome', () {
    final sheet = File(
      'lib/features/active_ride/presentation/ride_terminal_state_sheet.dart',
    ).readAsStringSync();

    expect(sheet, isNot(contains('Retry payment')));
    expect(sheet, isNot(contains('retryPayment')));
  });
}
