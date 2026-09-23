import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('receipt remains data-backed and does not fabricate trip details', () {
    final receipt = File(
      'lib/features/ride_complete/presentation/trip_detail.dart',
    ).readAsStringSync();

    expect(receipt, contains('(controller ?? RideCompleteController()).receipt()'));
    expect(receipt, contains('Trip details unavailable'));
    expect(receipt, isNot(contains("pickup: '")));
  });

  test('dispute mutation is backend-owned and idempotent', () {
    final dispute = File(
      'lib/features/ride_complete/data/ride_dispute_repository.dart',
    ).readAsStringSync();

    expect(dispute, contains("MutationAttempt('ride-dispute')"));
    expect(dispute, contains("'/api/v1/rides/\$id/disputes'"));
    expect(dispute, contains('idempotencyKey: _mutation.keyFor(intent)'));
    expect(dispute, contains('_mutation.succeeded(intent)'));
  });

  test('dev transport exposes the same dispute contract', () {
    final mock = File(
      'lib/core/api/in_process_mock_client.dart',
    ).readAsStringSync();

    expect(mock, contains("parts.last == 'disputes'"));
    expect(mock, contains("'status': 'submitted'"));
    expect(mock, contains("'code': 'INVALID_DISPUTE'"));
  });
}
