import 'package:flutter/material.dart';
import 'package:movera_rider/app/di.dart';
import 'package:movera_rider/features/ride_booking/domain/ride_status.dart';
import 'package:movera_rider/core/constants/appassets.dart';
import 'package:movera_rider/core/constants/appcolors.dart';
import 'package:movera_rider/core/constants/appfontweight.dart';
import 'package:movera_rider/shared/models/onboarding.dart';
import 'package:movera_rider/features/scheduled_rides/presentation/ride_pending.dart';
import 'package:movera_rider/shared/widgets/custom_btn.dart';
import 'package:movera_rider/shared/widgets/custom_text_widget.dart';
import 'package:movera_rider/shared/widgets/navigation_transition.dart';
import 'package:movera_rider/shared/widgets/responsive_size.dart';
import 'package:movera_rider/shared/widgets/sizedbox_extention.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

class ScheduleConfirmBooking extends StatefulWidget {
  final Widget body;
  const ScheduleConfirmBooking({super.key, required this.body});

  @override
  State<ScheduleConfirmBooking> createState() => _ScheduleConfirmBookingState();
}

class _ScheduleConfirmBookingState extends State<ScheduleConfirmBooking> {
  List<OnBoardingModel> paymentMethods = [
    OnBoardingModel(
      image: AppAssets.wallet,
      title: "\$7.00",
      subTitle: "Wallet",
    ),
    OnBoardingModel(image: AppAssets.cash, title: "\$7.00", subTitle: "Cash"),
    OnBoardingModel(
      image: AppAssets.mastercard,
      title: "\$7.00",
      subTitle: "Master card",
    ),
    OnBoardingModel(
      image: AppAssets.applepay,
      title: "\$7.00",
      subTitle: "Apple pay",
    ),
    OnBoardingModel(
      image: AppAssets.paypal,
      title: "\$7.00",
      subTitle: "Paypal",
    ),
  ];
  int selectedMethod = 0;
  @override
  Widget build(BuildContext context) {
    return SlidingUpPanel(
      color: AppColor.white,
      backdropColor: Colors.transparent,
      margin: EdgeInsets.all(0),
      minHeight: ResSize.h * 322,
      padding: EdgeInsets.symmetric(
        horizontal: screenHorizPadding,
        vertical: ResSize.h * 16,
      ),
      boxShadow: [],
      isDraggable: true,
      defaultPanelState: PanelState.CLOSED,
      maxHeight: MediaQuery.of(context).size.height * 0.85,
      parallaxEnabled: false,
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(12),
        topRight: Radius.circular(12),
      ),
      panelBuilder: (ScrollController sc) => panelColumn(sc),
      // panelBuilder: (ScrollController sc) => panelColumn(sc, context),
      body: widget.body,
    );
  }

  Widget panelColumn(ScrollController sc) {
    return SingleChildScrollView(
      controller: sc,
      child: Column(
        children: [
          Center(
            child: Transform.scale(
              scale: 1.3,
              child: Image.asset(
                AppAssets.scheduleRideCar,
                height: ResSize.h * 90,
              ),
            ),
          ),
          0.height,
          TextWidget(
            text: "Comfort SUV",
            fontSize: 20,
            fontWeight: fwBold,
            color: AppColor.darkTitle,
          ),
          4.height,
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(AppAssets.profile_2user, height: ResSize.h * 14),
              4.width,
              TextWidget(
                text: "4 Passengers",
                fontSize: 12,
                fontWeight: fwMedium,
                color: AppColor.darkTitle,
              ),
              10.width,
              Image.asset(AppAssets.suitcases, height: ResSize.h * 14),
              4.width,
              TextWidget(
                text: "3 Suitcases",
                fontSize: 12,
                fontWeight: fwMedium,
                color: AppColor.darkTitle,
              ),
            ],
          ),
          22.height,
          Row(
            children: [
              TextWidget(
                fontSize: 14,
                fontWeight: fwMedium,
                text: "Payment methods",
                color: AppColor.title,
              ),
            ],
          ),
          14.height,
          ...List.generate(paymentMethods.length, (index) {
            return Padding(
              padding: EdgeInsets.only(top: index == 0 ? 0 : ResSize.h * 8),
              child: InkWell(
                onTap: () {
                  setState(() {
                    selectedMethod = index;
                  });
                },

                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: ResSize.w * 10,
                    vertical: ResSize.h * 8,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: selectedMethod == index
                        ? Border.all(color: Colors.transparent, width: 0)
                        : Border.all(color: AppColor.border, width: 0.4),
                    color: selectedMethod == index
                        ? AppColor.title
                        : Colors.transparent,
                  ),
                  child: Row(
                    children: [
                      index > 1
                          ? Image.asset(
                              paymentMethods[index].image,
                              height: ResSize.h * 25,
                            )
                          : Image.asset(
                              paymentMethods[index].image,
                              height: ResSize.h * 25,
                              color: selectedMethod == index
                                  ? AppColor.white
                                  : AppColor.title,
                            ),
                      12.width,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextWidget(
                              fontSize: 18,
                              fontWeight: fwSemiBold,
                              text: paymentMethods[index].title,
                              color: selectedMethod == index
                                  ? AppColor.whiteText
                                  : AppColor.title,
                            ),
                            TextWidget(
                              fontSize: 12,
                              fontWeight: fwNormal,
                              text: paymentMethods[index].subTitle,
                              color: selectedMethod == index
                                  ? Color(0xffE2E2E2)
                                  : AppColor.subtitle,
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: ResSize.h * 18,
                        color: selectedMethod == index
                            ? AppColor.white
                            : AppColor.subtitle,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),

          // ✅ Rest of your code untouched
          16.height,
          CustomButton(
            centerContent: "CONFIRM",
            onPressed: () {
              AppScope.instance.ride.restoreFromBackend(
                RideStatus.bookingRequested,
              );
              Navigator.push(
                context,
                BottomToTopTransition(const ScheduleRidePending()),
              );
            },
          ),
          22.height,
        ],
      ),
    );
  }
}
