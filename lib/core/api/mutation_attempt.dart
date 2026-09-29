import 'package:movera_rider/core/api/idempotency.dart';

/// Owns one idempotency key for one logical mutation intent.
///
/// A failed retry of the same intent reuses the key. Success clears it so a
/// later, genuinely new mutation can receive a fresh key.
class MutationAttempt {
  MutationAttempt(this.operation);

  final String operation;
  String? _intent;
  String? _key;

  String keyFor(String intent) {
    if (_intent == intent && _key != null) return _key!;
    _intent = intent;
    _key = newIdempotencyKey(operation);
    return _key!;
  }

  void succeeded(String intent) {
    if (_intent != intent) return;
    _intent = null;
    _key = null;
  }

  void reset() {
    _intent = null;
    _key = null;
  }
}
