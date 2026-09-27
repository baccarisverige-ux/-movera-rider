import 'dart:convert';

import 'package:movera_rider/core/storage/preferences_store.dart';

/// A ride cancellation the server never acknowledged.
///
/// The rider-facing cancel flow commits to "cancelled" locally the moment
/// the rider taps Cancel, then tells the backend in the background. When
/// that background call keeps failing (offline, a dropped connection), the
/// request must not just vanish when the process exits — a later session
/// needs to find it and try again.
class PendingCancel {
  const PendingCancel({required this.rideId, this.reasonId});

  final String rideId;
  final String? reasonId;

  Map<String, dynamic> toJson() => {'rideId': rideId, 'reasonId': reasonId};

  factory PendingCancel.fromJson(Map<String, dynamic> json) => PendingCancel(
    rideId: json['rideId'] as String,
    reasonId: json['reasonId'] as String?,
  );
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
