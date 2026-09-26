class OtpChallenge {
  const OtpChallenge({
    required this.phone,
    required this.requestId,
    required this.sessionId,
    required this.expiresAt,
    required this.retryAfter,
  });

  final String phone;
  final String requestId;
  final String sessionId;
  final DateTime expiresAt;
  final Duration retryAfter;

  bool get isExpired => !expiresAt.isAfter(DateTime.now().toUtc());

  Duration get remaining {
    final value = expiresAt.difference(DateTime.now().toUtc());
    return value.isNegative ? Duration.zero : value;
  }
}
