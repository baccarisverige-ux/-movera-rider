import 'dart:convert';

import 'package:movera_rider/core/web/web_search_interrupted.dart';

import 'package:movera_rider/core/storage/preferences_store.dart';
import 'package:movera_rider/features/ride_booking/domain/entities/matched_driver.dart';
import 'package:movera_rider/features/ride_booking/domain/ride_notes.dart';
import 'package:movera_rider/features/ride_booking/domain/ride_status.dart';

class RideSnapshot {
  static const currentSchemaVersion = 2;

  const RideSnapshot({
    required this.status,
    required this.savedAt,
    DateTime? createdAt,
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
  }) : createdAt = createdAt ?? savedAt;

  final RideStatus status;
  final DateTime savedAt;
  final DateTime createdAt;
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
    DateTime? createdAt,
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
      createdAt: createdAt ?? this.createdAt,
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
    'schemaVersion': currentSchemaVersion,
    'status': status.name,
    'savedAt': savedAt.toUtc().toIso8601String(),
    'createdAt': createdAt.toUtc().toIso8601String(),
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
    final schemaVersion = (json['schemaVersion'] as num?)?.toInt() ?? 1;
    if (schemaVersion < 1 || schemaVersion > currentSchemaVersion) return null;

    final statusName = json['status'];
    if (statusName is! String) return null;
    RideStatus? parsedStatus;
    for (final value in RideStatus.values) {
      if (value.name == statusName) {
        parsedStatus = value;
        break;
      }
    }
    if (parsedStatus == null) return null;

    final savedRaw = json['savedAt'];
    if (savedRaw is! String) return null;
    final savedParsed = DateTime.tryParse(savedRaw);
    if (savedParsed == null) return null;
    final savedAt = savedParsed.toUtc();

    final createdRaw = json['createdAt'];
    final createdParsed = createdRaw is String ? DateTime.tryParse(createdRaw) : null;
    // v1 did not persist creation time. Preserve its original persisted time
    // rather than manufacturing a new timestamp during migration.
    final createdAt = (createdParsed ?? savedParsed).toUtc();

    final pickupAddress = json['pickupAddress'];
    final destinationAddress = json['destinationAddress'];
    final pickupLat = json['pickupLat'];
    final pickupLng = json['pickupLng'];
    final destinationLat = json['destinationLat'];
    final destinationLng = json['destinationLng'];
    final rideType = json['rideType'];
    final price = json['price'];
    final paymentMethod = json['paymentMethod'];
    if (pickupAddress is! String ||
        destinationAddress is! String ||
        pickupLat is! num ||
        pickupLng is! num ||
        destinationLat is! num ||
        destinationLng is! num ||
        rideType is! String ||
        price is! num ||
        paymentMethod is! String) {
      return null;
    }

    final rideIdRaw = json['rideId'];
    final rideId = rideIdRaw is String ? rideIdRaw.trim() : null;
    if (rideIdRaw != null && (rideId == null || rideId.isEmpty)) return null;

    return RideSnapshot(
      status: parsedStatus,
      savedAt: savedAt,
      createdAt: createdAt,
      pickupAddress: pickupAddress,
      destinationAddress: destinationAddress,
      pickupLat: pickupLat.toDouble(),
      pickupLng: pickupLng.toDouble(),
      destinationLat: destinationLat.toDouble(),
      destinationLng: destinationLng.toDouble(),
      rideType: rideType,
      price: price.toDouble(),
      paymentMethod: paymentMethod,
      rideId: rideId,
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
  static int _epoch = 0;
  static int get epoch => _epoch;
  static set epoch(int value) {
    _epoch = value;
    // Tests reset epoch between cases; reset the lifecycle intent too so no
    // previous test can poison a later one.
    if (value == 0) {
      _intentSerial = 0;
      _lifecycleRefreshBlocked = false;
      _activeRideId = null;
    }
  }

  /// Changes synchronously whenever business logic explicitly saves or clears
  /// ride state. Lifecycle timestamp refreshes capture this value so they
  /// cannot outlive a newer ride decision.
  static int _intentSerial = 0;
  static bool _lifecycleRefreshBlocked = false;
  static String? _activeRideId;

  /// Monotonic process-local identity for each persisted write.
  ///
  /// It is embedded in the stored JSON as an ignored metadata field. That lets
  /// a stale writer clean up only its own value instead of blindly deleting the
  /// shared key and potentially removing a newer ride.
  static int _writeSerial = 0;

  static Future<void> save(RideSnapshot snapshot) async {
    _intentSerial += 1;

    if (snapshot.status.isTerminal) {
      _lifecycleRefreshBlocked = true;
      _activeRideId = snapshot.rideId;
      return;
    }

    _lifecycleRefreshBlocked = false;
    _activeRideId = snapshot.rideId;

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

  /// Refreshes only the snapshot that is still current at the instant this
  /// lifecycle operation starts.
  ///
  /// Unlike `read() -> save(snapshot)`, this never turns an old read into a
  /// brand-new save after cancellation. Any explicit save/clear invalidates the
  /// captured intent. A clear also blocks lifecycle refresh synchronously while
  /// its SharedPreferences removal is still in flight.
  static Future<void> touchCurrent() async {
    if (_lifecycleRefreshBlocked) return;

    final token = epoch;
    final intentToken = _intentSerial;
    final expectedRideId = _activeRideId;

    final prefs = await PreferencesStore.load();
    if (token != epoch ||
        intentToken != _intentSerial ||
        _lifecycleRefreshBlocked) {
      return;
    }

    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return;

    Map<String, dynamic> decoded;
    try {
      final value = jsonDecode(raw);
      if (value is! Map<String, dynamic>) return;
      decoded = Map<String, dynamic>.from(value);
    } catch (_) {
      return;
    }

    final snapshot = RideSnapshot.fromJson(decoded);
    if (snapshot == null ||
        snapshot.status.isTerminal ||
        !snapshot.isFresh) {
      return;
    }

    if (expectedRideId != null && snapshot.rideId != expectedRideId) {
      return;
    }

    final writeId = ++_writeSerial;
    decoded['savedAt'] = DateTime.now().toUtc().toIso8601String();
    decoded[_writeIdField] = writeId;
    final encoded = jsonEncode(decoded);

    if (token != epoch ||
        intentToken != _intentSerial ||
        _lifecycleRefreshBlocked) {
      return;
    }

    markSearchLive();
    await prefs.setString(key, encoded);

    if (token != epoch ||
        intentToken != _intentSerial ||
        _lifecycleRefreshBlocked) {
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
    _epoch += 1;
    _intentSerial += 1;
    _lifecycleRefreshBlocked = true;
    _activeRideId = null;
    final prefs = await PreferencesStore.load();
    await prefs.remove(key);
  }
}
