import 'dart:convert';

import 'package:movera_rider/core/api/api_error.dart';
import 'package:movera_rider/core/api/idempotency.dart';
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

  static Future<List<PendingCancel>> all() async {
    final prefs = await PreferencesStore.load();
    final raw = prefs.getStringList(_key) ?? const <String>[];
    return raw
        .map(
          (entry) =>
              PendingCancel.fromJson(jsonDecode(entry) as Map<String, dynamic>),
        )
        .toList();
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
    final withoutSameRide = existing.where((entry) {
      final decoded = jsonDecode(entry) as Map<String, dynamic>;
      return decoded['rideId'] != cancel.rideId;
    }).toList();
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
    await prefs.setStringList(
      _key,
      existing.where((entry) {
        final decoded = jsonDecode(entry) as Map<String, dynamic>;
        return decoded['rideId'] != rideId;
      }).toList(),
    );
  }
}
