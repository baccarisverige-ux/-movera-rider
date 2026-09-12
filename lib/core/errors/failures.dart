sealed class Failure {
  const Failure(this.message, {this.code, this.requestId});

  final String message;
  final String? code;
  final String? requestId;
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Network unavailable']);
}

class TimeoutFailure extends Failure {
  const TimeoutFailure([super.message = 'Request timed out']);
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([super.message = 'Session expired']);
}

class LocationFailure extends Failure {
  const LocationFailure([super.message = 'Location unavailable']);
}

class GeocodingFailure extends Failure {
  const GeocodingFailure([super.message = 'Address lookup failed']);
}

class RouteFailure extends Failure {
  const RouteFailure([super.message = 'Route unavailable']);
}

class BookingFailure extends Failure {
  const BookingFailure([super.message = 'Booking failed']);
}

class PaymentFailure extends Failure {
  const PaymentFailure([super.message = 'Payment failed']);
}

class RealtimeFailure extends Failure {
  const RealtimeFailure([super.message = 'Live connection lost']);
}

class MapFailure extends Failure {
  const MapFailure([super.message = 'Map failed to load']);
}

class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'Something went wrong']);
}
