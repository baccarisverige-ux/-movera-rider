import 'dart:convert';

import 'package:movera_rider/core/storage/preferences_store.dart';
import 'package:movera_rider/features/profile/domain/profile.dart';

class ProfileRepository {
  ProfileRepository({this.storageKey = 'movera_profile_v1'});

  final String storageKey;
  RiderProfileData _profile = RiderProfileData.defaults();
  bool _hydrated = false;

  RiderProfileData get current => _profile;

  String displayName() => _profile.name;

  String referralCode() => 'RID2ESSA';

  Future<void> hydrate() async {
    if (_hydrated) return;
    _hydrated = true;
    try {
      final prefs = await PreferencesStore.load();
      final raw = prefs.getString(storageKey);
      if (raw == null || raw.isEmpty) return;
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        _profile = RiderProfileData.fromJson(
          Map<String, dynamic>.from(decoded),
        );
      }
    } catch (_) {}
  }

  Future<RiderProfileData> save(RiderProfileData next) async {
    _profile = next;
    try {
      final prefs = await PreferencesStore.load();
      await prefs.setString(storageKey, jsonEncode(next.toJson()));
    } catch (_) {}
    return _profile;
  }
}
