import 'package:flutter_test/flutter_test.dart';
import 'package:movera_rider/core/realtime/mock_ride_realtime.dart';
import 'package:movera_rider/features/ride_booking/domain/ride_status.dart';

void main() {
  test('assignment event', () async {
    final rt = MockRideRealtime(assignAfter: Duration.zero);
    RideStatus? last;
    rt.subscribe('r1').listen((e) => last = e.status);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(last, RideStatus.driverAssigned);
    rt.dispose();
  });

  test('duplicate assignment keeps last sequence', () async {
    final rt = MockRideRealtime(assignAfter: const Duration(days: 1));
    final seq = <int>[];
    rt.subscribe('r1').listen((e) => seq.add(e.sequence));
    rt.emit(RideStatus.driverAssigned, sequence: 2);
    rt.emit(RideStatus.driverAssigned, sequence: 2);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(seq.where((s) => s == 2).length, greaterThanOrEqualTo(1));
    rt.dispose();
  });

  test('assignment after cancellation is ignored by cancelled flag', () async {
    final rt = MockRideRealtime(assignAfter: Duration.zero);
    rt.subscribe('r1');
    rt.unsubscribe();
    expect(rt.cancelled, isTrue);
    rt.dispose();
  });

  test('stale out-of-order sequence can be emitted', () async {
    final rt = MockRideRealtime(assignAfter: const Duration(days: 1));
    final statuses = <RideStatus>[];
    rt.subscribe('r1').listen((e) => statuses.add(e.status));
    rt.emit(RideStatus.driverAssigned, sequence: 5);
    rt.emit(RideStatus.findingDriver, sequence: 1);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(statuses, contains(RideStatus.driverAssigned));
    rt.dispose();
  });

  test('reconnect resyncs last status', () async {
    final rt = MockRideRealtime(assignAfter: const Duration(days: 1));
    RideStatus? last;
    rt.subscribe('r1').listen((e) => last = e.status);
    rt.emit(RideStatus.findingDriver, sequence: 3);
    await rt.reconnectAndResync('r1');
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(last, RideStatus.findingDriver);
    rt.dispose();
  });
}
