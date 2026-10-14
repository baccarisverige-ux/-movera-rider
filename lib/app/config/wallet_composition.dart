import 'package:movera_rider/app/config/env.dart';

/// The wallet balance must be owned by a real, server-backed ledger in a
/// release composition. A client-local double editable via
/// SharedPreferences/localStorage (see `WalletStore`) is not an
/// authoritative record of real money and must never be what a release
/// build trusts.
///
/// Wired into `AppScope`'s composition (ARCH-6): release builds switch the
/// wallet off (`FeatureFlags.release`) and compose a disabled ledger, so this
/// passes; turning the flag on without a server-backed
/// `WalletBalanceRepository` makes every release launch fail here.
abstract final class WalletComposition {
  static void validate({
    required AppEnv environment,
    required bool usesLocalBalanceSource,
  }) {
    if (environment.isReleaseLike && usesLocalBalanceSource) {
      throw StateError(
        'Client-local wallet balance is forbidden in ${environment.flavor.name}',
      );
    }
  }
}
