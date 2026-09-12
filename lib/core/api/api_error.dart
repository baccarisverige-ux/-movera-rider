class ApiError implements Exception {
  const ApiError({
    required this.code,
    required this.message,
    this.requestId,
    this.statusCode,
  });

  final String code;
  final String message;
  final String? requestId;
  final int? statusCode;

  @override
  String toString() => 'ApiError($code, $message, $requestId)';
}
