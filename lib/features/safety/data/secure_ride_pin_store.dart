import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// iOS Keychain / Android Keystore for the ride-verification PIN digits,
/// mirroring core/auth/secure_token_store.dart's platform split: native
/// secure storage on iOS/Android, a no-op everywhere else (web, desktop,
/// tests) so those platforms keep behaving exactly as before — the PIN
/// stays in the caller's existing SharedPreferences-backed cache there,
/// same as this codebase already accepts for auth tokens.
class SecureRidePinStore {
  const SecureRidePinStore() : _forceNativeSecure = null, _fakeStorage = null;

  /// Test-only: exercises the same scrub/restore logic against an in-memory
  /// map instead of the real Keychain/Keystore plugin, which has no
  /// platform-channel handler under `flutter test` and hangs rather than
  /// failing fast.
  @visibleForTesting
  SecureRidePinStore.fake()
    : _forceNativeSecure = true,
      _fakeStorage = <String, String>{};

  static const _key = 'movera_ride_pin';
  final bool? _forceNativeSecure;
  final Map<String, String>? _fakeStorage;

  bool get _nativeSecure {
    if (_forceNativeSecure != null) return _forceNativeSecure;
    if (kIsWeb) return false;
    try {
      WidgetsBinding.instance;
    } catch (_) {
      return false;
    }
    return defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.android;
  }

  bool get isNativeSecure => _nativeSecure;

  Future<String?> read() async {
    if (!_nativeSecure) return null;
    final fake = _fakeStorage;
    if (fake != null) return fake[_key];
    try {
      return await const FlutterSecureStorage(
        aOptions: AndroidOptions(encryptedSharedPreferences: true),
      ).read(key: _key);
    } catch (_) {
      return null;
    }
  }

  Future<void> write(String pin) async {
    if (!_nativeSecure) return;
    final fake = _fakeStorage;
    if (fake != null) {
      fake[_key] = pin;
      return;
    }
    try {
      await const FlutterSecureStorage(
        aOptions: AndroidOptions(encryptedSharedPreferences: true),
      ).write(key: _key, value: pin);
    } catch (_) {}
  }
}
