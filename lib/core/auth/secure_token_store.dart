import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:movera_rider/core/auth/token_store.dart';
import 'package:movera_rider/core/logging/app_log.dart';

/// iOS Keychain / Android Keystore via flutter_secure_storage.
/// Web, tests, and Linux CI: memory only — not equivalent to Keychain/Keystore.
class SecureTokenStore implements TokenStore {
  SecureTokenStore({TokenStore? override}) : _override = override;

  final TokenStore? _override;
  final MemoryTokenStore _memory = MemoryTokenStore();
  static const accessKey = 'movera_access_token';
  static const refreshKey = 'movera_refresh_token';

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

  TokenStore get _active {
    if (_override != null) return _override!;
    if (!_nativeSecure) return _memory;
    return _NativeSecureStore(
      const FlutterSecureStorage(
        aOptions: AndroidOptions(encryptedSharedPreferences: true),
      ),
    );
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
}

class _NativeSecureStore implements TokenStore {
  _NativeSecureStore(this._storage);
  final FlutterSecureStorage _storage;

  @override
  Future<void> save({required String access, required String refresh}) async {
    await _storage.write(key: SecureTokenStore.accessKey, value: access);
    await _storage.write(key: SecureTokenStore.refreshKey, value: refresh);
  }

  @override
  Future<String?> readAccess() =>
      _storage.read(key: SecureTokenStore.accessKey);

  @override
  Future<String?> readRefresh() =>
      _storage.read(key: SecureTokenStore.refreshKey);

  @override
  Future<void> clear() async {
    await _storage.delete(key: SecureTokenStore.accessKey);
    await _storage.delete(key: SecureTokenStore.refreshKey);
  }
}
