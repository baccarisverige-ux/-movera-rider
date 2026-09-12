import 'dart:async';

import 'package:movera_rider/app/di.dart';
import 'package:movera_rider/core/analytics/analytics.dart';
import 'package:movera_rider/core/realtime/ride_realtime.dart';
import 'package:movera_rider/features/finding_driver/data/finding_driver_repository.dart';
import 'package:movera_rider/features/ride_booking/data/ride_snapshot_store.dart';
import 'package:movera_rider/features/ride_booking/domain/ride_status.dart';

class FindingDriverController {
  FindingDriverController({
    FindingDriverRepository? store,
    RideRealtime? realtime,
  })  : _store = store ?? FindingDriverRepository(),
        _realtime = realtime ?? AppScope.instance.rideRealtime;

  final FindingDriverRepository _store;
  final RideRealtime _realtime;
  Timer? _tick;
  StreamSubscription<RideRealtimeEvent>? _sub;
  bool _assigned = false;
  bool _cancelled = false;
  int _lastSequence = -1;
  RideSnapshot? _snapshot;

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
        rideId: AppScope.instance.ride.rideId,
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
    _assigned = false;
    _cancelled = false;
    _lastSequence = -1;
    AppScope.instance.ride.restoreFromBackend(RideStatus.findingDriver);
    var remaining = seconds;
    _tick?.cancel();
    _sub?.cancel();
    _tick = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remaining > 0) {
        remaining -= 1;
        onTick(remaining);
      } else {
        timer.cancel();
      }
    });
    final rideId = snapshot.rideId ?? AppScope.instance.ride.rideId ?? 'ride';
    _sub = _realtime.subscribe(rideId).listen((event) {
      if (_cancelled) return;
      if (event.sequence < _lastSequence) return;
      if (event.sequence == _lastSequence &&
          event.status == RideStatus.driverAssigned &&
          _assigned) {
        return;
      }
      _lastSequence = event.sequence;
      if (event.status == RideStatus.driverAssigned) {
        _completeAssigned(onMatched);
      }
    });
  }

  void _completeAssigned(void Function() onMatched) {
    if (_assigned || _cancelled) return;
    _assigned = true;
    final snapshot = _snapshot;
    AppScope.instance.ride.restoreFromBackend(RideStatus.driverAssigned);
    Analytics.driverFound(rideId: AppScope.instance.ride.rideId);
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
          rideId: AppScope.instance.ride.rideId,
        ),
      );
    }
    onMatched();
  }

  void cancelSearch() {
    _cancelled = true;
    Analytics.rideCancelled();
    AppScope.instance.ride.restoreFromBackend(RideStatus.cancelledByRider);
    _store.clear();
    _realtime.unsubscribe();
  }

  Future<void> resync() async {
    final id = _snapshot?.rideId;
    if (id == null || _cancelled) return;
    await _realtime.reconnectAndResync(id);
  }

  void dispose() {
    _tick?.cancel();
    _sub?.cancel();
    _realtime.unsubscribe();
  }
}
