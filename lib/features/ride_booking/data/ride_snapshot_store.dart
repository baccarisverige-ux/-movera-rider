import 'dart:convert';

import 'package:movera_rider/core/storage/preferences_store.dart';
import 'package:movera_rider/features/ride_booking/domain/entities/matched_driver.dart';
import 'package:movera_rider/features/ride_booking/domain/ride_notes.dart';
import 'package:movera_rider/features/ride_booking/domain/ride_status.dart';

class RideSnapshot {
  const RideSnapshot({
    required this.status,
    required this.savedAt,
    required this.pickupAddress,
    required this.destinationAddress,
    required this.pickupLat,
    required this.pickupLng,
    required this.destinationLat,
    required this.destinationLng,
    required this.rideType,
    required this.price,
    required this.paymentMethod,
    this.rideId,
    this.notes = RideNotes.empty,
    this.driver,
    this.cancellationReason,
  });

  final RideStatus status;
  final DateTime savedAt;
  final String pickupAddress;
  final String destinationAddress;
  final double pickupLat;
  final double pickupLng;
  final double destinationLat;
  final double destinationLng;
  final String rideType;
  final double price;
  final String paymentMethod;
  final String? rideId;
  final RideNotes notes;
  final MatchedDriver? driver;
  final String? cancellationReason;

  bool get isFresh =>
      DateTime.now().difference(savedAt) < const Duration(minutes: 20);

  RideSnapshot copyWith({
    RideStatus? status,
    DateTime? savedAt,
    String? pickupAddress,
    String? destinationAddress,
    double? pickupLat,
    double? pickupLng,
    double? destinationLat,
    double? destinationLng,
    String? rideType,
    double? price,
    String? paymentMethod,
    String? rideId,
    RideNotes? notes,
    MatchedDriver? driver,
    String? cancellationReason,
  }) {
    return RideSnapshot(
      status: status ?? this.status,
      savedAt: savedAt ?? this.savedAt,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      destinationAddress: destinationAddress ?? this.destinationAddress,
      pickupLat: pickupLat ?? this.pickupLat,
      pickupLng: pickupLng ?? this.pickupLng,
      destinationLat: destinationLat ?? this.destinationLat,
      destinationLng: destinationLng ?? this.destinationLng,
      rideType: rideType ?? this.rideType,
      price: price ?? this.price,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      rideId: rideId ?? this.rideId,
      notes: notes ?? this.notes,
      driver: driver ?? this.driver,
      cancellationReason: cancellationReason ?? this.cancellationReason,
    );
  }

  Map<String, dynamic> toJson() => {
    'status': status.name,
    'savedAt': savedAt.toIso8601String(),
    'pickupAddress': pickupAddress,
    'destinationAddress': destinationAddress,
    'pickupLat': pickupLat,
    'pickupLng': pickupLng,
    'destinationLat': destinationLat,
    'destinationLng': destinationLng,
    'rideType': rideType,
    'price': price,
    'paymentMethod': paymentMethod,
    'rideId': rideId,
    'notes': notes.toJson(),
    if (driver != null) 'driver': driver!.toJson(),
    if (cancellationReason != null) 'cancellationReason': cancellationReason,
  };

  static RideSnapshot? fromJson(Map<String, dynamic> json) {
    final statusName = json['status'] as String?;
    final status = RideStatus.values.where((value) => value.name == statusName);
    if (status.isEmpty) return null;
    return RideSnapshot(
      status: status.first,
      savedAt:
          DateTime.tryParse(json['savedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      pickupAddress: json['pickupAddress'] as String? ?? '',
      destinationAddress: json['destinationAddress'] as String? ?? '',
      pickupLat: (json['pickupLat'] as num?)?.toDouble() ?? 0,
      pickupLng: (json['pickupLng'] as num?)?.toDouble() ?? 0,
      destinationLat: (json['destinationLat'] as num?)?.toDouble() ?? 0,
      destinationLng: (json['destinationLng'] as num?)?.toDouble() ?? 0,
      rideType: json['rideType'] as String? ?? 'Movera',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      paymentMethod: json['paymentMethod'] as String? ?? 'Apple Pay',
      rideId: json['rideId'] as String?,
      notes: RideNotes.fromJson(
        json['notes'] is Map
            ? Map<String, dynamic>.from(json['notes'] as Map)
            : null,
      ),
      driver: json['driver'] is Map
          ? MatchedDriver.fromJson(
              Map<String, dynamic>.from(json['driver'] as Map),
            )
          : null,
      cancellationReason: json['cancellationReason'] as String?,
    );
  }
}

class RideSnapshotStore {
  /// SharedPreferences key. On Flutter web this is `flutter.movera_active_ride`.
  static const key = 'movera_active_ride';
  static const webStorageKey = 'flutter.movera_active_ride';

  static Future<void> save(RideSnapshot snapshot) async {
    final prefs = await PreferencesStore.load();
    await prefs.setString(key, jsonEncode(snapshot.toJson()));
  }

  static Future<RideSnapshot?> read() async {
    final prefs = await PreferencesStore.load();
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      final snapshot = RideSnapshot.fromJson(decoded);
      if (snapshot == null || !snapshot.isFresh || snapshot.status.isTerminal) {
        return null;
      }
      return snapshot;
    } catch (_) {
      return null;
    }
  }

  static Future<void> clear() async {
    final prefs = await PreferencesStore.load();
    await prefs.remove(key);
  }
}
