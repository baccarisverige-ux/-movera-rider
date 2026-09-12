import 'package:flutter/foundation.dart';
import 'package:movera_rider/core/auth/token_store.dart';
import 'package:movera_rider/core/logging/app_log.dart';

/// Native: Keychain/Keystore via flutter_secure_storage when wired.
/// Web: in-memory only — not equivalent to iOS Keychain / Android Keystore.
class SecureTokenStore implements TokenStore {
  SecureTokenStore({TokenStore? native}) : _memory = MemoryTokenStore();

  final MemoryTokenStore _memory;

  @override
  Future<void> save({required String access, required String refresh}) {
    if (kIsWeb) {
      AppLog.info(
        'auth.token.web',
        extra: {'note': 'web storage is not Keychain/Keystore'},
      );
    }
    return _memory.save(access: access, refresh: refresh);
  }

  @override
  Future<String?> readAccess() => _memory.readAccess();

  @override
  Future<String?> readRefresh() => _memory.readRefresh();

  @override
  Future<void> clear() => _memory.clear();
}
