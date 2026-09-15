import 'dart:convert';

import 'package:movera_rider/core/storage/preferences_store.dart';
import 'package:movera_rider/features/profile/domain/profile.dart';

class ProfileRepository {
  ProfileRepository({this.storageKey = 'movera_profile_v1'});

  static const _legacyName = 'Ben Gleason';
  static const _legacyEmail = 'ben.gleason@movera.se';
  static const _legacyPhone = '+46 70 123 45 67';
  static const _legacyPhoto = 'assets/images/profile_img.png';

  final String storageKey;
  RiderProfileData _profile = RiderProfileData.defaults();
  bool _hydrated = false;

  RiderProfileData get current => _profile;

  String displayName() {
    final name = _profile.name.trim();
    return name.isEmpty ? 'Profile not set' : name;
  }

  Future<void> hydrate() async {
    if (_hydrated) return;
    _hydrated = true;
    try {
      final prefs = await PreferencesStore.load();
      final raw = prefs.getString(storageKey);
      if (raw == null || raw.isEmpty) return;
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        final loaded = RiderProfileData.fromJson(
          Map<String, dynamic>.from(decoded),
        );
        final sanitized = _sanitizeLegacyDemoProfile(loaded);
        _profile = sanitized;
        if (!_sameProfile(loaded, sanitized)) {
          await prefs.setString(storageKey, jsonEncode(sanitized.toJson()));
        }
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

  RiderProfileData _sanitizeLegacyDemoProfile(RiderProfileData source) {
    final hasLegacyIdentitySeed =
        source.email == _legacyEmail && source.phone == _legacyPhone;
    final hasLegacyLoginSeed = source.logins.length == 2 &&
        source.logins[0].device == 'This browser' &&
        source.logins[0].place == 'Stockholm, Sweden' &&
        source.logins[0].source == 'Movera Web' &&
        source.logins[0].current &&
        source.logins[1].device == 'iPhone' &&
        source.logins[1].place == 'Stockholm, Sweden' &&
        source.logins[1].source == 'Movera iOS' &&
        !source.logins[1].current;

    return source.copyWith(
      name: source.name == _legacyName ? '' : source.name,
      email: source.email == _legacyEmail ? '' : source.email,
      phone: source.phone == _legacyPhone ? '' : source.phone,
      gender: hasLegacyIdentitySeed && source.gender == 'Man'
          ? 'Prefer not to say'
          : source.gender,
      photoAsset: source.photoAsset == _legacyPhoto ? '' : source.photoAsset,
      passwordUpdatedAt: source.passwordUpdatedAt == DateTime(2025, 11, 4)
          ? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true)
          : source.passwordUpdatedAt,
      appleConnected: hasLegacyIdentitySeed ? false : source.appleConnected,
      logins: hasLegacyLoginSeed ? const [] : source.logins,
    );
  }

  bool _sameProfile(RiderProfileData a, RiderProfileData b) {
    return jsonEncode(a.toJson()) == jsonEncode(b.toJson());
  }
}
