import 'package:movera_rider/core/api/api_client.dart';
import 'package:movera_rider/core/api/api_error.dart';
import 'package:movera_rider/core/utils/request_id.dart';
import 'package:movera_rider/features/safety/data/safety_data_sources.dart';
import 'package:movera_rider/features/safety/domain/audio_recording.dart';
import 'package:movera_rider/features/safety/domain/emergency_contact.dart';
import 'package:movera_rider/features/safety/domain/phone_e164.dart';
import 'package:movera_rider/features/safety/domain/ride_check.dart';
import 'package:movera_rider/features/safety/domain/ride_pin.dart';
import 'package:movera_rider/features/safety/domain/safety_preferences.dart';
import 'package:movera_rider/features/safety/domain/trip_share.dart';

class SafetyException implements Exception {
  const SafetyException(this.code, this.message);
  final String code;
  final String message;
  @override
  String toString() => 'SafetyException($code, $message)';
}

/// Cached + remote Safety store. Screens never talk to this type's data sources.
class SafetyStore {
  SafetyStore({
    SafetyLocalDataSource? local,
    SafetyRemoteDataSource? remote,
  })  : _local = local ?? PreferencesSafetyLocalDataSource(),
        _remote = remote ?? ApiSafetyRemoteDataSource(ApiClient());

  static SafetyStore? _shared;
  static SafetyStore get shared => _shared ??= SafetyStore();
  static void resetShared() => _shared = null;

  final SafetyLocalDataSource _local;
  final SafetyRemoteDataSource _remote;
  SafetyCache _cache = SafetyCache();
  bool _loaded = false;
  bool failNextWrite = false;

  SafetyPreferences get preferences => _cache.preferences;
  RidePin get pin => _cache.pin;
  List<EmergencyContact> get contacts => List.unmodifiable(_cache.contacts);
  RideCheckPolicy get rideCheck => _cache.rideCheck;
  List<RideCheckEvent> get rideCheckEvents => List.unmodifiable(_cache.events);

  Future<void> load() async {
    _cache = await _local.load();
    try {
      final prefs = await _remote.getPreferences();
      final pin = await _remote.getPin();
      final contacts = await _remote.listContacts();
      final policy = await _remote.getRideCheck();
      _cache.preferences = prefs;
      _cache.pin = pin;
      _cache.contacts = contacts;
      _cache.rideCheck = policy;
      await _local.save(_cache);
    } catch (_) {
      // Offline: cached display data only. PIN/events remain server-authoritative
      // when the real backend is connected.
    }
    if (_cache.pin.pin.isEmpty || !RegExp(r'^\d{4}$').hasMatch(_cache.pin.pin)) {
      _cache.pin = RidePin.generate();
      await _local.save(_cache);
    }
    _loaded = true;
  }

  Future<void> _ensure() async {
    if (!_loaded) await load();
  }

  Future<T> _write<T>(Future<T> Function() remote, T optimistic, void Function(T value) apply) async {
    await _ensure();
    final previous = SafetyCache.fromJson(_cache.toJson());
    apply(optimistic);
    await _local.save(_cache);
    if (failNextWrite) {
      failNextWrite = false;
      _cache = previous;
      await _local.save(_cache);
      throw const SafetyException('SERVER_ERROR', 'Simulated write failure');
    }
    try {
      final confirmed = await remote();
      apply(confirmed);
      await _local.save(_cache);
      return confirmed;
    } catch (error) {
      _cache = previous;
      await _local.save(_cache);
      rethrow;
    }
  }

  Future<SafetyPreferences> patchPreferences(SafetyPreferences next) {
    return _write(
      () => _remote.patchPreferences(next),
      next.copyWith(updatedAt: DateTime.now().toUtc()),
      (value) => _cache.preferences = value,
    );
  }

  Future<RidePin> rotatePin({String? idempotencyKey}) async {
    await _ensure();
    final previous = _cache.pin;
    final optimistic = RidePin.generate(requiredForStart: previous.requiredForStart);
    return _write(
      () => _remote.rotatePin(idempotencyKey: idempotencyKey),
      optimistic,
      (value) {
        _cache.pin = value.copyWith(requiredForStart: _cache.preferences.pinRequired);
      },
    );
  }

