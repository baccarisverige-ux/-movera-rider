import 'package:flutter/material.dart';
import 'package:movera_rider/core/constants/appcolors.dart';
import 'package:movera_rider/core/constants/appfontweight.dart';
import 'package:movera_rider/features/ride_booking/data/driver_repository.dart';
import 'package:movera_rider/shared/widgets/custom_text_widget.dart';
import 'package:movera_rider/shared/widgets/responsive_size.dart';
import 'package:movera_rider/shared/widgets/sizedbox_extention.dart';

class RideCompletedTripDetail extends StatelessWidget {
  const RideCompletedTripDetail({super.key});

  @override
  Widget build(BuildContext context) {
    final trip = TripReceiptRepository().last();
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenHorizPadding),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: ResSize.w * 20,
              vertical: ResSize.h * 9,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Color(0xffFAFAFA),
              border: Border.all(color: AppColor.border, width: 0.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextWidget(
                  text: "Trip Details",
                  color: AppColor.title,
                  fontSize: 16,
                  fontWeight: fwSemiBold,
                ),
                12.height,
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextWidget(
                      text: "Pickup location",
                      color: AppColor.title,
                      fontSize: 14,
                      fontWeight: fwMedium,
                    ),
                    TextWidget(
                      text: trip.pickup,
                      color: AppColor.subtitle,
                      fontSize: 14,
                      fontWeight: fwMedium,
                    ),
                  ],
                ),
                8.height,
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,

                  children: [
                    TextWidget(
                      text: "Destination",
                      color: AppColor.title,
                      fontSize: 14,
                      fontWeight: fwMedium,
                    ),
                    TextWidget(
                      text: trip.destination,
                      color: AppColor.subtitle,
                      fontSize: 14,
                      fontWeight: fwMedium,
                    ),
                  ],
                ),
                8.height,

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,

                  children: [
                    TextWidget(
                      text: "Total Payment",
                      color: AppColor.title,
                      fontSize: 14,
                      fontWeight: fwMedium,
                    ),
                    TextWidget(
                      text: trip.total,
                      color: AppColor.subtitle,
                      fontSize: 14,
                      fontWeight: fwMedium,
                    ),
                  ],
                ),
                8.height,

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,

                  children: [
                    TextWidget(
                      text: "Payment method",
                      color: AppColor.title,
                      fontSize: 14,
                      fontWeight: fwMedium,
                    ),
                    TextWidget(
                      text: trip.method,
                      color: AppColor.subtitle,
                      fontSize: 14,
                      fontWeight: fwMedium,
                    ),
                  ],
                ),
                8.height,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
