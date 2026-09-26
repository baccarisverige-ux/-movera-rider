import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:movera_rider/core/debug/web_qa_hooks.dart';
import 'package:movera_rider/core/logging/app_log.dart';
import 'package:movera_rider/features/safety/application/emergency_call_service.dart';
import 'package:movera_rider/features/safety/application/ride_check_service.dart';
import 'package:movera_rider/features/safety/application/safety_audio_service.dart';
import 'package:movera_rider/features/safety/data/safety_repository.dart';
import 'package:movera_rider/features/safety/data/safety_store.dart';
import 'package:movera_rider/features/safety/domain/emergency_contact.dart';
import 'package:movera_rider/features/safety/domain/ride_check.dart';
import 'package:movera_rider/features/safety/domain/ride_pin.dart';
import 'package:movera_rider/features/safety/domain/safety_event.dart';
import 'package:movera_rider/features/safety/domain/safety_preferences.dart';
import 'package:movera_rider/features/safety/domain/trip_share.dart';

class SafetyController extends ChangeNotifier {
  SafetyController._({
    SafetyRepository? store,
    SafetyStore? session,
    EmergencyCallService? emergency,
    SafetyAudioService? audio,
    RideCheckService? rideCheck,
  })  : _events = store ?? SafetyRepository.shared,
        _session = session ?? SafetyStore.shared,
        emergency = emergency ?? EmergencyCallService.shared,
        audio = audio ?? SafetyAudioService(store: session ?? SafetyStore.shared),
        rideCheck = rideCheck ??
            RideCheckService(store: session ?? SafetyStore.shared);

  factory SafetyController({
    SafetyRepository? store,
    SafetyStore? session,
    EmergencyCallService? emergency,
    SafetyAudioService? audio,
    RideCheckService? rideCheck,
  }) {
    final injected = store != null ||
        session != null ||
        emergency != null ||
        audio != null ||
        rideCheck != null;
    if (!injected) return shared;
    return SafetyController._(
      store: store,
      session: session,
      emergency: emergency,
      audio: audio,
      rideCheck: rideCheck,
    );
  }

  static SafetyController? _shared;
  static SafetyController get shared =>
      _shared ??= SafetyController._();

  static void resetShared() {
    _shared?.dispose();
    _shared = null;
    SafetyStore.resetShared();
    SafetyRepository.resetShared();
  }

  final SafetyRepository _events;
  final SafetyStore _session;
  final EmergencyCallService emergency;
  final SafetyAudioService audio;
  final RideCheckService rideCheck;
  bool loading = false;
  String? error;

  List<SafetyEvent> get events => _events.events;

  SafetyPreferences get preferences => _session.preferences;
  RidePin get pin => _session.pin;
  List<EmergencyContact> get contacts => _session.contacts;
  RideCheckPolicy get rideCheckPolicy => _session.rideCheck;

  String pinStatusLabel() =>
      preferences.pinRequired ? 'On' : 'Off';

  String contactsStatusLabel() {
    if (contacts.isEmpty) return 'None added';
    if (contacts.length == 1) return '1 contact';
    return '${contacts.length} contacts';
  }

  String shareStatusLabel() {
    if (!preferences.tripShareEnabled) return 'Off';
    return preferences.tripShareMode == TripShareMode.auto
        ? 'Every ride'
        : 'Manual';
  }

  String rideCheckStatusLabel() =>
      rideCheckPolicy.enabled ? 'On' : 'Off';

  void _publishSnapshot() {
    reportSafetySnapshot(
      jsonEncode({
        'pinRequired': preferences.pinRequired,
        'contacts': contacts.length,
        'tripShareEnabled': preferences.tripShareEnabled,
        'rideCheckEnabled': rideCheckPolicy.enabled,
      }),
    );
  }

  void record(SafetyKind kind, {String? rideId}) {
    _events.add(SafetyEvent(kind: kind, at: DateTime.now(), rideId: rideId));
  }

  void shareTrip({String? rideId}) =>
      record(SafetyKind.shareTrip, rideId: rideId);

