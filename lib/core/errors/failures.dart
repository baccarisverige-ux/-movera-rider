sealed class Failure {
  const Failure(this.message, {this.code});

  final String message;
  final String? code;
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Network unavailable', super.code]);
}

class LocationFailure extends Failure {
  const LocationFailure([super.message = 'Location unavailable', super.code]);
}

class PaymentFailure extends Failure {
  const PaymentFailure([super.message = 'Payment failed', super.code]);
}

class BookingFailure extends Failure {
  const BookingFailure([super.message = 'Booking failed', super.code]);
}
