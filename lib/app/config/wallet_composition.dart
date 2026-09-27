import 'package:movera_rider/app/config/env.dart';

/// The wallet balance must be owned by a real, server-backed ledger in a
/// release composition. A client-local double editable via
/// SharedPreferences/localStorage (see `WalletStore`) is not an
/// authoritative record of real money and must never be what a release
/// build trusts.
///
/// This is deliberately not wired into [AppScope]'s live composition yet:
/// no server-backed [WalletBalanceSource] exists in this repo, so doing
/// that today would make every production launch throw at startup instead
/// of catching a real regression. It exists, and is tested, so that the
/// day a real implementation lands, wiring this in is a one-line change
/// with a guard already proven correct — see R-043 in the Batch 8 audit.
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
