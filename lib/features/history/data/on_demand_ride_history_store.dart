import 'dart:convert';

import 'package:movera_rider/core/storage/preferences_store.dart';
import 'package:movera_rider/features/reservations/domain/reservation.dart';
import 'package:movera_rider/features/reservations/domain/reservation_status.dart';
import 'package:movera_rider/features/ride_booking/data/ride_snapshot_store.dart';
import 'package:movera_rider/features/ride_booking/domain/ride_status.dart';

/// Local archive for finished Book Now rides.
///
/// The backend remains the future source of truth. Until then, retain at most
/// 100 rides for 180 days on this device. Records are keyed by the real rideId
/// so retries cannot create duplicate History entries.
abstract final class OnDemandRideHistoryStore {
  static const key = 'movera_on_demand_ride_history_v1';
  static const maxRecords = 100;
  static const retention = Duration(days: 180);

  static Future<List<Reservation>> read() async {
    final prefs = await PreferencesStore.load();
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      final cutoff = DateTime.now().subtract(retention);
      final byId = <String, Reservation>{};
      for (final value in decoded) {
        final ride = Reservation.tryParse(value);
        if (ride == null || !ride.scheduledPickupAt.isAfter(cutoff)) continue;
        final current = byId[ride.reservationId];
        if (current == null ||
            ride.scheduledPickupAt.isAfter(current.scheduledPickupAt)) {
          byId[ride.reservationId] = ride;
        }
      }
      final rides = byId.values.toList()
        ..sort((a, b) => b.scheduledPickupAt.compareTo(a.scheduledPickupAt));
      return rides.take(maxRecords).toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  /// Archives a cancelled Book Now ride then clears the live snapshot.
  ///
  /// Cancel-first stays intact: the snapshot is always cleared, even when
  /// History has nothing to keep (missing rideId, already cleared, etc.).
  static Future<void> archiveCancelledThenClear({
    RideSnapshot? snapshot,
    String? reasonId,
  }) async {
    final candidate = snapshot ?? await RideSnapshotStore.readForArchive();
    final rideId = candidate?.rideId?.trim();
    if (candidate != null && rideId != null && rideId.isNotEmpty) {
      try {
        await archive(
          candidate,
          terminalStatus: RideStatus.cancelledByRider,
          cancellationReason: reasonId,
        );
      } catch (_) {}
    }
    await RideSnapshotStore.clear();
  }

  static Future<void> archive(
    RideSnapshot snapshot, {
    required RideStatus terminalStatus,
    DateTime? endedAt,
    String? cancellationReason,
  }) async {
    final rideId = snapshot.rideId?.trim();
    if (rideId == null || rideId.isEmpty) {
      throw ArgumentError.value(
        snapshot.rideId,
        'rideId',
        'A stable rideId is required for History archival.',
      );
    }

    final reservationStatus = _reservationStatus(terminalStatus);
    if (reservationStatus == null) {
      throw ArgumentError.value(
        terminalStatus,
        'terminalStatus',
        'Only completed or explicitly cancelled rides can be archived.',
      );
    }

    final ended = endedAt ?? DateTime.now();
    final record = Reservation(
      reservationId: 'ondemand-$rideId',
      createdAt: snapshot.savedAt,
      scheduledPickupAt: ended,
      pickup: ReservationPlace(
        label: snapshot.pickupAddress,
        lat: snapshot.pickupLat,
        lng: snapshot.pickupLng,
      ),
      destination: ReservationPlace(
        label: snapshot.destinationAddress,
        lat: snapshot.destinationLat,
        lng: snapshot.destinationLng,
      ),
      categoryId: _categoryId(snapshot.rideType),
      categoryName: snapshot.rideType.trim().isEmpty
          ? 'Movera'
          : snapshot.rideType,
      categoryImage: _categoryImage(snapshot.rideType),
      price: snapshot.price,
      paymentMethod: snapshot.paymentMethod,
      status: reservationStatus,
      driver: _driver(snapshot),
      note: snapshot.notes.selected.isEmpty
          ? null
          : snapshot.notes.selected.join(', '),
      cancellationReason: cancellationReason ?? snapshot.cancellationReason,
    );

    final rides = await read();
    final updated = <Reservation>[
      record,
      ...rides.where((ride) => ride.reservationId != record.reservationId),
    ]..sort((a, b) => b.scheduledPickupAt.compareTo(a.scheduledPickupAt));

    final prefs = await PreferencesStore.load();
    await prefs.setString(
      key,
      jsonEncode(
        updated.take(maxRecords).map((ride) => ride.toJson()).toList(),
      ),
    );
  }

  static Future<void> clear() async {
    final prefs = await PreferencesStore.load();
    await prefs.remove(key);
  }

  static ReservationStatus? _reservationStatus(RideStatus status) {
    if (status.isCompletedSurface) return ReservationStatus.completed;
    if (status == RideStatus.cancelledByRider ||
        status == RideStatus.cancelledByDriver ||
        status == RideStatus.cancelledBySystem) {
      return ReservationStatus.cancelled;
    }
    return null;
  }

  static ReservationDriver? _driver(RideSnapshot snapshot) {
    final driver = snapshot.driver;
    if (driver == null) return null;
    return ReservationDriver(
      firstName: driver.firstName,
      rating: driver.rating,
      vehicle: driver.vehicleLabel.isEmpty ? null : driver.vehicleLabel,
      plate: driver.plate,
      photoAsset: driver.photoAsset,
    );
  }

  static String _categoryId(String rideType) {
    final id = rideType.trim().toLowerCase().replaceAll(' ', '-');
    return id.isEmpty ? 'movera' : id;
  }

  static String _categoryImage(String rideType) {
    final value = rideType.toLowerCase();
    if (value.contains('comfort')) return 'assets/images/rides/comfort.webp';
    if (value.contains('premium')) return 'assets/images/rides/premium.webp';
    if (value.contains('electric')) return 'assets/images/rides/electric.webp';
    if (value.contains('xl')) return 'assets/images/rides/xl.webp';
    if (value.contains('pet')) return 'assets/images/rides/pet.webp';
    if (value.contains('priority')) return 'assets/images/rides/priority.webp';
    return 'assets/images/rides/movera.webp';
  }
}
