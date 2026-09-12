import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:movera_rider/core/auth/token_store.dart';
import 'package:movera_rider/core/logging/app_log.dart';

/// iOS Keychain / Android Keystore via flutter_secure_storage.
/// Web and Linux CI: memory only — not equivalent to Keychain/Keystore.
class SecureTokenStore implements TokenStore {
  SecureTokenStore({TokenStore? override}) : _override = override;

  final TokenStore? _override;
  final MemoryTokenStore _memory = MemoryTokenStore();
  static const _accessKey = 'movera_access_token';
  static const _refreshKey = 'movera_refresh_token';

  bool get _nativeSecure {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.android;
  }

  FlutterSecureStorage get _secure => const FlutterSecureStorage(
        aOptions: AndroidOptions(encryptedSharedPreferences: true),
      );

  TokenStore get _active {
    if (_override != null) return _override!;
    if (!_nativeSecure) return _memory;
    return _NativeSecureStore(_secure);
  }

  @override
  Future<void> save({required String access, required String refresh}) {
    if (kIsWeb) {
      AppLog.info(
        'auth.token.web',
        extra: {'note': 'web storage is not Keychain/Keystore'},
      );
    }
    return _active.save(access: access, refresh: refresh);
  }

  @override
  Future<String?> readAccess() => _active.readAccess();

  @override
  Future<String?> readRefresh() => _active.readRefresh();

  @override
  Future<void> clear() => _active.clear();
}

class _NativeSecureStore implements TokenStore {
  _NativeSecureStore(this._storage);
  final FlutterSecureStorage _storage;

  @override
  Future<void> save({required String access, required String refresh}) async {
    await _storage.write(key: SecureTokenStore._accessKey, value: access);
    await _storage.write(key: SecureTokenStore._refreshKey, value: refresh);
  }

  @override
  Future<String?> readAccess() =>
      _storage.read(key: SecureTokenStore._accessKey);

  @override
  Future<String?> readRefresh() =>
      _storage.read(key: SecureTokenStore._refreshKey);

  @override
  Future<void> clear() async {
    await _storage.delete(key: SecureTokenStore._accessKey);
    await _storage.delete(key: SecureTokenStore._refreshKey);
  }
}
