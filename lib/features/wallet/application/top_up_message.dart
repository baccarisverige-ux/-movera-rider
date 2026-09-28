import 'package:movera_rider/core/api/rider_error_kind.dart';
import 'package:movera_rider/features/wallet/application/wallet_controller.dart';

/// What to tell the rider after a top-up, or null when it went through.
///
/// Every message says whether money was taken. A failed top-up used to show
/// nothing at all.
String? topUpMessage(TopUpOutcome outcome) {
  switch (outcome) {
    case TopUpCredited():
      return null;
    case TopUpUnconfirmed():
      return "We couldn't confirm your top-up. If it went through, it will "
          "show in your balance — trying again won't charge you twice.";
    case TopUpNotCharged(declined: true):
      return "The payment was declined, so you weren't charged.";
    case TopUpNotCharged(:final error):
      final kind =
          error == null ? RiderErrorKind.unknown : riderErrorKind(error);
      switch (kind) {
        case RiderErrorKind.offline:
          return "No connection, so the top-up didn't go through. You "
              "weren't charged — try again when you're back online.";
        case RiderErrorKind.rateLimited:
          final wait = error == null ? null : riderRetryWait(error);
          return "Too many tries. You weren't charged — try again "
              "${wait == null ? 'in a moment' : 'in $wait'}.";
        case RiderErrorKind.serverTrouble:
          return "Movera is having trouble right now. You weren't charged — "
              'try again in a moment.';
        case RiderErrorKind.refused:
        case RiderErrorKind.unknown:
          return "The top-up didn't go through. You weren't charged — try "
              'again.';
      }
  }
}
