import 'package:flutter/foundation.dart';
import 'package:movera_rider/app/config/env.dart';
import 'package:movera_rider/app/di.dart';

/// The single switch for the in-app Add card form.
///
/// The form only saves a local reference (no payment partner tokenises or
/// authorises the card), so it is offered only where mock transport is
/// allowed (demo, dev, test). Staging and production hide every Add card
/// entry until a payment partner's secure card element replaces the form.
abstract final class CardEntryPolicy {
  static bool allowedFor(AppEnv environment) => environment.allowsMockTransport;

  /// Whether Add card is offered in this build.
  static bool get enabled =>
      debugOverride ?? allowedFor(AppScope.instance.environment);

  /// Tests flip this to check the staging/production layout.
  @visibleForTesting
  static bool? debugOverride;
}
