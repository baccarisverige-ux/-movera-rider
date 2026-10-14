import 'package:movera_rider/core/auth/token_store.dart';

/// Not a browser: native builds use Keychain/Keystore.
TokenStore? createWebSessionTokenStore() => null;
