import 'dart:convert';
import 'dart:math';

import 'package:movera_rider/core/storage/preferences_store.dart';
import 'package:movera_rider/features/reservations/data/reservation_policy_catalog.dart';
import 'package:movera_rider/features/reservations/domain/reservation.dart';
import 'package:movera_rider/features/reservations/domain/reservation_policy.dart';
import 'package:movera_rider/features/reservations/domain/reservation_repository.dart';
import 'package:movera_rider/features/reservations/domain/reservation_status.dart';

abstract class ReservationStorage {
  Future<String?> read();
  Future<void> write(String json);
}

class PrefsReservationStorage implements ReservationStorage {
  static const key = 'movera_reservations_v1';

  @override
  Future<String?> read() async {
    try {
      final prefs = await PreferencesStore.load();
      return prefs.getString(key);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> write(String json) async {
    try {
      final prefs = await PreferencesStore.load();
      await prefs.setString(key, json);
    } catch (_) {}
  }
}

class MemoryReservationStorage implements ReservationStorage {
  MemoryReservationStorage([this.value]);

  String? value;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String json) async {
    value = json;
  }
}

class LocalReservationRepository implements ReservationRepository {
  LocalReservationRepository({
    ReservationStorage? storage,
    ReservationPolicy? policy,
    String Function()? nextId,
    DateTime Function()? clock,
  }) : _storage = storage ?? PrefsReservationStorage(),
       _policy = policy ?? ReservationPolicyCatalog.current,
       _nextId = nextId ?? _defaultId,
       _clock = clock ?? DateTime.now;

  final ReservationStorage _storage;
  final ReservationPolicy _policy;
  final String Function() _nextId;
  final DateTime Function() _clock;
  final List<Reservation> _items = [];
  bool _hydrated = false;

  static String _defaultId() {
    final now = DateTime.now().microsecondsSinceEpoch;
    final salt = Random().nextInt(1 << 20).toRadixString(16);
    return 'rsv_${now}_$salt';
  }

  @override
  List<Reservation> get cached => List.unmodifiable(_items);

  @override
  ReservationPolicy get policy => _policy;

  @override
  Future<void> hydrate() async {
    if (_hydrated) return;
    _hydrated = true;
    final raw = await _storage.read();
    if (raw == null || raw.isEmpty) return;
    try {
      final decoded = jsonDecode(raw);
      final list = decoded is List
          ? decoded
          : decoded is Map && decoded['reservations'] is List
          ? decoded['reservations'] as List
          : const [];
      _items
        ..clear()
        ..addAll(list.map(Reservation.tryParse).whereType<Reservation>());
    } catch (_) {
      // Ignore corrupt local data rather than crash on restore.
    }
  }

  Future<void> _persist() {
    return _storage.write(
      jsonEncode(_items.map((item) => item.toJson()).toList()),
    );
  }

  Reservation _require(String reservationId) {
    for (final item in _items) {
      if (item.reservationId == reservationId) return item;
    }
    throw StateError('Unknown reservation $reservationId');
  }

  int _indexOf(String reservationId) {
    return _items.indexWhere((item) => item.reservationId == reservationId);
  }

  @override
  Future<Reservation> createReservation(ReservationDraft draft) async {
    await hydrate();
    final created = Reservation(
      reservationId: _nextId(),
      createdAt: _clock(),
      scheduledPickupAt: draft.scheduledPickupAt,
      estimatedDropoffAt: draft.estimatedDropoffAt,
      pickup: draft.pickup,
      destination: draft.destination,
      categoryId: draft.categoryId,
      categoryName: draft.categoryName,
      categoryImage: draft.categoryImage,
      passengerCount: draft.passengerCount,
      price: draft.price,
      currency: draft.currency,
      paymentMethod: draft.paymentMethod,
      status: ReservationStatus.scheduled,
      note: draft.note,
      policyVersion: _policy.version,
      parentReservationId: draft.parentReservationId,
    );
    _items.insert(0, created);
    await _persist();
    return created;
  }

  @override
  Future<Reservation> updateReservation(
    String reservationId,
    ReservationPatch patch,
  ) async {
    await hydrate();
    final current = _require(reservationId);
    final next = current.copyWith(
      scheduledPickupAt: patch.scheduledPickupAt,
      estimatedDropoffAt: patch.estimatedDropoffAt,
      pickup: patch.pickup,
      destination: patch.destination,
      categoryId: patch.categoryId,
      categoryName: patch.categoryName,
      categoryImage: patch.categoryImage,
      passengerCount: patch.passengerCount,
      paymentMethod: patch.paymentMethod,
      price: patch.price,
      note: patch.note,
      status: patch.status,
      driver: patch.driver,
      clearDriver: patch.clearDriver,
    );
    _items[_indexOf(reservationId)] = next;
    await _persist();
    return next;
  }

  @override
  Future<Reservation> cancelReservation(
    String reservationId, {
    String? reason,
  }) async {
    await hydrate();
    final current = _require(reservationId);
    final next = current.copyWith(
      status: ReservationStatus.cancelled,
      cancellationReason: reason,
    );
    _items[_indexOf(reservationId)] = next;
    await _persist();
    return next;
  }

  @override
  Future<Reservation?> getReservation(String reservationId) async {
    await hydrate();
    for (final item in _items) {
      if (item.reservationId == reservationId) return item;
    }
    return null;
  }

  @override
  Future<List<Reservation>> getUpcomingReservations() async {
    await hydrate();
    return _items.where((item) => item.status.isUpcoming).toList();
  }

  @override
  Future<List<Reservation>> getRideHistory() async {
    await hydrate();
    return cached;
  }

  @override
  Future<Reservation> assignDriver(
    String reservationId, {
    ReservationDriver? driver,
  }) {
    return updateReservation(
      reservationId,
      ReservationPatch(
        status: ReservationStatus.driverAssigned,
        driver: driver ?? ReservationDriver.mockAssigned,
      ),
    );
  }
}
