enum PaymentStatus {
  notStarted,
  pending,
  processing,
  succeeded,
  failed,
  refunded,
  partiallyRefunded,
}

/// ARCH-10: the P1 payment vocabulary is
/// `pending -> authorized -> captured | failed | refunded`. The Rider enum is
/// mapped onto it here, the one adapter, and both P1 names and the gateway's
/// current Stripe-like strings parse back. `processing` is read as
/// `authorized` until the backend contract says otherwise.
extension PaymentStatusWire on PaymentStatus {
  /// The P1 name, or null before any payment exists.
  String? get wireName => switch (this) {
    PaymentStatus.notStarted => null,
    PaymentStatus.pending => 'pending',
    PaymentStatus.processing => 'authorized',
    PaymentStatus.succeeded => 'captured',
    PaymentStatus.failed => 'failed',
    PaymentStatus.refunded || PaymentStatus.partiallyRefunded => 'refunded',
  };

  static PaymentStatus? parse(Object? raw) {
    if (raw is! String) return null;
    return switch (raw.trim().toLowerCase()) {
      'pending' || 'requires_confirmation' => PaymentStatus.pending,
      'authorized' || 'processing' => PaymentStatus.processing,
      'captured' || 'succeeded' => PaymentStatus.succeeded,
      'failed' || 'cancelled' => PaymentStatus.failed,
      'refunded' => PaymentStatus.refunded,
      'partially_refunded' => PaymentStatus.partiallyRefunded,
      _ => null,
    };
  }
}
