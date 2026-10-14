import 'dart:convert';

import 'package:movera_rider/core/api/api_error.dart';
import 'package:movera_rider/core/api/idempotency.dart';
import 'package:movera_rider/core/logging/app_log.dart';
import 'package:movera_rider/core/storage/preferences_store.dart';

/// A ride cancellation the server never acknowledged.
///
/// Finding commits to "cancelled" locally and tells the backend in the
/// background; Waiting/in-trip asks the backend first. In both cases, when the
/// backend call keeps failing (offline, a dropped connection) the request must
/// not just vanish when the process exits — a later session, or the next
/// reconnect, needs to find it and try again.
///
/// D-020: every entry carries the one idempotency key minted for it, so a
/// retry after a relaunch is recognisably the same request to the server
/// instead of a brand-new cancel each launch.
class PendingCancel {
  const PendingCancel({
    required this.rideId,
    this.reasonId,
    this.idempotencyKey,
  });

  final String rideId;
  final String? reasonId;

  /// Null only for entries written by builds before D-020; the flush mints
  /// and persists one the first time it sees such an entry.
  final String? idempotencyKey;

  PendingCancel withKey(String key) =>
      PendingCancel(rideId: rideId, reasonId: reasonId, idempotencyKey: key);

  PendingCancel withReason(String? reason) => PendingCancel(
    rideId: rideId,
    reasonId: reason,
    idempotencyKey: idempotencyKey,
  );

  Map<String, dynamic> toJson() => {
    'rideId': rideId,
    'reasonId': reasonId,
    if (idempotencyKey != null) 'idempotencyKey': idempotencyKey,
  };

  factory PendingCancel.fromJson(Map<String, dynamic> json) => PendingCancel(
    rideId: json['rideId'] as String,
    reasonId: json['reasonId'] as String?,
    idempotencyKey: json['idempotencyKey'] as String?,
  );
}

/// True when a cancel request failed in a way no retry can fix: the server
/// no longer knows the ride (404/410) or refuses the transition because the
/// ride is already finished/cancelled (409/422). Those entries must leave the
/// outbox instead of being retried forever (D-020).
bool isPermanentCancelFailure(Object error) {
  if (error is! ApiError) return false;
  final status = error.statusCode;
  return status == 404 || status == 409 || status == 410 || status == 422;
}

class PendingCancelStore {
  static const _key = 'movera_pending_cancels';

  /// Decodes one stored entry, or null when it is corrupt (not JSON, not an
  /// object, no usable rideId). CODE-17: one bad entry used to throw out of
  /// every read, so no later cancel could be queued or flushed at all.
  static PendingCancel? _decode(String entry) {
    try {
      final decoded = jsonDecode(entry);
      if (decoded is! Map<String, dynamic>) return null;
      final rideId = decoded['rideId'];
      if (rideId is! String || rideId.trim().isEmpty) return null;
      final reasonId = decoded['reasonId'];
      final key = decoded['idempotencyKey'];
      return PendingCancel(
        rideId: rideId,
        reasonId: reasonId is String ? reasonId : null,
        idempotencyKey: key is String && key.isNotEmpty ? key : null,
      );
    } catch (_) {
      return null;
    }
  }

  static void _logCorrupt(int count) {
    AppLog.warning(
      'ride.cancel.outbox_corrupt_entry_skipped',
      extra: {'count': count},
    );
  }

  /// Every readable entry; corrupt ones are skipped and logged.
  static Future<List<PendingCancel>> all() async {
    final prefs = await PreferencesStore.load();
    final raw = prefs.getStringList(_key) ?? const <String>[];
    final entries = <PendingCancel>[];
    var corrupt = 0;
    for (final entry in raw) {
      final decoded = _decode(entry);
      if (decoded == null) {
        corrupt += 1;
      } else {
        entries.add(decoded);
      }
    }
    if (corrupt > 0) _logCorrupt(corrupt);
    return entries;
  }

  /// The stored list without corrupt entries and without [rideId]'s entry.
  /// Rewriting the list therefore also drops anything unreadable.
  static List<String> _othersThan(List<String> existing, String rideId) {
    final kept = <String>[];
    var corrupt = 0;
    for (final entry in existing) {
      final decoded = _decode(entry);
      if (decoded == null) {
        corrupt += 1;
      } else if (decoded.rideId != rideId) {
        kept.add(entry);
      }
    }
    if (corrupt > 0) _logCorrupt(corrupt);
    return kept;
  }

  static Future<PendingCancel?> find(String rideId) async {
    for (final entry in await all()) {
      if (entry.rideId == rideId) return entry;
    }
    return null;
  }

  static Future<void> add(PendingCancel cancel) async {
    final prefs = await PreferencesStore.load();
    final existing = prefs.getStringList(_key) ?? const <String>[];
    final withoutSameRide = _othersThan(existing, cancel.rideId);
    await prefs.setStringList(_key, [
      ...withoutSameRide,
      jsonEncode(cancel.toJson()),
    ]);
  }

  /// Records the rider's intent to cancel [rideId] before the request is
  /// sent, reusing the entry (and its idempotency key) if one already exists.
  static Future<PendingCancel> enqueue({
    required String rideId,
    String? reasonId,
    String? idempotencyKey,
  }) async {
    final existing = await find(rideId);
    if (existing != null && existing.idempotencyKey != null) return existing;
    final entry = PendingCancel(
      rideId: rideId,
      reasonId: reasonId ?? existing?.reasonId,
      idempotencyKey:
          idempotencyKey ?? newIdempotencyKey('ride-cancel'),
    );
    await add(entry);
    return entry;
  }

  static Future<void> remove(String rideId) async {
    final prefs = await PreferencesStore.load();
    final existing = prefs.getStringList(_key) ?? const <String>[];
    await prefs.setStringList(_key, _othersThan(existing, rideId));
  }

  /// Adds the rider's optional reason to a cancel that is still queued, so
  /// the retried request carries it. Keeps the entry's idempotency key.
  /// Returns false when nothing for [rideId] is queued.
  static Future<bool> attachReason(String rideId, String reasonId) async {
    final existing = await find(rideId);
    if (existing == null) return false;
    await add(existing.withReason(reasonId));
    return true;
  }
}
