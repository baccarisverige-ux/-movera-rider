import 'package:movera_rider/core/api/idempotency.dart';

/// One logical booking operation.
///
/// The idempotency key belongs to the operation, not to an individual HTTP
/// request. Retries of the same intent therefore reuse the same key until the
/// operation succeeds or the rider changes the booking intent.
class BookingAttempt {
  BookingAttempt({required this.intentKey})
    : idempotencyKey = newIdempotencyKey('booking');

  final String intentKey;
  final String idempotencyKey;

  bool matches(String otherIntentKey) => intentKey == otherIntentKey;
}
