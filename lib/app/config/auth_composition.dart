import 'package:movera_rider/app/config/env.dart';

abstract final class AuthComposition {
  static void validate(AppEnv environment) {
    if (environment.isProduction && !environment.authRequired) {
      throw StateError('Production requires authentication.');
    }
  }
}
