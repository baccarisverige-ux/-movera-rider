import 'package:movera_rider/app/di.dart';
import 'package:movera_rider/features/history/data/scheduled_ride_cards.dart';
import 'package:movera_rider/features/ride_booking/domain/ride_status.dart';
import 'package:movera_rider/features/scheduled_rides/data/scheduled_rides_repository.dart';
import 'package:movera_rider/shared/models/onboarding.dart';

class ScheduledRideSession {
  String pickup = 'Current location';
  String dropoff = '';
  DateTime? scheduledAt;
  String paymentMethod = 'Wallet';

  Future<String> confirm() {
    return AppScope.instance.booking.requestBooking(
      rideType: 'movera',
      paymentMethod: paymentMethod,
    );
  }

  void markScheduled() {
    AppScope.instance.ride.restoreFromBackend(RideStatus.bookingRequested);
  }
}

class ScheduledRidesController {
  ScheduledRidesController({
    CancelReasonCatalog? reasons,
    SchedulePaymentCatalog? payments,
    ScheduledRideCatalog? cards,
  })  : _reasons = reasons ?? CancelReasonCatalog(),
        _payments = payments ?? SchedulePaymentCatalog(),
        _cards = cards ?? ScheduledRideCatalog();

  final CancelReasonCatalog _reasons;
  final SchedulePaymentCatalog _payments;
  final ScheduledRideCatalog _cards;

  List<String> cancelReasons() => _reasons.all();
  List<OnBoardingModel> paymentMethods() => _payments.methods();
  List<ScheduledRideCard> confirmed() => _cards.confirmed();
  ScheduledRideCard pending() => _cards.pending();
}
