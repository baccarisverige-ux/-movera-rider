import 'package:flutter/material.dart';
import 'package:movera_rider/app/router/ride_navigator.dart';
import 'package:movera_rider/core/constants/appassets.dart';
import 'package:movera_rider/core/constants/appcolors.dart';
import 'package:movera_rider/core/constants/appfontweight.dart';
import 'package:movera_rider/features/ride_complete/application/ride_complete_controller.dart';
import 'package:movera_rider/features/ride_complete/presentation/add_tip.dart';
import 'package:movera_rider/features/ride_complete/presentation/driver_info.dart';
import 'package:movera_rider/features/ride_complete/presentation/give_review.dart';
import 'package:movera_rider/features/ride_booking/domain/ride_status.dart';
import 'package:movera_rider/features/ride_complete/presentation/trip_detail.dart';
import 'package:movera_rider/shared/widgets/custom_btn.dart';
import 'package:movera_rider/shared/widgets/custom_text_widget.dart';
import 'package:movera_rider/shared/widgets/responsive_size.dart';
import 'package:movera_rider/shared/widgets/sizedbox_extention.dart';

class RideCompleted extends StatefulWidget {
  const RideCompleted({super.key});

  @override
  State<RideCompleted> createState() => _RideCompletedState();
}

class _RideCompletedState extends State<RideCompleted> {
  @override
  void initState() {
    super.initState();
    RideCompleteController().close();
  }

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
                      RideNavigator.home(context, status: RideStatus.closed);
                    },
                    customBorder: const CircleBorder(),
                    child: Semantics(
                      button: true,
                      label: 'Back',
                      child: Container(
                        height: 48,
                        width: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColor.border,
                            width: 0.3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              // ignore: deprecated_member_use
                              color: Color(0xff999999).withValues(alpha: 0.1),
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
                  ),
                  Flexible(
                    child: TextWidget(
                      text: "You’re Arrived",
                      color: AppColor.black,
                      fontSize: 16,
                      fontWeight: fwSemiBold,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 48, width: 48),
                ],
              ),
            ),
            26.height,
            Container(
              color: AppColor.liteBlue,
              width: double.infinity,
              child: Padding(
                padding: EdgeInsetsGeometry.symmetric(vertical: ResSize.h * 11),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenHorizPadding),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: TextWidget(
                          text: "Make sure your belongings are not left behind",
                          color: AppColor.title,
                          fontSize: 12,
                          fontWeight: fwMedium,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      7.width,
                      Image.asset(
                        excludeFromSemantics: true,
                        AppAssets.eyeEmoji,
                        height: ResSize.h * 20,
                      ),
                    ],
                  ),
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
              child: CustomButton(
                centerContent: "Done",
                onPressed: () =>
                    RideNavigator.home(context, status: RideStatus.closed),
              ),
            ),
            24.height,
          ],
        ),
      ),
    );
  }
}
