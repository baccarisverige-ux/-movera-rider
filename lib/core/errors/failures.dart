sealed class Failure {
  const Failure(this.message, {this.code, this.requestId});

  final String message;
  final String? code;
  final String? requestId;
}

class NetworkFailure extends Failure {
  const NetworkFailure([String message = 'Network unavailable', String? code])
      : super(message, code: code);
}

class TimeoutFailure extends Failure {
  const TimeoutFailure([String message = 'Request timed out', String? code])
      : super(message, code: code);
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([String message = 'Session expired', String? code])
      : super(message, code: code);
}

class LocationFailure extends Failure {
  const LocationFailure([String message = 'Location unavailable', String? code])
      : super(message, code: code);
}

class GeocodingFailure extends Failure {
  const GeocodingFailure([String message = 'Address lookup failed', String? code])
      : super(message, code: code);
}

class RouteFailure extends Failure {
  const RouteFailure([String message = 'Route unavailable', String? code])
      : super(message, code: code);
}

class BookingFailure extends Failure {
  const BookingFailure([String message = 'Booking failed', String? code])
      : super(message, code: code);
}

class PaymentFailure extends Failure {
  const PaymentFailure([String message = 'Payment failed', String? code])
      : super(message, code: code);
}

class RealtimeFailure extends Failure {
  const RealtimeFailure([String message = 'Live connection lost', String? code])
      : super(message, code: code);
}

class MapFailure extends Failure {
  const MapFailure([String message = 'Map failed to load', String? code])
      : super(message, code: code);
}

class UnknownFailure extends Failure {
  const UnknownFailure([String message = 'Something went wrong', String? code])
      : super(message, code: code);
}