  Future<PinVerifyResult> verifyPin({required String rideId, required String pin}) async {
    await _ensure();
    try {
      return await _remote.verifyPin(rideId: rideId, pin: pin);
    } on ApiError catch (error) {
      if (error.statusCode == 409 || error.code.contains('409')) {
        return PinVerifyResult(valid: false, rideId: rideId, code: 'PIN_INVALID');
      }
      rethrow;
    }
  }

  Future<EmergencyContact> createContact({
    required String name,
    required String phone,
    String relationship = 'Other',
    bool shareTrips = false,
    bool isEnabled = true,
    String? idempotencyKey,
  }) async {
    await _ensure();
    if (_cache.contacts.length >= kMaxEmergencyContacts) {
      throw const SafetyException('CONTACT_LIMIT', 'You can add up to 5 emergency contacts.');
    }
    final e164 = SwedishPhone.toE164(phone);
    if (e164 == null) {
      throw const SafetyException('INVALID_PHONE', 'Enter a Swedish mobile number.');
    }
    if (_cache.contacts.any((c) => c.phoneE164 == e164)) {
      throw const SafetyException('DUPLICATE_PHONE', 'That number is already saved.');
    }
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw const SafetyException('INVALID_NAME', 'Enter a contact name.');
    }
    final now = DateTime.now().toUtc();
    final contact = EmergencyContact(
      id: 'ec_${newRequestId()}',
      userId: _cache.preferences.userId,
      name: trimmed,
      phoneE164: e164,
      relationship: kEmergencyContactRelationships.contains(relationship)
          ? relationship
          : 'Other',
      isPrimary: _cache.contacts.isEmpty,
      shareTrips: shareTrips,
      isEnabled: isEnabled,
      createdAt: now,
      updatedAt: now,
    );
    return _write(
      () => _remote.createContact(contact, idempotencyKey: idempotencyKey),
      contact,
      (value) {
        final next = [..._cache.contacts.where((c) => c.id != value.id), value];
        if (value.isPrimary) {
          _cache.contacts = [
            for (final item in next)
              item.copyWith(isPrimary: item.id == value.id),
          ];
        } else {
          _cache.contacts = next;
        }
      },
    );
  }

  Future<EmergencyContact> updateContact(EmergencyContact contact) async {
    final e164 = SwedishPhone.toE164(contact.phoneE164) ??
        (RegExp(r'^\+46\d{7,10}$').hasMatch(contact.phoneE164)
            ? contact.phoneE164
            : null);
    if (e164 == null) {
      throw const SafetyException('INVALID_PHONE', 'Enter a Swedish mobile number.');
    }
    if (contact.name.trim().isEmpty) {
      throw const SafetyException('INVALID_NAME', 'Enter a contact name.');
    }
    if (_cache.contacts.any((c) => c.phoneE164 == e164 && c.id != contact.id)) {
      throw const SafetyException('DUPLICATE_PHONE', 'That number is already saved.');
    }
    final next = contact.copyWith(
      phoneE164: e164,
      name: contact.name.trim(),
      updatedAt: DateTime.now().toUtc(),
    );
    return _write(
      () => _remote.updateContact(next),
      next,
      (value) {
        _cache.contacts = [
          for (final item in _cache.contacts)
            if (item.id == value.id) value else item,
        ];
      },
    );
  }

  Future<void> deleteContact(String id) async {
    await _ensure();
    final previous = [..._cache.contacts];
    _cache.contacts = _cache.contacts.where((c) => c.id != id).toList();
    if (_cache.contacts.isNotEmpty && !_cache.contacts.any((c) => c.isPrimary)) {
      _cache.contacts[0] = _cache.contacts[0].copyWith(isPrimary: true);
    }
    await _local.save(_cache);
    try {
      await _remote.deleteContact(id);
    } catch (_) {
      _cache.contacts = previous;
      await _local.save(_cache);
      rethrow;
    }
  }

  Future<List<EmergencyContact>> setPrimary(String id) async {
    await _ensure();
    final optimistic = [
      for (final item in _cache.contacts)
        item.copyWith(isPrimary: item.id == id),
    ];
    return _write(
      () => _remote.setPrimary(id),
      optimistic,
      (value) => _cache.contacts = value,
    );
  }

  Future<TripShare> startShare(String rideId, {List<String>? contactIds}) async {
    if (rideId.trim().isEmpty) {
      throw const SafetyException('NO_RIDE', 'Sharing starts when a ride is active.');
    }
    final ids = contactIds ??
        _cache.contacts.where((c) => c.shareTrips && c.isEnabled).map((c) => c.id).toList();
    final token = 'tok_${newRequestId()}';
    final now = DateTime.now().toUtc();
    final optimistic = TripShare(
      shareId: 'share_$rideId',
      rideId: rideId,
      userId: _cache.preferences.userId,
      contactIds: ids,
      startedAt: now,
      expiresAt: now.add(const Duration(hours: 6)),
      shareToken: token,
      isActive: true,
    );
    return _write(
      () => _remote.startShare(rideId, contactIds: ids),
      optimistic,
      (value) => _cache.shares[rideId] = value,
    );
  }

  Future<TripShare?> getShare(String rideId) async {
    await _ensure();
    try {
      final live = await _remote.getShare(rideId);
      if (live != null) {
        _cache.shares[rideId] = live;
        await _local.save(_cache);
      }
      return live ?? _cache.shares[rideId];
    } catch (_) {
      return _cache.shares[rideId];
    }
  }

  Future<void> stopShare(String rideId) async {
    await _ensure();
    final previous = _cache.shares[rideId];
    final current = previous?.copyWith(isActive: false);
    if (current != null) _cache.shares[rideId] = current;
    await _local.save(_cache);
    try {
      await _remote.stopShare(rideId);
    } catch (_) {
      if (previous != null) _cache.shares[rideId] = previous;
      await _local.save(_cache);
      rethrow;
    }
  }

  Future<RideCheckPolicy> patchRideCheck(bool enabled) {
    final next = _cache.rideCheck.copyWith(
      enabled: enabled,
      updatedAt: DateTime.now().toUtc(),
    );
    return _write(
      () => _remote.patchRideCheck(next),
      next,
      (value) {
        _cache.rideCheck = value;
        _cache.preferences = _cache.preferences.copyWith(rideCheckEnabled: value.enabled);
      },
    );
  }

  Future<RideCheckEvent> postEvent(RideCheckEvent event) async {
    await _ensure();
    final existing = _cache.events.where((e) => e.eventId == event.eventId);
    if (existing.isNotEmpty) return existing.first;
    final lastResolved = _cache.events.where((e) => e.status == RideCheckStatus.resolved);
    if (lastResolved.isNotEmpty) {
      final latest = lastResolved.last.at;
      if (event.at.isBefore(latest) || event.at.isAtSameMomentAs(latest)) {
        return event.copyWith(status: RideCheckStatus.stale);
      }
    }
    return _write(
      () => _remote.postSafetyEvent(event),
      event,
      (value) {
        _cache.events = [..._cache.events.where((e) => e.eventId != value.eventId), value];
      },
    );
  }

  Future<RideCheckEvent> respondEvent({
    required String rideId,
    required String eventId,
    required String action,
  }) async {
    final current = _cache.events.firstWhere(
      (e) => e.eventId == eventId,
      orElse: () => RideCheckEvent(
        eventId: eventId,
        rideId: rideId,
        type: RideCheckEventType.manualSafetyCheck,
        at: DateTime.now().toUtc(),
      ),
    );
    final next = current.copyWith(
      status: action == 'resolved' ? RideCheckStatus.resolved : RideCheckStatus.acknowledged,
    );
    return _write(
      () => _remote.respondSafetyEvent(rideId: rideId, eventId: eventId, action: action),
      next,
      (value) {
        _cache.events = [
          for (final item in _cache.events)
            if (item.eventId == value.eventId) value else item,
        ];
      },
    );
  }

  Future<AudioRecording> initAudio(String rideId) {
    final rec = AudioRecording(
      id: 'aud_${newRequestId()}',
      rideId: rideId,
      createdAt: DateTime.now().toUtc(),
      uploadStatus: AudioUploadStatus.localOnly,
    );
    return _write(
      () => _remote.initAudio(rideId: rideId),
      rec,
      (value) {
        _cache.recordings = [..._cache.recordings.where((r) => r.id != value.id), value];
      },
    );
  }

  Future<AudioRecording> completeAudio(AudioRecording recording) {
    final next = recording.copyWith(
      endedAt: DateTime.now().toUtc(),
      uploadStatus: AudioUploadStatus.localOnly,
    );
    return _write(
      () => _remote.completeAudio(
        rideId: recording.rideId ?? '',
        recordingId: recording.id,
        durationMs: recording.durationMs,
      ),
      next,
      (value) {
        _cache.recordings = [
          for (final item in _cache.recordings)
            if (item.id == value.id) value else item,
        ];
      },
    );
  }

  Future<void> deleteAudio(AudioRecording recording) async {
    await _ensure();
    _cache.recordings = _cache.recordings.where((r) => r.id != recording.id).toList();
    await _local.save(_cache);
    if (recording.rideId != null) {
      await _remote.deleteAudio(rideId: recording.rideId!, recordingId: recording.id);
    }
  }
}

