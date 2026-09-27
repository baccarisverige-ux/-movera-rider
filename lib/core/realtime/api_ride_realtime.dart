import 'dart:async';

import 'package:movera_rider/core/api/api_client.dart';
import 'package:movera_rider/core/logging/app_log.dart';
import 'package:movera_rider/core/realtime/realtime_connection.dart';
import 'package:movera_rider/core/realtime/ride_realtime.dart';
import 'package:movera_rider/features/ride_booking/domain/entities/matched_driver.dart';
import 'package:movera_rider/features/ride_booking/domain/ride_status.dart';

/// Polls each active ride once and shares its events across all screen owners.
/// A screen cancelling its subscription cannot disconnect another screen.
class ApiRideRealtime implements RideRealtime {
  ApiRideRealtime({
    required ApiClient api,
    RealtimeConnection? connection,
    this.pollInterval = const Duration(seconds: 2),
  }) : _api = api,
       connection = connection ?? RealtimeConnection();

  final ApiClient _api;
  final RealtimeConnection connection;
  final Duration pollInterval;
  final Map<String, _RidePoll> _rides = {};
  bool _disposed = false;

  @override
  bool get supportsRiderSignals => false;

  @override
  Stream<RideRealtimeEvent> subscribe(String rideId) {
    final id = rideId.trim();
    if (_disposed || id.isEmpty || id == 'ride') {
      throw StateError('A server rideId is required for realtime updates.');
    }
    final poll = _rides.putIfAbsent(id, () => _RidePoll(id));
    poll.controller ??= StreamController<RideRealtimeEvent>.broadcast(
      onListen: () {
        if (poll.timer != null) return;
        connection.state = RealtimeState.connecting;
        unawaited(_poll(poll));
        poll.timer = Timer.periodic(
          pollInterval,
          (_) => unawaited(_poll(poll)),
        );
      },
      onCancel: () {
        poll.timer?.cancel();
        poll.timer = null;
        _rides.remove(id);
        final controller = poll.controller;
        if (controller != null) unawaited(controller.close());
        if (_rides.isEmpty) connection.markDisconnected();
      },
    );
    return poll.controller!.stream;
  }

  Future<void> _poll(_RidePoll poll) async {
    if (_disposed || !_rides.containsKey(poll.id) || poll.inFlight) return;
    poll.inFlight = true;
    try {
      final json = await _api.get('/api/v1/rides/${Uri.encodeComponent(poll.id)}');
      if (_disposed || !identical(_rides[poll.id], poll)) return;
      final rawRide = json['ride'];
      if (rawRide is! Map) throw const FormatException('Missing ride projection');
      final ride = Map<String, dynamic>.from(rawRide);
      final status = _status(ride['status']);
      if (status == null) {
        AppLog.warning('realtime.unknown_status', extra: {
          'rideId': poll.id,
          'status': '${ride['status']}',
        });
        // Keep the last valid state and retry. An unknown backend status is
        // never evidence that a matched ride resumed searching.
        connection.markFailed();
        return;
      }
      final version = _version(ride['version'] ?? json['version']);
      final updatedAt = _date(ride['updatedAt'] ?? json['updatedAt']);
      if (version == null && updatedAt == null) {
        throw const FormatException('Ride projection needs version or updatedAt');
      }
      if (poll.version != null && version != null &&
          version < poll.version!) return;
      // The aggregate version wins over a clock that moves backwards. Within
      // the same version, updatedAt can still order location projections.
      if ((poll.version == null || version == null ||
              version == poll.version) &&
          poll.updatedAt != null && updatedAt != null &&
          updatedAt.isBefore(poll.updatedAt!)) return;
      if (poll.version != null && version == null) {
        // Do not replace a versioned projection with an unversioned response.
        return;
      }
      final rawDriver = ride['driver'];
      final driver = rawDriver is Map
          ? MatchedDriver.fromJson(Map<String, dynamic>.from(rawDriver))
          : null;
      if (poll.version == version && poll.updatedAt == updatedAt &&
          poll.lastStatus == status &&
          poll.lastLat == ride['driverLat'] &&
          poll.lastLng == ride['driverLng']) {
        connection.markConnected();
        return;
      }
      poll.version = version ?? poll.version;
      poll.updatedAt = updatedAt ?? poll.updatedAt;
      poll.lastStatus = status;
      poll.lastLat = ride['driverLat'];
      poll.lastLng = ride['driverLng'];
      poll.sequence++;
      poll.controller?.add(RideRealtimeEvent(
        rideId: poll.id,
        status: status,
        sequence: poll.sequence,
        version: version,
        serverTime: updatedAt,
        driver: driver,
        latitude: (ride['driverLat'] as num?)?.toDouble(),
        longitude: (ride['driverLng'] as num?)?.toDouble(),
        locationAt: _date(ride['locationAt'] ?? ride['driverLocationAt']),
      ));
      connection.markConnected();
    } catch (error) {
      if (!_disposed && identical(_rides[poll.id], poll)) {
        AppLog.warning('realtime.poll_failed', extra: {
          'rideId': poll.id,
          'error': error.toString(),
        });
        connection.markFailed();
      }
    } finally {
      poll.inFlight = false;
    }
  }

  RideStatus? _status(Object? raw) {
    for (final status in RideStatus.values) {
      if (status.name == raw) return status;
    }
    return null;
  }

  int? _version(Object? raw) =>
      raw is int ? raw : (raw is String ? int.tryParse(raw) : null);

  DateTime? _date(Object? raw) =>
      raw is String ? DateTime.tryParse(raw)?.toUtc() : null;

  @override
  Future<void> reconnectAndResync(String rideId) async {
    final poll = _rides[rideId.trim()];
    if (poll == null) return;
    connection.markReconnecting();
    await _poll(poll);
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
    // Legacy callers also cancel their own StreamSubscription. Closing every
    // stream here would disconnect other screens that still own this ride.
  }

  @override
  void cancelRide() {
    for (final poll in _rides.values.toList()) {
      poll.timer?.cancel();
      final controller = poll.controller;
      if (controller != null) unawaited(controller.close());
    }
    _rides.clear();
    connection.markDisconnected();
  }

  @override
  void researchAfterDriverCancel() {
    for (final poll in _rides.values) {
      unawaited(_poll(poll));
    }
  }

  @override
  void dispose() {
    _disposed = true;
    cancelRide();
  }
}

class _RidePoll {
  _RidePoll(this.id);
  final String id;
  StreamController<RideRealtimeEvent>? controller;
  Timer? timer;
  bool inFlight = false;
  int sequence = 0;
  int? version;
  DateTime? updatedAt;
  RideStatus? lastStatus;
  Object? lastLat;
  Object? lastLng;
}
