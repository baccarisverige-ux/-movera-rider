import 'package:flutter/material.dart';
import 'package:movera_rider/core/constants/appassets.dart';
import 'package:movera_rider/core/constants/appcolors.dart';
import 'package:movera_rider/core/constants/appfontweight.dart';
import 'package:movera_rider/features/rider/ride%20completed/components/add_tip.dart';
import 'package:movera_rider/features/rider/ride%20completed/components/driver_info.dart';
import 'package:movera_rider/features/rider/ride%20completed/components/give_review.dart';
import 'package:movera_rider/features/rider/ride%20completed/components/trip_detail.dart';
import 'package:movera_rider/shared/widgets/custom_btn.dart';
import 'package:movera_rider/shared/widgets/custom_text_widget.dart';
import 'package:movera_rider/shared/widgets/responsive_size.dart';
import 'package:movera_rider/shared/widgets/sizedbox_extention.dart';

class RideCompleted extends StatelessWidget {
  const RideCompleted({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            50.height,
            Padding(
              padding: EdgeInsets.symmetric(horizontal: screenHorizPadding),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Container(
                      height: ResSize.h * 30,
                      width: ResSize.w * 30,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColor.border, width: 0.3),
                        boxShadow: [
                          BoxShadow(
                            // ignore: deprecated_member_use
                            color: Color(0xff999999).withOpacity(0.1),
                            blurRadius: 40,
                            offset: const Offset(0, 4),
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          Icons.arrow_back_ios_rounded,
                          color: AppColor.title,
                          size: ResSize.h * 16,
                        ),
                      ),
                    ),
                  ),
                  TextWidget(
                    text: "You’re Arrived",
                    color: AppColor.black,
                    fontSize: 16,
                    fontWeight: fwSemiBold,
                  ),
                  SizedBox(height: ResSize.h * 30, width: ResSize.w * 30),
                ],
              ),
            ),
            26.height,
            Container(
              color: AppColor.liteBlue,
              width: double.infinity,
              child: Padding(
                padding: EdgeInsetsGeometry.symmetric(vertical: ResSize.h * 11),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextWidget(
                      text: "Make sure your belonging are not left behind",
                      color: AppColor.title,
                      fontSize: 12,
                      fontWeight: fwMedium,
                    ),
                    7.width,
                    Image.asset(AppAssets.eyeEmoji, height: ResSize.h * 20),
                  ],
                ),
              ),
            ),
            24.height,
            RideCompletedDriverInfo(),
            24.height,
            RideCompletedGiveReview(),
            24.height,
            RideCompletedAddTip(),
            24.height,
            RideCompletedTripDetail(),
            24.height,
            Padding(
              padding: EdgeInsets.symmetric(horizontal: screenHorizPadding),
              child: CustomButton(centerContent: "Done", onPressed: () {}),
            ),
            24.height,
          ],
        ),
      ),
    );
  }
}
