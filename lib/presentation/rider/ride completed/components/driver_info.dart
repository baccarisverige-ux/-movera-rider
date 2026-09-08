import 'package:flutter/material.dart';
import 'package:movera/constants/appassets.dart';
import 'package:movera/constants/appcolors.dart';
import 'package:movera/constants/appfontweight.dart';
import 'package:movera/widgets/custom_text_widget.dart';
import 'package:movera/widgets/responsive_size.dart';
import 'package:movera/widgets/sizedbox_extention.dart';

class RideCompletedDriverInfo extends StatelessWidget {
  const RideCompletedDriverInfo({super.key});

  @override
  Widget build(BuildContext context) {
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
              text: "Merle Feeney",
              color: AppColor.title,
              fontSize: 20,
              fontWeight: fwSemiBold,
            ),
          ),
          2.height,
          Center(
            child: TextWidget(
              text: "Toyota HR-V . L-2323 F",
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
                text: "#IL19051950015",
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
                text: "22 May, 2025 . 12:30 pm ",
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
