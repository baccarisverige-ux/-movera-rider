import 'dart:async';

import 'package:movera_rider/app/di.dart';
import 'package:movera_rider/core/realtime/ride_realtime.dart';
import 'package:movera_rider/features/finding_driver/domain/driver_eta.dart';
import 'package:movera_rider/features/ride_booking/data/ride_snapshot_store.dart';
import 'package:movera_rider/features/ride_booking/domain/entities/matched_driver.dart';
import 'package:movera_rider/features/ride_booking/domain/ride_status.dart';

class DriverTrackingController {
  DriverTrackingController({
    RideRealtime? realtime,
    required this.pickupLat,
    required this.pickupLng,
  }) : _realtime = realtime ?? AppScope.instance.rideRealtime;

  final RideRealtime _realtime;
  final double pickupLat;
  final double pickupLng;
  StreamSubscription<RideRealtimeEvent>? _sub;
  MatchedDriver? driver;
  DriverEta? eta;
  RideStatus status = RideStatus.driverAssigned;
  RideStatus? _lastPersistedStatus;
  void Function()? onChange;

  void start({
    required String rideId,
    MatchedDriver? initial,
    void Function()? onChange,
  }) {
    driver = initial;
    this.onChange = onChange;
    _sub?.cancel();
    _sub = _realtime.subscribe(rideId).listen((event) {
      final statusChanged = event.status != status;
      status = event.status;
      if (event.driver != null) driver = event.driver;
      if (event.latitude != null && event.longitude != null) {
        eta = DriverEta.fromFix(
          latitude: event.latitude!,
          longitude: event.longitude!,
          pickupLat: pickupLat,
          pickupLng: pickupLng,
          locationAt: event.locationAt ?? event.at,
          etaSeconds: event.etaSeconds,
        );
      } else if (eta != null && eta!.locationAt != null) {
        eta = DriverEta.fromFix(
          latitude: eta!.latitude ?? pickupLat,
          longitude: eta!.longitude ?? pickupLng,
          pickupLat: pickupLat,
          pickupLng: pickupLng,
          locationAt: eta!.locationAt!,
          etaSeconds: event.etaSeconds ?? eta!.seconds,
        );
      }
      if (statusChanged) {
        unawaited(_persistLiveStatus());
      }
      this.onChange?.call();
    });
    unawaited(_persistLiveStatus());
  }

  Future<void> _persistLiveStatus() async {
    if (status.isTerminal) return;
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
  }
}