  Future<void> sos({String? rideId}) async {
    record(SafetyKind.sos, rideId: rideId);
    final id = rideId?.trim();
    if (id == null || id.isEmpty) return;
    try {
      await rideCheck.sos(rideId: id);
    } catch (error, stackTrace) {
      AppLog.warning(
        'safety.sos.backend_failed',
        extra: {'rideId': id, 'error': error.toString()},
      );
      AppLog.error(
        'safety.sos.backend_failed.detail',
        error: error,
        stackTrace: stackTrace,
        extra: {'rideId': id},
      );
    }
  }

  Future<void> load() async {
    loading = true;
    error = null;
    _publishSnapshot();
    notifyListeners();
    try {
      await _session.load();
      AppLog.info('safety.loaded', extra: {
        'contacts': contacts.length,
        'pinRequired': preferences.pinRequired,
      });
      _publishSnapshot();
      final pending = pendingRideCheckType();
      if (pending != null && pending.isNotEmpty) {
        final type = RideCheckEventType.values.firstWhere(
          (value) => value.name == pending,
          orElse: () => RideCheckEventType.unexpectedStop,
        );
        await rideCheck.simulate(type: type);
        clearPendingRideCheck();
      }
    } catch (err) {
      error = 'Could not load Safety preferences.';
      AppLog.error('safety.load_failed');
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> setPinRequired(bool value) async {
    error = null;
    try {
      await _session.patchPreferences(preferences.copyWith(pinRequired: value));
      record(SafetyKind.ridePin);
      AppLog.info('safety.pin.required', extra: {'on': value});
    } catch (_) {
      error = 'Could not update PIN verification.';
    }
    notifyListeners();
  }

  Future<void> rotatePin() async {
    error = null;
    try {
      await _session.rotatePin();
      AppLog.info('safety.pin.rotated');
    } catch (_) {
      error = 'Could not change PIN.';
    }
    notifyListeners();
  }

  Future<PinVerifyResult> verifyPin({
    required String rideId,
    required String pin,
  }) {
    return _session.verifyPin(rideId: rideId, pin: pin);
  }

  Future<void> addContact({
    required String name,
    required String phone,
    String relationship = 'Other',
    bool shareTrips = false,
  }) async {
    error = null;
    try {
      await _session.createContact(
        name: name,
        phone: phone,
        relationship: relationship,
        shareTrips: shareTrips,
      );
      AppLog.info('safety.contact.created');
    } on SafetyException catch (err) {
      error = err.message;
      rethrow;
    } catch (_) {
      error = 'Could not save that contact.';
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  Future<void> editContact(EmergencyContact contact) async {
    error = null;
    try {
      await _session.updateContact(contact);
    } on SafetyException catch (err) {
      error = err.message;
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  Future<void> removeContact(String id) async {
    error = null;
    try {
      await _session.deleteContact(id);
    } catch (_) {
      error = 'Could not delete that contact.';
    }
    notifyListeners();
  }

  Future<void> makePrimary(String id) async {
    await _session.setPrimary(id);
    notifyListeners();
  }

  Future<void> setTripShare({
    bool? enabled,
    TripShareMode? mode,
    List<String>? contactIds,
  }) async {
    error = null;
    try {
      await _session.patchPreferences(
        preferences.copyWith(
          tripShareEnabled: enabled,
          tripShareMode: mode,
          tripShareContactIds: contactIds,
        ),
      );
    } catch (_) {
      error = 'Could not update trip sharing.';
    }
    notifyListeners();
  }

  Future<TripShare> startShare(String rideId) async {
    final share = await _session.startShare(
      rideId,
      contactIds: preferences.tripShareContactIds.isEmpty
          ? null
          : preferences.tripShareContactIds,
    );
    record(SafetyKind.shareTrip, rideId: rideId);
    notifyListeners();
    return share;
  }

  Future<void> stopShare(String rideId) async {
    await _session.stopShare(rideId);
    notifyListeners();
  }

  Future<void> setRideCheck(bool enabled) async {
    error = null;
    try {
      await rideCheck.setEnabled(enabled);
    } catch (_) {
      error = 'Could not update RideCheck.';
    }
    notifyListeners();
  }
}
