import 'dart:async';

import 'package:movera_rider/app/di.dart';
import 'package:movera_rider/core/realtime/ride_realtime.dart';
import 'package:movera_rider/features/finding_driver/domain/driver_eta.dart';
import 'package:movera_rider/features/ride_booking/application/ride_session.dart';
import 'package:movera_rider/features/ride_booking/data/ride_snapshot_store.dart';
import 'package:movera_rider/features/ride_booking/domain/entities/matched_driver.dart';
import 'package:movera_rider/features/ride_booking/domain/ride_status.dart';

class DriverTrackingController {
  DriverTrackingController({
    RideRealtime? realtime,
    required this.pickupLat,
    required this.pickupLng,
    this.destinationLat,
    this.destinationLng,
    this.persistRideSnapshot = true,
    RideSession? ride,
  })  : _realtime = realtime ?? AppScope.instance.rideRealtime,
        _ride = ride;

  final RideRealtime _realtime;
  final RideSession? _ride;
  final bool persistRideSnapshot;
  final double pickupLat;
  final double pickupLng;
  final double? destinationLat;
  final double? destinationLng;
  StreamSubscription<RideRealtimeEvent>? _sub;
  Timer? _staleCheck;
  MatchedDriver? driver;
  DriverEta? eta;
  RideStatus status = RideStatus.driverAssigned;
  RideRealtimeSignal? lastSignal;
  String? signalMessage;
  RideStatus? _lastPersistedStatus;
  void Function()? onChange;

  /// Re-evaluates staleness on a timer, independent of new fixes arriving.
  /// Without this, a marker whose updates simply stopped (a dropped
  /// connection, a crashed driver client) never registers as stale, because
  /// [DriverEta.fromFix] — the only other place staleness is computed — only
  /// runs when an event actually arrives.
  static const _staleCheckInterval = Duration(seconds: 5);

  void start({
    required String rideId,
    MatchedDriver? initial,
    void Function()? onChange,
  }) {
    driver = initial;
    this.onChange = onChange;
    // A fresh subscription is a fresh feed; only its own errors degrade it.
    connectionDegraded = false;
    _sub?.cancel();
    _staleCheck?.cancel();
    _sub = _realtime.subscribe(rideId).listen(
      (event) {
        // A location fix is independently useful even when the status it
        // arrived with is rejected as stale by backendReconcile: dropping the
        // whole event discarded a possibly-newer coordinate along with a
        // status the app had already superseded. Only skip the status/signal
        // side when the event is rejected; the position always applies if it
        // is not itself older than what is already tracked.
        final accepted = !persistRideSnapshot ||
            (_ride ?? AppScope.instance.ride).backendReconcile(
              event.status,
              id: event.tripId,
              version: event.version ?? event.sequence,
              updatedAt: event.serverTime ?? event.occurredAt,
            );
        final statusChanged = accepted && event.status != status;
        if (accepted) {
          status = event.status;
          lastSignal = event.signal;
          signalMessage = event.message;
        }
        if (event.driver != null) driver = event.driver;
        final incomingLocationAt = event.locationAt ?? event.at;
        final currentLocationAt = eta?.locationAt;
        final isNewerFix = currentLocationAt == null ||
            !incomingLocationAt.isBefore(currentLocationAt);
        if (event.latitude != null && event.longitude != null && isNewerFix) {
          eta = DriverEta.fromFix(
            latitude: event.latitude!,
            longitude: event.longitude!,
            pickupLat: pickupLat,
            pickupLng: pickupLng,
            destinationLat: destinationLat,
            destinationLng: destinationLng,
            locationAt: incomingLocationAt,
            etaSeconds: event.etaSeconds,
            status: status,
          );
        } else if (eta != null && eta!.locationAt != null) {
          eta = DriverEta.fromFix(
            latitude: eta!.latitude ?? pickupLat,
            longitude: eta!.longitude ?? pickupLng,
            pickupLat: pickupLat,
            pickupLng: pickupLng,
            destinationLat: destinationLat,
            destinationLng: destinationLng,
            locationAt: eta!.locationAt!,
            etaSeconds: event.etaSeconds ?? eta!.seconds,
            status: status,
          );
        }
        if (statusChanged) {
          unawaited(_persistLiveStatus());
        }
        this.onChange?.call();
      },
      onError: (Object error) {
        connectionDegraded = true;
        this.onChange?.call();
      },
      onDone: () {
        connectionDegraded = true;
        this.onChange?.call();
      },
    );
    unawaited(_persistLiveStatus());
    _staleCheck = Timer.periodic(_staleCheckInterval, (_) {
      final current = eta;
      if (current == null) return;
      final refreshed = current.withStalenessCheckedAt(DateTime.now());
      if (identical(refreshed, current)) return;
      eta = refreshed;
      this.onChange?.call();
    });
  }

  /// Set when the realtime stream itself errors or closes (see M-05). Waiting
  /// renders it as a "live updates paused" banner with a Retry (D-015), so a
  /// dead feed no longer looks like a stationary driver.
  bool connectionDegraded = false;

  Future<void> _persistLiveStatus() async {
    if (!persistRideSnapshot || status.isTerminal) return;
    if (_lastPersistedStatus == status) return;
    final stored = await RideSnapshotStore.read();
    if (stored == null) return;
    _lastPersistedStatus = status;
    await RideSnapshotStore.save(
      stored.copyWith(
        status: status,
        savedAt: DateTime.now(),
        driver: driver ?? stored.driver,
      ),
    );
  }

  void dispose() {
    _sub?.cancel();
    _sub = null;
    _staleCheck?.cancel();
    _staleCheck = null;
  }
}