class RidePinRepository {
  RidePinRepository({SafetyStore? store}) : _store = store ?? SafetyStore.shared;
  final SafetyStore _store;
  RidePin current() => _store.pin;
  Future<RidePin> rotate({String? idempotencyKey}) =>
      _store.rotatePin(idempotencyKey: idempotencyKey);
  Future<PinVerifyResult> verify({required String rideId, required String pin}) =>
      _store.verifyPin(rideId: rideId, pin: pin);
}

class EmergencyContactsRepository {
  EmergencyContactsRepository({SafetyStore? store})
      : _store = store ?? SafetyStore.shared;
  final SafetyStore _store;
  List<EmergencyContact> listContacts() => _store.contacts;
  Future<EmergencyContact> createContact({
    required String name,
    required String phone,
    String relationship = 'Other',
    bool shareTrips = false,
    bool isEnabled = true,
    String? idempotencyKey,
  }) =>
      _store.createContact(
        name: name,
        phone: phone,
        relationship: relationship,
        shareTrips: shareTrips,
        isEnabled: isEnabled,
        idempotencyKey: idempotencyKey,
      );
  Future<EmergencyContact> updateContact(EmergencyContact contact) =>
      _store.updateContact(contact);
  Future<void> deleteContact(String id) => _store.deleteContact(id);
  Future<List<EmergencyContact>> setPrimaryContact(String id) =>
      _store.setPrimary(id);
}

class TripShareRepository {
  TripShareRepository({SafetyStore? store}) : _store = store ?? SafetyStore.shared;
  final SafetyStore _store;
  Future<TripShare> start(String rideId, {List<String>? contactIds}) =>
      _store.startShare(rideId, contactIds: contactIds);
  Future<TripShare?> get(String rideId) => _store.getShare(rideId);
  Future<void> stop(String rideId) => _store.stopShare(rideId);
}

class RideCheckRepository {
  RideCheckRepository({SafetyStore? store}) : _store = store ?? SafetyStore.shared;
  final SafetyStore _store;
  RideCheckPolicy policy() => _store.rideCheck;
  List<RideCheckEvent> events() => _store.rideCheckEvents;
  Future<RideCheckPolicy> setEnabled(bool enabled) => _store.patchRideCheck(enabled);
  Future<RideCheckEvent> post(RideCheckEvent event) => _store.postEvent(event);
  Future<RideCheckEvent> respond({
    required String rideId,
    required String eventId,
    required String action,
  }) =>
      _store.respondEvent(rideId: rideId, eventId: eventId, action: action);
}
