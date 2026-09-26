import 'dart:async';

import 'package:movera_rider/core/api/api_client.dart';
import 'package:movera_rider/core/realtime/ride_realtime.dart';
import 'package:movera_rider/features/ride_booking/domain/entities/matched_driver.dart';
import 'package:movera_rider/features/ride_booking/domain/ride_status.dart';

/// Backend-backed polling transport used by staging/production until the
/// websocket transport is connected. It never fabricates rider->driver signals.
class ApiRideRealtime implements RideRealtime {
  ApiRideRealtime({
    required ApiClient api,
    this.pollInterval = const Duration(seconds: 2),
  }) : _api = api;

  final ApiClient _api;
  final Duration pollInterval;

  StreamController<RideRealtimeEvent>? _controller;
  Timer? _timer;
  String? _rideId;
  int _sequence = 0;
  bool _disposed = false;

  @override
  bool get supportsRiderSignals => false;

  @override
  Stream<RideRealtimeEvent> subscribe(String rideId) {
    unsubscribe();
    _rideId = rideId;
    _controller = StreamController<RideRealtimeEvent>.broadcast(
      onCancel: () {
        if (_controller?.hasListener != true) {
          _timer?.cancel();
          _timer = null;
        }
      },
    );
    unawaited(_poll());
    _timer = Timer.periodic(pollInterval, (_) => unawaited(_poll()));
    return _controller!.stream;
  }

  Future<void> _poll() async {
    final id = _rideId;
    final controller = _controller;
    if (_disposed || id == null || controller == null || controller.isClosed) {
      return;
    }
    final json = await _api.get('/api/v1/rides/$id');
    final rawRide = json['ride'];
    if (rawRide is! Map) return;
    final ride = Map<String, dynamic>.from(rawRide);
    final rawStatus = '${ride['status'] ?? ''}';
    final status = RideStatus.values.firstWhere(
      (value) => value.name == rawStatus,
      orElse: () => RideStatus.findingDriver,
    );
    final rawDriver = ride['driver'];
    final driver = rawDriver is Map
        ? MatchedDriver.fromJson(Map<String, dynamic>.from(rawDriver))
        : null;
    _sequence += 1;
    if (!controller.isClosed) {
      controller.add(
        RideRealtimeEvent(
          rideId: id,
          status: status,
          sequence: _sequence,
          serverTime: DateTime.now().toUtc(),
          driver: driver,
          latitude: (ride['driverLat'] as num?)?.toDouble(),
          longitude: (ride['driverLng'] as num?)?.toDouble(),
        ),
      );
    }
  }

  @override
  Future<void> reconnectAndResync(String rideId) async {
    _rideId = rideId;
    await _poll();
  }

  @override
  Future<void> sendSignal({
    required String rideId,
    required RideRealtimeSignal signal,
    String? message,
  }) {
    throw UnsupportedError(
      'Rider signals are not available on the polling transport.',
    );
  }

  @override
  void unsubscribe() {
    _timer?.cancel();
    _timer = null;
    final controller = _controller;
    _controller = null;
    _rideId = null;
    if (controller != null && !controller.isClosed) {
      unawaited(controller.close());
    }
  }

  @override
  void cancelRide() {
    unsubscribe();
  }

  @override
  void researchAfterDriverCancel() {
    if (_rideId != null) unawaited(_poll());
  }

  @override
  void dispose() {
    _disposed = true;
    unsubscribe();
  }
}
