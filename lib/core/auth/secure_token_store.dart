import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
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
    try {
      WidgetsBinding.instance;
    } catch (_) {
      return false;
    }
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
  Future<void> save({required String access, required String refresh}) async {
    if (kIsWeb) {
      AppLog.info(
        'auth.token.web',
        extra: {'note': 'web storage is not Keychain/Keystore'},
      );
    }
    try {
      await _active.save(access: access, refresh: refresh);
    } catch (_) {
      await _memory.save(access: access, refresh: refresh);
    }
  }

  @override
  Future<String?> readAccess() async {
    try {
      return await _active.readAccess();
    } catch (_) {
      return _memory.readAccess();
    }
  }

  @override
  Future<String?> readRefresh() async {
    try {
      return await _active.readRefresh();
    } catch (_) {
      return _memory.readRefresh();
    }
  }

  @override
  Future<void> clear() async {
    try {
      await _active.clear();
    } catch (_) {
      await _memory.clear();
    }
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
