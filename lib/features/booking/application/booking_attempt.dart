import 'package:movera_rider/core/api/idempotency.dart';

/// One logical booking operation.
///
/// The idempotency key belongs to the operation, not to an individual HTTP
/// request. Retries of the same intent therefore reuse the same key until the
/// operation succeeds or the rider changes the booking intent.
///
/// RIDE-3: the intent is the rider's trip (route, category, payment), not the
/// quote, which is refreshed after every failure. A retry within
/// [reuseWindow] of the first try is the same booking; after that a new
/// booking gets a new key.
class BookingAttempt {
  BookingAttempt({required this.intentKey, DateTime? startedAt})
    : idempotencyKey = newIdempotencyKey('booking'),
      startedAt = startedAt ?? DateTime.now();

  /// How long an unfinished booking may be retried under the same key.
  static const reuseWindow = Duration(minutes: 5);

  final String intentKey;
  final String idempotencyKey;
  final DateTime startedAt;

  bool matches(String otherIntentKey, {DateTime? now}) =>
      intentKey == otherIntentKey &&
      (now ?? DateTime.now()).difference(startedAt) < reuseWindow;
}
