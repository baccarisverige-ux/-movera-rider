import 'dart:async';
import 'dart:math';

import 'package:movera_rider/core/api/api_client.dart';
import 'package:movera_rider/core/realtime/realtime_connection.dart';
import 'package:movera_rider/core/realtime/ride_realtime.dart';
import 'package:movera_rider/features/finding_driver/domain/driver_eta.dart';
import 'package:movera_rider/features/ride_booking/domain/entities/matched_driver.dart';
import 'package:movera_rider/features/ride_booking/domain/ride_status.dart';

/// Mock matching transport. Assignment is an event, not a widget timer.
class MockRideRealtime implements RideRealtime {
  MockRideRealtime({
    this.assignAfter = const Duration(seconds: 25),
    RealtimeConnection? connection,
    this.api,
  }) : connection = connection ?? RealtimeConnection();

  final Duration assignAfter;
  final RealtimeConnection connection;
  final ApiClient? api;
  final _controller = StreamController<RideRealtimeEvent>.broadcast();
  Timer? _assign;
  Timer? _gps;
  String? _rideId;
  int _sequence = 0;
  bool cancelled = false;
  bool disposed = false;
  bool held = false;
  RideStatus lastStatus = RideStatus.findingDriver;
  MatchedDriver? lastDriver;
  double? lastLat;
  double? lastLng;
  DateTime? lastLocationAt;
  double? _pickupLat;
  double? _pickupLng;
  double _progress = 0;

  static const mockDriver = MatchedDriver(
    id: 'drv_mock_linnea',
    firstName: 'Linnea',
    rating: 4.97,
    tripCount: 1842,
    vehicleMake: 'Volvo',
    vehicleModel: 'XC60',
    vehicleColor: 'Black',
    plate: 'MVR 418',
    photoAsset: 'assets/images/profile_img.png',
    vehicleImageAsset: 'assets/images/comfort_ride.png',
  );

  @override
  Stream<RideRealtimeEvent> subscribe(String rideId) {
    if (_rideId == rideId && !disposed && lastStatus.isMatched) {
      return _controller.stream;
    }
    _assign?.cancel();
    _gps?.cancel();
    cancelled = false;
    disposed = false;
    held = false;
    _rideId = rideId;
    _sequence = 0;
    lastStatus = RideStatus.findingDriver;
    lastDriver = null;
    lastLat = null;
    lastLng = null;
    lastLocationAt = null;
    _progress = 0;
    connection.markConnected();
    _emit(RideStatus.findingDriver);
    _assign = Timer(assignAfter, () {
      if (cancelled || disposed || held || _rideId != rideId) return;
      assignNow();
    });
    return _controller.stream;
  }

  void holdAssignment() {
    held = true;
    _assign?.cancel();
    _assign = null;
  }

  void assignNow() {
    if (cancelled || disposed || _rideId == null) return;
    if (lastStatus.isMatched) {
      _emit(lastStatus);
      return;
    }
    _assign?.cancel();
    _assign = null;
    lastDriver = mockDriver;
    lastStatus = RideStatus.driverAssigned;
    _pickupLat ??= 59.3293;
    _pickupLng ??= 18.0686;
    lastLat ??= _pickupLat! + 0.0072;
    lastLng ??= _pickupLng! - 0.0048;
    lastLocationAt = DateTime.now();
    _emit(RideStatus.driverAssigned);
    _startGps();
    _hydratePickup();
    _persistAssigned();
  }

  void emit(
    RideStatus status, {
    int? sequence,
    MatchedDriver? driver,
    double? latitude,
    double? longitude,
    int? etaSeconds,
  }) {
    if (_rideId == null || disposed) return;
    _sequence = sequence ?? _sequence + 1;
    lastStatus = status;
    if (driver != null) lastDriver = driver;
    if (latitude != null) lastLat = latitude;
    if (longitude != null) lastLng = longitude;
    if (latitude != null || longitude != null) lastLocationAt = DateTime.now();
    _controller.add(
      RideRealtimeEvent(
        rideId: _rideId!,
        status: status,
        sequence: _sequence,
        at: DateTime.now(),
        driver: lastDriver,
        latitude: lastLat,
        longitude: lastLng,
        etaSeconds: etaSeconds,
        locationAt: lastLocationAt,
      ),
    );
  }

