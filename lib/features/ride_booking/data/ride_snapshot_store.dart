import 'dart:convert';

import 'package:movera_rider/core/web/web_search_interrupted.dart';

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

  /// How long a saved ride may go untouched and still be worth restoring.
  ///
  /// The rule exists to stop an abandoned snapshot reviving days later as a
  /// zombie "Finding driver". Twenty minutes is right for a search — none runs
  /// longer — but wrong once a driver is matched: a real trip across Stockholm
  /// can easily outlive it, and the rider would come back to Home mid-journey.
  /// The same goes for a finished trip still owing payment or a rating. So the
  /// window follows the ride's state, not just the clock.
  static const searchWindow = Duration(minutes: 20);
  static const activeRideWindow = Duration(hours: 6);

  Duration get freshnessWindow => status.isMatched || status.isCompletedSurface
      ? activeRideWindow
      : searchWindow;

  bool get isFresh => DateTime.now().difference(savedAt) < freshnessWindow;

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
  static const _writeIdField = '_moveraSnapshotWriteId';

  /// Bumped synchronously on every [clear] so a save can detect that it became
  /// stale while awaiting SharedPreferences/platform persistence.
  static int epoch = 0;

  /// Monotonic process-local identity for each persisted write.
  ///
  /// It is embedded in the stored JSON as an ignored metadata field. That lets
  /// a stale writer clean up only its own value instead of blindly deleting the
  /// shared key and potentially removing a newer ride.
  static int _writeSerial = 0;

  static Future<void> save(RideSnapshot snapshot) async {
    if (snapshot.status.isTerminal) return;

    // A live ride is worth remembering across a reload so the same trip
    // reopens instead of dumping the rider on Home.
    markSearchLive();

    final token = epoch;
    final writeId = ++_writeSerial;
    final payload = <String, dynamic>{
      ...snapshot.toJson(),
      _writeIdField: writeId,
    };
    final encoded = jsonEncode(payload);

    final prefs = await PreferencesStore.load();
    if (token != epoch) return;

    await prefs.setString(key, encoded);

    if (token != epoch) {
      // Never perform an unconditional stale rollback. Read and compare without
      // an await between the comparison and remove invocation, so a newer save
      // cannot be mistaken for this write. The unique write id also makes two
      // otherwise-identical snapshots distinguishable.
      if (prefs.getString(key) == encoded) {
        await prefs.remove(key);
      }
    }
  }

  static Future<RideSnapshot?> read() async {
    final snapshot = await _readStored();
    if (snapshot == null || !snapshot.isFresh || snapshot.status.isTerminal) {
      return null;
    }
    return snapshot;
  }

  /// Reads the last persisted ride specifically for terminal History archival.
  ///
  /// Unlike [read], this intentionally ignores [RideSnapshot.isFresh]
  /// entirely. A legitimate long trip must still be archived before its active
  /// snapshot is cleared, however stale the snapshot has gone.
  static Future<RideSnapshot?> readForArchive() => _readStored();

  static Future<RideSnapshot?> _readStored() async {
    final prefs = await PreferencesStore.load();
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      return RideSnapshot.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  static Future<void> clear() async {
    epoch += 1;
    final prefs = await PreferencesStore.load();
    await prefs.remove(key);
  }
}
