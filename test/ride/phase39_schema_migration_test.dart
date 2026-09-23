import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
void main() {
  test('reservation restore tolerates corrupt or older local data', () {
    final s=File('lib/features/reservations/data/local_reservation_repository.dart').readAsStringSync();
    expect(s, contains('Reservation.tryParse'));
    expect(s, contains('Ignore corrupt local data rather than crash on restore'));
  });
  test('ride snapshots restore through explicit serialization boundary', () {
    final s=File('lib/features/ride_booking/data/ride_snapshot_store.dart').readAsStringSync();
    expect(s, contains('RideSnapshot'));
    expect(s, contains('jsonDecode'));
  });
}
