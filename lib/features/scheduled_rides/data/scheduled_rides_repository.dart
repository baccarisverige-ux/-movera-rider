import 'package:movera_rider/core/constants/appassets.dart';
import 'package:movera_rider/shared/models/onboarding.dart';

class CancelReasonCatalog {
  List<String> all() => const [
        'Change of plans',
        'Found cheaper ride',
        'Unable to contact driver',
        'Incorrect pickup location',
        'Payment issues',
        'Duplicate booking by mistake',
        'Driver asked to cancel',
        'Emergency or urgent matter',
        'Weather conditions',
        'Ride no longer needed',
        'Other',
      ];
}

class SchedulePaymentCatalog {
  List<OnBoardingModel> methods() => [
        OnBoardingModel(
          image: AppAssets.wallet,
          title: '\$7.00',
          subTitle: 'Wallet',
        ),
        OnBoardingModel(
          image: AppAssets.cash,
          title: '\$7.00',
          subTitle: 'Cash',
        ),
        OnBoardingModel(
          image: AppAssets.mastercard,
          title: '\$7.00',
          subTitle: 'Master card',
        ),
        OnBoardingModel(
          image: AppAssets.applepay,
          title: '\$7.00',
          subTitle: 'Apple pay',
        ),
        OnBoardingModel(
          image: AppAssets.paypal,
          title: '\$7.00',
          subTitle: 'Paypal',
        ),
      ];
}
