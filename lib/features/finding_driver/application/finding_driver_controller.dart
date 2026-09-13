import 'dart:async';
import 'dart:convert';

import 'package:movera_rider/app/di.dart';
import 'package:movera_rider/core/analytics/analytics.dart';
import 'package:movera_rider/core/api/api_client.dart';
import 'package:movera_rider/core/api/idempotency.dart';
import 'package:movera_rider/core/debug/web_qa_hooks.dart';
import 'package:movera_rider/core/logging/app_log.dart';
import 'package:movera_rider/core/realtime/mock_ride_realtime.dart';
import 'package:movera_rider/core/realtime/ride_realtime.dart';
import 'package:movera_rider/features/finding_driver/data/finding_driver_repository.dart';
import 'package:movera_rider/features/finding_driver/domain/nearby_vehicle.dart';
import 'package:movera_rider/features/finding_driver/domain/search_copy.dart';
import 'package:movera_rider/features/ride_booking/application/ride_session.dart';
import 'package:movera_rider/features/ride_booking/data/ride_snapshot_store.dart';
import 'package:movera_rider/features/ride_booking/domain/entities/matched_driver.dart';
import 'package:movera_rider/features/ride_booking/domain/ride_notes.dart';
import 'package:movera_rider/features/ride_booking/domain/ride_status.dart';

class FindingDriverController {
  FindingDriverController({
    FindingDriverRepository? store,
    RideRealtime? realtime,
    RideSession? ride,
    ApiClient? api,
    this.delayedAfter = SearchCopy.delayedAfter,
  }) : _store = store ?? FindingDriverRepository(),
       _realtime = realtime ?? AppScope.instance.rideRealtime,
       _ride = ride,
       _api = api;

  static FindingDriverController? active;

  final FindingDriverRepository _store;
  final RideRealtime _realtime;
  final RideSession? _ride;
  final ApiClient? _api;
  final Duration delayedAfter;
  Timer? _tick;
  StreamSubscription<RideRealtimeEvent>? _sub;
  bool _assigned = false;
  bool _cancelled = false;
  bool _disposed = false;
  bool _delayedLogged = false;
  bool _bumpDismissed = false;
  bool _priceUpdated = false;
  int _lastSequence = -1;
  RideSnapshot? _snapshot;
  void Function()? _onMatched;
  void Function(int elapsed)? _onTick;
  int timeoutLogs = 0;
  int elapsedSeconds = 0;
  String? offerConfirmation;
  MatchedDriver? matchedDriver;
  List<NearbyVehicle> nearby = const [];

  RideSession get ride => _ride ?? AppScope.instance.ride;
  ApiClient get api => _api ?? AppScope.instance.api;

