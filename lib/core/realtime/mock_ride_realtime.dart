import 'dart:async';

import 'package:movera_rider/core/realtime/realtime_connection.dart';
import 'package:movera_rider/core/realtime/ride_realtime.dart';
import 'package:movera_rider/features/ride_booking/domain/ride_status.dart';

/// Mock transport. Emits driver_assigned at [assignAfter] (~12s in product).
class MockRideRealtime implements RideRealtime {
  MockRideRealtime({
    this.assignAfter = const Duration(seconds: 12),
    RealtimeConnection? connection,
  }) : connection = connection ?? RealtimeConnection();

  final Duration assignAfter;
  final RealtimeConnection connection;
  final _controller = StreamController<RideRealtimeEvent>.broadcast();
  Timer? _assign;
  String? _rideId;
  int _sequence = 0;
  bool cancelled = false;
  RideStatus lastStatus = RideStatus.findingDriver;

  @override
  Stream<RideRealtimeEvent> subscribe(String rideId) {
    unsubscribe();
    cancelled = false;
    _rideId = rideId;
    _sequence = 0;
    lastStatus = RideStatus.findingDriver;
    connection.markConnected();
    _emit(RideStatus.findingDriver);
    _assign = Timer(assignAfter, () {
      if (cancelled || _rideId != rideId) return;
      lastStatus = RideStatus.driverAssigned;
      _emit(RideStatus.driverAssigned);
    });
    return _controller.stream;
  }

  void emit(RideStatus status, {int? sequence}) {
    if (_rideId == null) return;
    _sequence = sequence ?? _sequence + 1;
    lastStatus = status;
    _controller.add(
      RideRealtimeEvent(
        rideId: _rideId!,
        status: status,
        sequence: _sequence,
        at: DateTime.now(),
      ),
    );
  }

  void _emit(RideStatus status) => emit(status);

  @override
  Future<void> reconnectAndResync(String rideId) async {
    connection.state = RealtimeState.reconnecting;
    await Future<void>.delayed(connection.nextBackoff());
    connection.markConnected();
    if (_rideId == rideId && !cancelled) {
      _emit(lastStatus);
    }
  }

  @override
  void unsubscribe() {
    cancelled = true;
    _assign?.cancel();
    _assign = null;
  }

  @override
  void dispose() {
    unsubscribe();
    _controller.close();
  }
}
