import 'dart:convert';

import 'package:movera_rider/core/storage/preferences_store.dart';
import 'package:movera_rider/features/reservations/domain/reservation.dart';
import 'package:movera_rider/features/reservations/domain/reservation_status.dart';
import 'package:movera_rider/features/ride_booking/data/ride_snapshot_store.dart';
import 'package:movera_rider/features/ride_booking/domain/ride_status.dart';

/// Local archive for finished Book Now rides.
///
/// The backend remains the future source of truth. Until then, retain at most
/// 100 rides for 180 days on this device.
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
      final rides = decoded
          .map(Reservation.tryParse)
          .whereType<Reservation>()
          .where((ride) => ride.scheduledPickupAt.isAfter(cutoff))
          .toList()
        ..sort(
          (a, b) => b.scheduledPickupAt.compareTo(a.scheduledPickupAt),
        );
      return rides.take(maxRecords).toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  static Future<void> archive(
    RideSnapshot snapshot, {
    required RideStatus terminalStatus,
    DateTime? endedAt,
    String? cancellationReason,
  }) async {
    final reservationStatus = terminalStatus.isCompletedSurface
        ? ReservationStatus.completed
        : terminalStatus.isTerminal && terminalStatus != RideStatus.closed
        ? ReservationStatus.cancelled
        : null;
    if (reservationStatus == null) {
      throw ArgumentError.value(
        terminalStatus,
        'terminalStatus',
        'Only completed or cancelled rides can be archived.',
      );
    }

    final ended = endedAt ?? DateTime.now();
    final record = Reservation(
      reservationId: 'ondemand-${snapshot.rideId ?? snapshot.savedAt.microsecondsSinceEpoch}',
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
      categoryId: snapshot.rideType.toLowerCase().replaceAll(' ', '-'),
      categoryName: snapshot.rideType,
      categoryImage: _categoryImage(snapshot.rideType),
      price: snapshot.price,
      paymentMethod: snapshot.paymentMethod,
      status: reservationStatus,
      driver: _driver(snapshot),
      note: snapshot.notes.hasNote ? snapshot.notes.note : null,
      cancellationReason:
          cancellationReason ?? snapshot.cancellationReason,
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

  static String _categoryImage(String rideType) {
    final value = rideType.toLowerCase();
    if (value.contains('comfort')) return 'assets/images/rides/comfort.png';
    if (value.contains('premium')) return 'assets/images/rides/premium.png';
    if (value.contains('electric')) return 'assets/images/rides/electric.png';
    if (value.contains('xl')) return 'assets/images/rides/xl.png';
    if (value.contains('pet')) return 'assets/images/rides/pet.png';
    if (value.contains('priority')) return 'assets/images/rides/priority.png';
    return 'assets/images/rides/movera.png';
  }
}
