import 'dart:async';

import 'package:movera_rider/app/di.dart';
import 'package:movera_rider/core/analytics/analytics.dart';
import 'package:movera_rider/core/api/api_client.dart';
import 'package:movera_rider/core/api/idempotency.dart';
import 'package:movera_rider/core/logging/app_log.dart';
import 'package:movera_rider/core/realtime/ride_realtime.dart';
import 'package:movera_rider/features/finding_driver/data/finding_driver_repository.dart';
import 'package:movera_rider/features/ride_booking/application/ride_session.dart';
import 'package:movera_rider/features/ride_booking/data/ride_snapshot_store.dart';
import 'package:movera_rider/features/ride_booking/domain/ride_status.dart';

class FindingDriverController {
  FindingDriverController({
    FindingDriverRepository? store,
    RideRealtime? realtime,
    RideSession? ride,
    ApiClient? api,
  })  : _store = store ?? FindingDriverRepository(),
        _realtime = realtime ?? AppScope.instance.rideRealtime,
        _ride = ride,
        _api = api;

  final FindingDriverRepository _store;
  final RideRealtime _realtime;
  final RideSession? _ride;
  final ApiClient? _api;
  Timer? _tick;
  StreamSubscription<RideRealtimeEvent>? _sub;
  bool _assigned = false;
  bool _cancelled = false;
  bool _disposed = false;
  int _lastSequence = -1;
  RideSnapshot? _snapshot;
  void Function()? _onMatched;
  int timeoutLogs = 0;

  RideSession get ride => _ride ?? AppScope.instance.ride;
  ApiClient get api => _api ?? AppScope.instance.api;

  int get matchCount => _assigned ? 1 : 0;

  void startFrom({
    required String pickupAddress,
    required String destinationAddress,
    required double pickupLat,
    required double pickupLng,
    required double destinationLat,
    required double destinationLng,
    required String rideType,
    required double price,
    required String paymentMethod,
    required void Function(int remaining) onTick,
    required void Function() onMatched,
  }) {
    start(
      seconds: 12,
      snapshot: RideSnapshot(
        status: RideStatus.findingDriver,
        savedAt: DateTime.now(),
        pickupAddress: pickupAddress,
        destinationAddress: destinationAddress,
        pickupLat: pickupLat,
        pickupLng: pickupLng,
        destinationLat: destinationLat,
        destinationLng: destinationLng,
        rideType: rideType,
        price: price,
        paymentMethod: paymentMethod,
        rideId: ride.rideId,
      ),
      onTick: onTick,
      onMatched: onMatched,
    );
  }

  void start({
    required int seconds,
    required RideSnapshot snapshot,
    required void Function(int remaining) onTick,
    required void Function() onMatched,
  }) {
    _snapshot = snapshot;
    _onMatched = onMatched;
    _assigned = false;
    _cancelled = false;
    _disposed = false;
    _lastSequence = -1;
    ride.restoreFromBackend(RideStatus.findingDriver);
    var remaining = seconds;
    _tick?.cancel();
    _sub?.cancel();
    _tick = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_disposed) {
        timer.cancel();
        return;
      }
      if (remaining > 0) {
        remaining -= 1;
        onTick(remaining);
      } else {
        timer.cancel();
        if (!_assigned && !_cancelled) {
          timeoutLogs += 1;
          AppLog.info(
            'ride.finding.no_driver',
            extra: {'rideId': snapshot.rideId, 'seconds': seconds},
          );
        }
      }
    });
    final rideId = snapshot.rideId ?? ride.rideId ?? 'ride';
    _sub = _realtime.subscribe(rideId).listen((event) {
      if (_disposed || _cancelled) return;
      if (event.sequence < _lastSequence) return;
      if (_assigned && event.status == RideStatus.driverAssigned) return;
      _lastSequence = event.sequence;
      if (event.status == RideStatus.driverAssigned) {
        _completeAssigned();
      }
    });
  }

  void _completeAssigned() {
    if (_assigned || _cancelled || _disposed) return;
    _assigned = true;
    final snapshot = _snapshot;
    ride.restoreFromBackend(RideStatus.driverAssigned);
    Analytics.driverFound(rideId: ride.rideId);
    final id = ride.rideId;
    if (id != null) {
      try {
        api.post(
          '/api/v1/rides/$id/status',
          body: {'status': RideStatus.driverAssigned.name},
          idempotencyKey: newIdempotencyKey('ride-status'),
        );
      } catch (_) {}
    }
    if (snapshot != null) {
      _store.save(
        RideSnapshot(
          status: RideStatus.driverAssigned,
          savedAt: DateTime.now(),
          pickupAddress: snapshot.pickupAddress,
          destinationAddress: snapshot.destinationAddress,
          pickupLat: snapshot.pickupLat,
          pickupLng: snapshot.pickupLng,
          destinationLat: snapshot.destinationLat,
          destinationLng: snapshot.destinationLng,
          rideType: snapshot.rideType,
          price: snapshot.price,
          paymentMethod: snapshot.paymentMethod,
          rideId: ride.rideId,
        ),
      );
    }
    _onMatched?.call();
  }

  void cancelSearch() {
    _cancelled = true;
    Analytics.rideCancelled();
    ride.restoreFromBackend(RideStatus.cancelledByRider);
    _store.clear();
    _realtime.unsubscribe();
  }

  Future<void> resync() async {
    final id = _snapshot?.rideId;
    if (id == null || _cancelled || _disposed) return;
    await _realtime.reconnectAndResync(id);
  }

  void dispose() {
    _disposed = true;
    _tick?.cancel();
    _sub?.cancel();
    _realtime.unsubscribe();
  }
}
