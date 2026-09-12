import 'package:flutter/material.dart';
import 'package:movera_rider/core/constants/appassets.dart';
import 'package:movera_rider/core/constants/appcolors.dart';
import 'package:movera_rider/core/constants/appfontweight.dart';
import 'package:movera_rider/features/ride_booking/data/driver_repository.dart';
import 'package:movera_rider/shared/widgets/custom_text_widget.dart';
import 'package:movera_rider/shared/widgets/responsive_size.dart';
import 'package:movera_rider/shared/widgets/sizedbox_extention.dart';

class RideCompletedDriverInfo extends StatelessWidget {
  const RideCompletedDriverInfo({super.key});

  @override
  Widget build(BuildContext context) {
    final driver = DriverRepository().current();
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenHorizPadding),
      child: Column(
        children: [
          SizedBox(
            height: ResSize.h * 74,
            width: ResSize.w * 160,
            child: Stack(
              children: [
                Image.asset(AppAssets.driverCar, height: ResSize.h * 74),
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: EdgeInsets.only(right: ResSize.w * 7),
                    child: Image.asset(
                      AppAssets.driverImg,
                      height: ResSize.h * 62,
                    ),
                  ),
                ),
              ],
            ),
          ),
          14.height,
          Center(
            child: TextWidget(
              text: driver.name,
              color: AppColor.title,
              fontSize: 20,
              fontWeight: fwSemiBold,
            ),
          ),
          2.height,
          Center(
            child: TextWidget(
              text: driver.vehicle,
              color: AppColor.title,
              fontSize: 14,
              fontWeight: fwMedium,
            ),
          ),
          24.height,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextWidget(
                text: "Trip completed",
                color: AppColor.title,
                fontSize: 14,
                fontWeight: fwMedium,
              ),
              TextWidget(
                text: driver.rideNumber,
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
                text: "Date & Time",
                color: AppColor.title,
                fontSize: 14,
                fontWeight: fwMedium,
              ),
              TextWidget(
                text: driver.completedAt,
                color: AppColor.subtitle,
                fontSize: 14,
                fontWeight: fwMedium,
              ),
            ],
          ),
          8.height,
        ],
      ),
    );
  }
}