  int get matchCount => _assigned ? 1 : 0;
  bool get isDelayed => elapsedSeconds >= delayedAfter.inSeconds;
  bool get showPriceBump =>
      isDelayed && !_bumpDismissed && !_assigned && !_cancelled;
  double get currentPrice => _snapshot?.price ?? 0;
  SearchCopy get copy => SearchCopy.forElapsed(elapsedSeconds);

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
    RideNotes notes = RideNotes.empty,
    required void Function(int elapsed) onTick,
    required void Function() onMatched,
  }) {
    start(
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
        notes: notes,
      ),
      onTick: onTick,
      onMatched: onMatched,
    );
  }

  void start({
    int seconds = 12,
    required RideSnapshot snapshot,
    required void Function(int elapsed) onTick,
    required void Function() onMatched,
  }) {
    active = this;
    _snapshot = snapshot;
    _onMatched = onMatched;
    _onTick = onTick;
    _assigned = false;
    _cancelled = false;
    _disposed = false;
    _delayedLogged = false;
    _bumpDismissed = false;
    _priceUpdated = false;
    _lastSequence = -1;
    elapsedSeconds = 0;
    if (seconds < 0) {
      elapsedSeconds = 0;
    }
    timeoutLogs = 0;
    offerConfirmation = null;
    matchedDriver = snapshot.driver;
    ride.restoreFromBackend(RideStatus.findingDriver);
    _tick?.cancel();
    _sub?.cancel();
    _evaluatePhase();
    _onTick?.call(elapsedSeconds);
    _tick = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_disposed || _assigned || _cancelled) {
        timer.cancel();
        return;
      }
      elapsedSeconds += 1;
      _evaluatePhase();
      _onTick?.call(elapsedSeconds);
    });
    final rideId = snapshot.rideId ?? ride.rideId ?? 'ride';
    _sub = _realtime.subscribe(rideId).listen((event) {
      if (_disposed || _cancelled) return;
      if (event.sequence < _lastSequence) return;
      if (_assigned && event.status == RideStatus.driverAssigned) return;
      _lastSequence = event.sequence;
      if (event.driver != null) matchedDriver = event.driver;
      if (event.status == RideStatus.driverAssigned || event.status.isMatched) {
        _completeAssigned();
      }
    });
    _loadNearby(rideId);
    installMatchingQaHooks(
      hold: () {
        final realtime = _realtime;
        if (realtime is MockRideRealtime) realtime.holdAssignment();
      },
      assign: () {
        final realtime = _realtime;
        if (realtime is MockRideRealtime) realtime.assignNow();
      },
      advance: debugAdvance,
    );
    _reportQa();
  }

  void debugAdvance(int seconds) {
    if (_disposed || _assigned || _cancelled) return;
    elapsedSeconds += seconds;
    _evaluatePhase();
    _onTick?.call(elapsedSeconds);
    _reportQa();
  }

  void _evaluatePhase() {
    if (_assigned || _cancelled || _disposed) return;
    if (!isDelayed) return;
    if (!_delayedLogged) {
      _delayedLogged = true;
      timeoutLogs += 1;
      ride.restoreFromBackend(RideStatus.searchDelayed);
      final snapshot = _snapshot;
      if (snapshot != null) {
        _store.save(
          snapshot.copyWith(
            status: RideStatus.searchDelayed,
            savedAt: DateTime.now(),
          ),
        );
      }
      AppLog.info(
        'ride.finding.delayed',
        extra: {'rideId': _snapshot?.rideId, 'elapsed': elapsedSeconds},
      );
    }
    _reportQa();
  }

  Future<void> _loadNearby(String rideId) async {
    try {
      final json = await api.get('/api/v1/rides/$rideId/nearby');
      final raw = json['vehicles'];
      if (raw is! List) return;
      nearby = raw
          .whereType<Map>()
          .map(
            (item) => NearbyVehicle.fromJson(Map<String, dynamic>.from(item)),
          )
          .whereType<NearbyVehicle>()
          .toList();
      if (_disposed) return;
      _onTick?.call(elapsedSeconds);
    } catch (_) {
      nearby = const [];
    }
  }

  Future<bool> confirmPriceIncrease(int kr) async {
    if (_assigned || _cancelled || _disposed || kr <= 0) return false;
    final snapshot = _snapshot;
    final id = snapshot?.rideId ?? ride.rideId;
    if (snapshot == null || id == null) return false;
    final next = snapshot.price + kr;
    try {
      await api.patch(
        '/api/v1/rides/$id',
        body: {'price': next, 'offerIncreaseKr': kr},
        idempotencyKey: newIdempotencyKey('ride-price'),
      );
    } catch (_) {
      return false;
    }
    _priceUpdated = true;
    _bumpDismissed = true;
    offerConfirmation = 'Updated offer: ${next.round()} kr';
    _snapshot = snapshot.copyWith(price: next, savedAt: DateTime.now());
    ride.restoreFromBackend(RideStatus.findingDriver, id: id);
    await _store.save(_snapshot!);
    AppLog.info('ride.offer.updated', extra: {'rideId': id, 'increaseKr': kr});
    _onTick?.call(elapsedSeconds);
    _reportQa();
    return true;
  }

  void dismissPriceBump() {
    _bumpDismissed = true;
    _onTick?.call(elapsedSeconds);
    _reportQa();
  }

  void _completeAssigned() {
    if (_assigned || _cancelled || _disposed) return;
    _assigned = true;
    final snapshot = _snapshot;
    ride.restoreFromBackend(RideStatus.driverAssigned);
    Analytics.driverFound(rideId: ride.rideId);
    if (snapshot != null) {
      _store.save(
        snapshot.copyWith(
          status: RideStatus.driverAssigned,
          savedAt: DateTime.now(),
          rideId: ride.rideId,
          driver: matchedDriver,
        ),
      );
    }
    _reportQa();
    _onMatched?.call();
  }

  Future<void> cancelSearch({String? reasonId}) async {
    if (_cancelled || _disposed) return;
    _cancelled = true;
    _tick?.cancel();
    _tick = null;
    _sub?.cancel();
    _sub = null;
    Analytics.rideCancelled(rideId: ride.rideId);
    if (reasonId != null) {
      AppLog.info(
        'ride.cancelled',
        extra: {'reason': reasonId, 'rideId': ride.rideId},
      );
    }
    ride.restoreFromBackend(RideStatus.cancelledByRider);
    final id = _snapshot?.rideId ?? ride.rideId;
    await _store.clear();
    _realtime.cancelRide();
    if (id != null) {
      unawaited(_cancelViaAdapter(id, reasonId));
    }
  }

  Future<void> _cancelViaAdapter(String id, String? reasonId) async {
    try {
      await api.post(
        '/api/v1/rides/$id/cancel',
        body: {if (reasonId != null) 'reason': reasonId},
        idempotencyKey: newIdempotencyKey('ride-cancel'),
      );
    } catch (error) {
      AppLog.warning(
        'ride.cancel.adapter_failed',
        extra: {'rideId': id, 'error': error.toString()},
      );
    }
  }

  Future<void> resync() async {
    final id = _snapshot?.rideId;
    if (id == null || _cancelled || _disposed) return;
    await _realtime.reconnectAndResync(id);
  }

  Map<String, dynamic> qaSnapshot() => {
    'elapsed': elapsedSeconds,
    'delayed': isDelayed,
    'bumpVisible': showPriceBump,
    'price': currentPrice,
    'priceUpdated': _priceUpdated,
    'headline': copy.headline,
    'rideId': _snapshot?.rideId ?? ride.rideId,
    'assigned': _assigned,
    'offerConfirmation': offerConfirmation,
    'nearby': nearby.length,
  };

  void _reportQa() {
    reportSearchSnapshot(jsonEncode(qaSnapshot()));
  }

  void dispose() {
    _disposed = true;
    if (identical(active, this)) active = null;
    _tick?.cancel();
    _sub?.cancel();
    if (!_assigned) _realtime.unsubscribe();
  }
}
