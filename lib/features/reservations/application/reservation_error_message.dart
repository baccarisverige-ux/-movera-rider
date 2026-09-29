import 'package:movera_rider/core/api/rider_error_kind.dart';

/// What the rider was doing to a scheduled ride when it failed.
enum ReservationAction { book, edit, cancel }

/// A specific, honest message for a failed scheduled-ride action, always
/// saying what state the ride is left in.
///
/// These failures used to be silent: the button stopped spinning and nothing
/// told the rider whether the ride was booked, changed or still on.
String reservationErrorMessage(Object error, ReservationAction action) {
  final kind = riderErrorKind(error);
  return switch (action) {
    ReservationAction.cancel => switch (kind) {
      RiderErrorKind.offline =>
        "No connection, so your cancellation wasn't confirmed. Your ride is "
            "still booked — try again when you're back online.",
      RiderErrorKind.rateLimited =>
        'Too many tries. Your ride is still booked — '
            '${_tryAgain(error)}.',
      RiderErrorKind.serverTrouble =>
        'Movera is having trouble right now, so your ride is still booked. '
            'Try cancelling again in a moment.',
      RiderErrorKind.refused => "This ride can't be cancelled right now.",
      RiderErrorKind.unknown =>
        "Couldn't cancel. Your ride is still booked — try again.",
    },
    ReservationAction.book => switch (kind) {
      RiderErrorKind.offline =>
        "No connection, so your booking wasn't confirmed. Check Upcoming "
            'rides before trying again.',
      RiderErrorKind.rateLimited =>
        "Too many tries, so your booking wasn't confirmed. "
            '${_capitalised(_tryAgain(error))}.',
      RiderErrorKind.serverTrouble =>
        "Movera is having trouble right now and couldn't confirm your "
            'booking. Check Upcoming rides before trying again.',
      RiderErrorKind.refused =>
        "Movera couldn't book this ride. Check the time and details, then "
            'try again.',
      RiderErrorKind.unknown =>
        "Couldn't confirm your booking. Check Upcoming rides before trying "
            'again.',
    },
    ReservationAction.edit => switch (kind) {
      RiderErrorKind.offline =>
        "No connection, so your changes weren't confirmed. Check your ride's "
            'details before trying again.',
      RiderErrorKind.rateLimited =>
        "Too many tries, so your changes weren't confirmed. "
            '${_capitalised(_tryAgain(error))}.',
      RiderErrorKind.serverTrouble =>
        "Movera is having trouble right now, so your changes weren't "
            "confirmed. Check your ride's details before trying again.",
      RiderErrorKind.refused => "This ride can't be changed right now.",
      RiderErrorKind.unknown =>
        "Couldn't save your changes. Check your ride's details before trying "
            'again.',
    },
  };
}

String _tryAgain(Object error) {
  final wait = riderRetryWait(error);
  return wait == null ? 'try again in a moment' : 'try again in $wait';
}

String _capitalised(String text) => text[0].toUpperCase() + text.substring(1);
