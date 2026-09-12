
class AppException implements Exception {
  const AppException(this.code, this.message, {this.requestId, this.recovery});

  final String code;
  final String message;
  final String? requestId;
  final String? recovery;

  @override
  String toString() => 'AppException($code, $message)';
}
