import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
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

  bool get isFresh =>
      DateTime.now().difference(savedAt) < const Duration(minutes: 20);

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
      };

  static RideSnapshot? fromJson(Map<String, dynamic> json) {
    final statusName = json['status'] as String?;
    final status = RideStatus.values.where((value) => value.name == statusName);
    if (status.isEmpty) return null;
    return RideSnapshot(
      status: status.first,
      savedAt: DateTime.tryParse(json['savedAt'] as String? ?? '') ??
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
    );
  }
}

class RideSnapshotStore {
  static const _key = 'movera_active_ride';

  static Future<void> save(RideSnapshot snapshot) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(snapshot.toJson()));
  }

  static Future<RideSnapshot?> read() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
