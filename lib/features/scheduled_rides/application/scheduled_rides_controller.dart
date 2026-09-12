import 'package:movera_rider/app/di.dart';
import 'package:movera_rider/features/history/data/scheduled_ride_cards.dart';
import 'package:movera_rider/features/ride_booking/domain/ride_status.dart';
import 'package:movera_rider/features/scheduled_rides/data/scheduled_rides_repository.dart';
import 'package:movera_rider/shared/models/onboarding.dart';

class ScheduledRideSession {
  String pickup = 'Current location';
  String dropoff = '';
  List<String> stops = [];
  DateTime? scheduledAt;
  String timezone = 'Europe/Stockholm';
  String note = '';
  String paymentMethod = 'Wallet';
  String rideType = 'movera';
  String? quoteId;
  String? bookingId;
  String submissionStatus = 'idle';

  Future<String> confirm() async {
    submissionStatus = 'submitting';
    bookingId = await AppScope.instance.booking.requestBooking(
      rideType: rideType,
      paymentMethod: paymentMethod,
      scheduledAt: scheduledAt?.toIso8601String(),
    );
    submissionStatus = 'confirmed';
    return bookingId!;
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
