class ApiError implements Exception {
  const ApiError({
    required this.code,
    required this.message,
    this.requestId,
    this.statusCode,
    this.retryAfter,
  });

  final String code;
  final String message;
  final String? requestId;
  final int? statusCode;
  final Duration? retryAfter;

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isAuthenticationFailure => isUnauthorized || isForbidden;
  bool get isRetryable =>
      statusCode == 408 ||
      statusCode == 429 ||
      (statusCode != null && statusCode! >= 500) ||
      code == 'TIMEOUT' ||
      code == 'NETWORK';

  @override
  String toString() => 'ApiError($code, $message, $requestId)';
}