  void _emit(RideStatus status) {
    final eta = _etaSeconds();
    emit(status, etaSeconds: eta);
  }

  Future<void> _hydratePickup() async {
    final pickup = await _pickup();
    _pickupLat = pickup.$1;
    _pickupLng = pickup.$2;
  }

  void _startGps() {
    _gps?.cancel();
    _gps = Timer.periodic(const Duration(seconds: 3), (_) {
      if (cancelled || disposed || !lastStatus.isMatched) return;
      _progress = min(1, _progress + 0.12);
      final pickupLat = _pickupLat;
      final pickupLng = _pickupLng;
      if (pickupLat == null || pickupLng == null || lastLat == null || lastLng == null) {
        return;
      }
      lastLat = lastLat! + (pickupLat - lastLat!) * 0.18;
      lastLng = lastLng! + (pickupLng - lastLng!) * 0.18;
      lastLocationAt = DateTime.now();
      var status = RideStatus.driverArriving;
      final distance = DriverEta.metersBetween(lastLat!, lastLng!, pickupLat, pickupLng);
      if (distance < 50) {
        status = RideStatus.driverWaiting;
      }
      lastStatus = status;
      _emit(status);
    });
  }

  int? _etaSeconds() {
    final lat = lastLat;
    final lng = lastLng;
    final pickupLat = _pickupLat;
    final pickupLng = _pickupLng;
    if (lat == null || lng == null || pickupLat == null || pickupLng == null) {
      return null;
    }
    return DriverEta.secondsForDistance(
      DriverEta.metersBetween(lat, lng, pickupLat, pickupLng),
    );
  }

  Future<(double, double)> _pickup() async {
    final client = api;
    final id = _rideId;
    if (client != null && id != null) {
      try {
        final json = await client.get('/api/v1/rides/$id');
        final ride = json['ride'];
        if (ride is Map) {
          final lat = (ride['pickupLat'] as num?)?.toDouble();
          final lng = (ride['pickupLng'] as num?)?.toDouble();
          if (lat != null && lng != null) return (lat, lng);
        }
      } catch (_) {}
    }
    return (59.3293, 18.0686);
  }

  Future<void> _persistAssigned() async {
    final client = api;
    final id = _rideId;
    if (client == null || id == null) return;
    try {
      await client.post(
        '/api/v1/rides/$id/status',
        body: {
          'status': lastStatus.name,
          'driver': lastDriver?.toJson(),
          'lat': lastLat,
          'lng': lastLng,
        },
      );
    } catch (_) {}
  }

  @override
  Future<void> reconnectAndResync(String rideId) async {
    connection.state = RealtimeState.reconnecting;
    await Future<void>.delayed(connection.nextBackoff());
    connection.markConnected();
    var status = lastStatus;
    final client = api;
    if (client != null) {
      try {
        final json = await client.get('/api/v1/rides/$rideId');
        final raw = json['ride'];
        if (raw is Map && raw['status'] is String) {
          status = RideStatus.values.firstWhere(
            (value) => value.name == raw['status'],
            orElse: () => status,
          );
          lastDriver = MatchedDriver.fromJson(
            raw['driver'] is Map
                ? Map<String, dynamic>.from(raw['driver'] as Map)
                : null,
          ) ??
              lastDriver;
        }
      } catch (_) {}
    }
    lastStatus = status;
    if (!cancelled && !disposed) _emit(status);
  }

  @override
  void unsubscribe() {
    _assign?.cancel();
    _assign = null;
  }

  @override
  void cancelRide() {
    cancelled = true;
    _gps?.cancel();
    unsubscribe();
  }

  @override
  void dispose() {
    disposed = true;
    cancelled = true;
    _gps?.cancel();
    unsubscribe();
    if (!_controller.isClosed) _controller.close();
  }
}
