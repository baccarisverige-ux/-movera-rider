import 'dart:async';
import 'dart:convert';

import 'package:movera_rider/app/di.dart';
import 'package:movera_rider/app/router/ride_navigator.dart';
import 'package:movera_rider/core/analytics/analytics.dart';
import 'package:movera_rider/core/api/api_client.dart';
import 'package:movera_rider/core/api/mutation_attempt.dart';
import 'package:movera_rider/core/debug/web_qa_hooks.dart';
import 'package:movera_rider/core/logging/app_log.dart';
import 'package:movera_rider/core/realtime/mock_ride_realtime.dart';
import 'package:movera_rider/core/realtime/ride_realtime.dart';
import 'package:movera_rider/features/fare/domain/fare_rules.dart';
import 'package:movera_rider/features/finding_driver/data/finding_driver_repository.dart';
import 'package:movera_rider/features/finding_driver/domain/nearby_vehicle.dart';
import 'package:movera_rider/features/finding_driver/domain/search_copy.dart';
import 'package:movera_rider/features/history/data/on_demand_ride_history_store.dart';
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
  final MutationAttempt _pickupMutation = MutationAttempt('ride-pickup');
  final MutationAttempt _priceMutation = MutationAttempt('ride-price');
  final MutationAttempt _cancelMutation = MutationAttempt('ride-cancel');
  Timer? _tick;
  StreamSubscription<RideRealtimeEvent>? _sub;
  bool _assigned = false;
  bool _cancelled = false;
  bool _terminated = false;
  bool _disposed = false;
  bool _delayedLogged = false;
  bool _bumpDismissed = false;
  bool _priceUpdated = false;
  bool _editInFlight = false;
  bool _assignmentPending = false;
  int _lastSequence = -1;
  int _nearbyRequestEpoch = 0;
  int _pickupUpdateEpoch = 0;
  int _editEpoch = 0;
  RideSnapshot? _snapshot;
  double? _catalogPrice;
  void Function()? _onMatched;
  void Function(RideStatus status)? _onTerminal;
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
      isDelayed &&
      !_bumpDismissed &&
      !_assigned &&
      !_assignmentPending &&
      !_editInFlight &&
      !_cancelled &&
      !_terminated;
  double get currentPrice => _snapshot?.price ?? 0;
  double get maxOfferPrice =>
      FareRules.maximum(_catalogPrice ?? currentPrice);
  String get pickupAddress => _snapshot?.pickupAddress ?? '';
  double? get pickupLat => _snapshot?.pickupLat;
  double? get pickupLng => _snapshot?.pickupLng;
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
    void Function(RideStatus status)? onTerminal,
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
      onTerminal: onTerminal,
    );
  }

  void start({
    int seconds = 12,
    required RideSnapshot snapshot,
    required void Function(int elapsed) onTick,
    required void Function() onMatched,
    void Function(RideStatus status)? onTerminal,
  }) {
    active = this;
    _snapshot = snapshot;
    _catalogPrice = snapshot.price;
    _onMatched = onMatched;
    _onTerminal = onTerminal;
    _onTick = onTick;
    _assigned = false;
    _cancelled = false;
    _terminated = false;
    _disposed = false;
    _delayedLogged = false;
    _bumpDismissed = false;
    _priceUpdated = false;
    _editInFlight = false;
    _assignmentPending = false;
    _lastSequence = -1;
    _nearbyRequestEpoch += 1;
    _pickupUpdateEpoch += 1;
    _editEpoch += 1;
    elapsedSeconds = 0;
    if (seconds < 0) {
      elapsedSeconds = 0;
    }
    timeoutLogs = 0;
    offerConfirmation = null;
    matchedDriver = snapshot.driver;
    nearby = const [];
    if (ride.status != snapshot.status || ride.rideId != snapshot.rideId) {
      ride.backendReconcile(snapshot.status, id: snapshot.rideId);
    }
    _tick?.cancel();
    _sub?.cancel();
    _evaluatePhase();
    _onTick?.call(elapsedSeconds);
    _tick = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_disposed || _assigned || _cancelled || _terminated) {
        timer.cancel();
        return;
      }
      elapsedSeconds += 1;
      _evaluatePhase();
      _onTick?.call(elapsedSeconds);
    });
    final rideId = snapshot.rideId ?? ride.rideId ?? 'ride';
    _sub = _realtime.subscribe(rideId).listen((event) {
      if (_disposed || _cancelled || _terminated) return;
      if (event.sequence < _lastSequence) return;
      if (_assigned && event.status == RideStatus.driverAssigned) return;
      _lastSequence = event.sequence;
      if (event.driver != null) matchedDriver = event.driver;

      final accepted = ride.backendReconcile(
        event.status,
        id: event.tripId,
        version: event.version ?? event.sequence,
        updatedAt: event.serverTime ?? event.occurredAt,
      );
      if (!accepted && event.status != ride.status) return;

      if (event.status.isTerminal) {
        unawaited(_completeTerminal(event.status));
        return;
      }
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
    if (_disposed || _assigned || _cancelled || _terminated) return;
    elapsedSeconds += seconds;
    _evaluatePhase();
    _onTick?.call(elapsedSeconds);
    _reportQa();
  }

  void _evaluatePhase() {
    if (_assigned || _cancelled || _terminated || _disposed) return;
    if (!isDelayed) return;
    if (!_delayedLogged) {
      _delayedLogged = true;
      timeoutLogs += 1;
      if (ride.status == RideStatus.findingDriver) {
        ride.localTransition(RideStatus.searchDelayed);
      }
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
    final requestEpoch = ++_nearbyRequestEpoch;
    try {
      final json = await api.get('/api/v1/rides/$rideId/nearby');
      if (_disposed ||
          _assigned ||
          _assignmentPending ||
          _cancelled ||
          _terminated ||
          requestEpoch != _nearbyRequestEpoch) {
        return;
      }
      final raw = json['vehicles'];
      if (raw is! List) return;
      final nextNearby = raw
          .whereType<Map>()
          .map(
            (item) => NearbyVehicle.fromJson(Map<String, dynamic>.from(item)),
          )
          .whereType<NearbyVehicle>()
          .toList();
      if (_disposed ||
          _assigned ||
          _assignmentPending ||
          _cancelled ||
          _terminated ||
          requestEpoch != _nearbyRequestEpoch) {
        return;
      }
      nearby = nextNearby;
      _onTick?.call(elapsedSeconds);
    } catch (_) {
      if (_disposed ||
          _assigned ||
          _assignmentPending ||
          _cancelled ||
          _terminated ||
          requestEpoch != _nearbyRequestEpoch) {
        return;
      }
      nearby = const [];
      _onTick?.call(elapsedSeconds);
    }
  }

  int? _beginEdit() {
    if (_assigned ||
        _assignmentPending ||
        _editInFlight ||
        _cancelled ||
        _terminated ||
        _disposed) {
      return null;
    }
    _editInFlight = true;
    _editEpoch += 1;
    return _editEpoch;
  }

  bool _editInvalid(int token) =>
      token != _editEpoch || _cancelled || _terminated || _disposed;

  void _finishEdit(int token) {
    if (token == _editEpoch || _editInFlight) {
      _editInFlight = false;
    }
    if (_assignmentPending && !_cancelled && !_terminated && !_disposed) {
      _assignmentPending = false;
      _completeAssigned();
    }
  }

  Future<bool> updatePickup({
    required String address,
    required double latitude,
    required double longitude,
  }) async {
    final snapshot = _snapshot;
    final id = snapshot?.rideId ?? ride.rideId;
    if (snapshot == null || id == null) return false;
    final editToken = _beginEdit();
    if (editToken == null) return false;
    final updateEpoch = ++_pickupUpdateEpoch;
    final intent = jsonEncode({
      'rideId': id,
      'pickupAddress': address,
      'pickupLat': latitude,
      'pickupLng': longitude,
    });
    try {
      await api.patch(
        '/api/v1/rides/$id',
        body: {
          'pickupAddress': address,
          'pickupLat': latitude,
          'pickupLng': longitude,
        },
        idempotencyKey: _pickupMutation.keyFor(intent),
      );
      _pickupMutation.succeeded(intent);
      if (_editInvalid(editToken) || updateEpoch != _pickupUpdateEpoch) {
        return false;
      }
      final updated = snapshot.copyWith(
        status: ride.status,
        savedAt: DateTime.now(),
        pickupAddress: address,
        pickupLat: latitude,
        pickupLng: longitude,
      );
      _snapshot = updated;
      await _store.save(updated);
      if (_editInvalid(editToken) || updateEpoch != _pickupUpdateEpoch) {
        return false;
      }
      if (!_assignmentPending && !_assigned) {
        await _loadNearby(id);
      }
      if (_editInvalid(editToken) || updateEpoch != _pickupUpdateEpoch) {
        return false;
      }
      _onTick?.call(elapsedSeconds);
      _reportQa();
      return true;
    } catch (_) {
      return false;
    } finally {
      _finishEdit(editToken);
    }
  }

  Future<bool> confirmPriceIncrease(int kr) async {
    if (kr <= 0) return false;
    final snapshot = _snapshot;
    final id = snapshot?.rideId ?? ride.rideId;
    if (snapshot == null || id == null) return false;
    final catalog = _catalogPrice ?? snapshot.price;
    final next = snapshot.price + kr;
    if (!FareRules.allowsTotal(total: next, catalog: catalog)) return false;
    final editToken = _beginEdit();
    if (editToken == null) return false;
    final intent = jsonEncode({
      'rideId': id,
      'price': next,
      'offerIncreaseKr': kr,
    });
    try {
      await api.patch(
        '/api/v1/rides/$id',
        body: {'price': next, 'offerIncreaseKr': kr},
        idempotencyKey: _priceMutation.keyFor(intent),
      );
      _priceMutation.succeeded(intent);
      if (_editInvalid(editToken)) return false;
      _priceUpdated = true;
      _bumpDismissed = true;
      offerConfirmation = 'Updated offer: ${next.round()} kr';
      _snapshot = snapshot.copyWith(
        status: ride.status,
        price: next,
        savedAt: DateTime.now(),
      );
      await _store.save(_snapshot!);
      if (_editInvalid(editToken)) return false;
      AppLog.info('ride.offer.updated', extra: {'rideId': id, 'increaseKr': kr});
      _onTick?.call(elapsedSeconds);
      _reportQa();
      return true;
    } catch (_) {
      return false;
    } finally {
      _finishEdit(editToken);
    }
  }

  void dismissPriceBump() {
    if (_terminated) return;
    _bumpDismissed = true;
    _onTick?.call(elapsedSeconds);
    _reportQa();
  }

  void _completeAssigned() {
    if (_assigned || _cancelled || _terminated || _disposed) return;
    if (_editInFlight) {
      _assignmentPending = true;
      return;
    }
    _assignmentPending = false;
    _assigned = true;
    _nearbyRequestEpoch += 1;
    _pickupUpdateEpoch += 1;
    final snapshot = _snapshot;
    final matched = _onMatched;
    if (_cancelled || _terminated || _disposed) return;
    Analytics.driverFound(rideId: ride.rideId);
    if (_cancelled || _disposed) {
      if (!ride.status.isTerminal) {
        ride.localTransition(RideStatus.cancelledByRider);
      }
      unawaited(_store.clear());
      return;
    }
    if (_terminated) return;
    unawaited(_persistAssigned(snapshot, matched));
  }

  Future<void> _persistAssigned(
    RideSnapshot? snapshot,
    void Function()? matched,
  ) async {
    if (snapshot != null) {
      await _store.save(
        snapshot.copyWith(
          status: ride.status.isMatched
              ? ride.status
              : RideStatus.driverAssigned,
          savedAt: DateTime.now(),
          rideId: ride.rideId,
          driver: matchedDriver,
        ),
      );
    }
    if (_terminated) {
      await _store.clear();
      return;
    }
    if (_cancelled || _disposed) {
      if (!ride.status.isTerminal) {
        ride.localTransition(RideStatus.cancelledByRider);
      }
      await _store.clear();
      return;
    }
    _reportQa();
    matched?.call();
  }

  Future<void> _completeTerminal(RideStatus status) async {
    if (_terminated || _cancelled || _disposed || !status.isTerminal) return;
    _terminated = true;
    _assignmentPending = false;
    _editEpoch += 1;
    _nearbyRequestEpoch += 1;
    _pickupUpdateEpoch += 1;
    _onMatched = null;
    _tick?.cancel();
    _tick = null;
    await _sub?.cancel();
    _sub = null;
    final snapshot = _snapshot;
    if (snapshot != null &&
        (status == RideStatus.cancelledByDriver ||
            status == RideStatus.cancelledBySystem)) {
      try {
        await OnDemandRideHistoryStore.archive(
          snapshot,
          terminalStatus: status,
        );
      } catch (_) {}
    }
    await _store.clear();
    _reportQa();
    if (_disposed) return;
    final callback = _onTerminal;
    if (callback != null) {
      callback(status);
    } else {
      RideNavigator.home(null, status: status);
    }
  }

  Future<void> cancelSearch({String? reasonId}) async {
    if (_cancelled || _terminated || _disposed) return;
    _cancelled = true;
    _assignmentPending = false;
    _editEpoch += 1;
    _nearbyRequestEpoch += 1;
    _pickupUpdateEpoch += 1;
    _onMatched = null;
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
    if (!ride.status.isTerminal) {
      ride.localTransition(RideStatus.cancelledByRider);
    }
    final id = _snapshot?.rideId ?? ride.rideId;
    await OnDemandRideHistoryStore.archiveCancelledThenClear(
      snapshot: _snapshot,
      reasonId: reasonId,
    );
    _realtime.cancelRide();
    if (id != null) {
      unawaited(_cancelViaAdapter(id, reasonId));
    }
  }

  Future<void> _cancelViaAdapter(String id, String? reasonId) async {
    final intent = jsonEncode({'rideId': id, 'reasonId': reasonId});
    try {
      await api.post(
        '/api/v1/rides/$id/cancel',
        body: {if (reasonId != null) 'reason': reasonId},
        idempotencyKey: _cancelMutation.keyFor(intent),
      );
      _cancelMutation.succeeded(intent);
    } catch (error) {
      AppLog.warning(
        'ride.cancel.adapter_failed',
        extra: {'rideId': id, 'error': error.toString()},
      );
    }
  }

  Future<void> resync() async {
    final id = _snapshot?.rideId;
    if (id == null || _cancelled || _terminated || _disposed) return;
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
    'assignmentPending': _assignmentPending,
    'editInFlight': _editInFlight,
    'terminated': _terminated,
    'status': ride.status.name,
    'offerConfirmation': offerConfirmation,
    'nearby': nearby.length,
    'pickupAddress': _snapshot?.pickupAddress,
    'pickupLat': _snapshot?.pickupLat,
    'pickupLng': _snapshot?.pickupLng,
  };

  void _reportQa() {
    reportSearchSnapshot(jsonEncode(qaSnapshot()));
  }

  void dispose() {
    _disposed = true;
    _assignmentPending = false;
    _editEpoch += 1;
    _nearbyRequestEpoch += 1;
    _pickupUpdateEpoch += 1;
    if (identical(active, this)) active = null;
    _tick?.cancel();
    _sub?.cancel();
    if (!_assigned) _realtime.unsubscribe();
  }
}
