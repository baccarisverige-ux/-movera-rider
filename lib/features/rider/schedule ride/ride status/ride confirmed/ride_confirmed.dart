import 'package:flutter/material.dart';
import 'package:movera_rider/core/constants/appassets.dart';
import 'package:movera_rider/core/constants/appcolors.dart';
import 'package:movera_rider/core/constants/appfontweight.dart';
import 'package:movera_rider/shared/presentation/chat/chat.dart';
import 'package:movera_rider/features/rider/schedule%20ride/ride%20status/cancel%20ride/cancel_ride.dart';
import 'package:movera_rider/features/rider/schedule%20ride/schedule_ride.dart';
import 'package:movera_rider/shared/widgets/custom_text_widget.dart';
import 'package:movera_rider/shared/widgets/navigation_transition.dart';
import 'package:movera_rider/shared/widgets/responsive_size.dart';
import 'package:movera_rider/shared/widgets/sizedbox_extention.dart';
import 'package:mobkit_dashed_border/mobkit_dashed_border.dart';

class ScheduleRideConfirmed extends StatelessWidget {
  const ScheduleRideConfirmed({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: screenHorizPadding),
          child: Column(
            children: [
              70.height,
              Center(
                child: Image.asset(
                  AppAssets.rideSummaryImg,
                  height: ResSize.h * 100,
                ),
              ),
              15.height,
              TextWidget(
                textAlign: TextAlign.center,
                text:
                    "We have received your request. Driver information will be shared before the ride starts.",
                fontSize: 14,
                fontWeight: fwNormal,
                color: AppColor.black,
              ),
              16.height,
              TextWidget(
                text: "STATUS",
                fontSize: 14,
                fontWeight: fwMedium,
                color: AppColor.black,
              ),
              TextWidget(
                text: "CONFIRMED",
                fontSize: 18,
                fontWeight: fwSemiBold,
                color: AppColor.green,
              ),
              16.height,
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: ResSize.w * 12,
                  vertical: ResSize.h * 9,
                ),
                decoration: BoxDecoration(
                  color: AppColor.liteBlue,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(5),
                    topRight: Radius.circular(5),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextWidget(
                      text: "Ride Route",
                      color: AppColor.title,
                      fontSize: 14,
                      fontWeight: fwSemiBold,
                    ),
                    8.height,
                    Row(
                      children: [
                        Container(
                          width: ResSize.w * 22,
                          height: ResSize.h * 22,
                          decoration: BoxDecoration(
                            color: AppColor.white,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Image.asset(
                              AppAssets.gpsFill,
                              height: ResSize.h * 15,
                              color: AppColor.green,
                            ),
                          ),
                        ),
                        12.width,
                        Expanded(
                          child: TextWidget(
                            text: "Club vista mare - dubai - uae",
                            color: AppColor.black,
                            fontSize: 14,
                            fontWeight: fwNormal,
                          ),
                        ),
                      ],
                    ),
                    12.height,
                    Row(
                      children: [
                        Container(
                          width: ResSize.w * 22,
                          height: ResSize.h * 22,
                          decoration: BoxDecoration(
                            color: AppColor.white,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Image.asset(
                              AppAssets.locationFill,
                              height: ResSize.h * 15,
                              color: AppColor.red,
                            ),
                          ),
                        ),
                        12.width,
                        Expanded(
                          child: TextWidget(
                            text: "jvc dubai united arab emirates",
                            color: AppColor.black,
                            fontSize: 14,
                            fontWeight: fwNormal,
                          ),
                        ),
                      ],
                    ),
                    16.height,
                  ],
                ),
              ),
              2.height,

              // Time left section
              Container(
                decoration: BoxDecoration(
                  color: AppColor.liteGrey,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(5),
                    bottomRight: Radius.circular(5),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: ResSize.w * 16,
                    vertical: ResSize.h * 8,
                  ),
                  child: Row(
                    children: [
                      Container(
                        height: ResSize.h * 22,
                        width: ResSize.w * 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColor.white,
                        ),
                        child: Center(
                          child: Image.asset(
                            AppAssets.dateTime,
                            height: ResSize.h * 13,
                            color: AppColor.title,
                          ),
                        ),
                      ),
                      8.width,
                      TextWidget(
                        text: "24th Feb 2025 - 10:11 PM",
                        color: AppColor.title,
                        fontSize: 12,
                        fontWeight: fwMedium,
                      ),
                    ],
                  ),
                ),
              ),
              8.height,
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Color(0xffF3F6FB),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(5),
                    topRight: Radius.circular(5),
                  ),
                ),
                child: Stack(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5),
                            color: AppColor.white,
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: ResSize.w * 12,
                            vertical: ResSize.h * 8,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextWidget(
                                text: "Executive SUV",
                                color: AppColor.black,
                                fontSize: 16,
                                fontWeight: fwBold,
                              ),
                              2.height,
                              TextWidget(
                                text: "Bentayga  Spur - AKE 95",
                                color: AppColor.subtitle,
                                fontSize: 16,
                                fontWeight: fwNormal,
                              ),
                              8.height,
                              Row(
                                children: [
                                  Image.asset(
                                    AppAssets.profile_2user,
                                    height: ResSize.h * 10,
                                  ),
                                  2.width,
                                  TextWidget(
                                    text: "4 Passengers",
                                    fontSize: 12,
                                    fontWeight: fwMedium,
                                    color: AppColor.darkTitle,
                                  ),
                                  8.width,
                                  Image.asset(
                                    AppAssets.suitcases,
                                    height: ResSize.h * 10,
                                  ),
                                  2.width,
                                  TextWidget(
                                    text: "3 Suitcases",
                                    fontSize: 12,
                                    fontWeight: fwMedium,
                                    color: AppColor.darkTitle,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        2.height,
                        Padding(
                          padding: EdgeInsets.only(left: ResSize.w * 31),
                          child: TextWidget(
                            text: "Total Payment",
                            color: AppColor.black,
                            fontSize: 12,
                            fontWeight: fwExtraBold,
                          ),
                        ),
                        3.height,
                        Padding(
                          padding: EdgeInsets.only(left: ResSize.w * 12),
                          child: Container(
                            width: ResSize.w * 128,
                            padding: EdgeInsets.symmetric(
                              vertical: ResSize.h * 6,
                            ),
                            decoration: BoxDecoration(
                              border: DashedBorder.fromBorderSide(
                                spaceLength: 3,
                                dashLength: 3,
                                side: BorderSide(
                                  // ignore: deprecated_member_use
                                  color: AppColor.border.withOpacity(0.7),
                                  width: 1,
                                ),
                              ),
                              borderRadius: BorderRadius.circular(5),
                              color: AppColor.white,
                            ),
                            child: Center(
                              child: TextWidget(
                                text: "\$250.70",
                                color: AppColor.green,
                                fontSize: 12,
                                fontWeight: fwBold,
                              ),
                            ),
                          ),
                        ),
                        6.height,
                      ],
                    ),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Padding(
                        padding: EdgeInsets.only(top: ResSize.h * 30),
                        child: Transform.translate(
                          offset: const Offset(8, 0),
                          child: Image.asset(
                            AppAssets.rideConfirmedImg,
                            height: ResSize.h * 83,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColor.liteGrey,
                  borderRadius: BorderRadius.only(
                    bottomRight: Radius.circular(5),
                    bottomLeft: Radius.circular(5),
                  ),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: ResSize.w * 12,
                  vertical: ResSize.h * 6,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextWidget(
                      text: "Payment Method:",
                      color: AppColor.title,
                      fontSize: 14,
                      fontWeight: fwSemiBold,
                    ),
                    TextWidget(
                      text: "Cash",
                      color: AppColor.title,
                      fontSize: 14,
                      fontWeight: fwNormal,
                    ),
                  ],
                ),
              ),
              28.height,
              InkWell(
                onTap: () {
                  Navigator.push(context, RightToLeftTransition(const Chat()));
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: ResSize.w * 12,
                    vertical: ResSize.h * 12,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Color(0xffF3F6FB),
                    border: Border.all(color: AppColor.black, width: 1),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Image.asset(AppAssets.chat, height: ResSize.h * 25),
                      TextWidget(
                        text: "START CHAT",
                        color: AppColor.title,
                        fontSize: 12,
                        fontWeight: fwSemiBold,
                      ),
                      SizedBox(height: ResSize.h * 25, width: ResSize.w * 25),
                    ],
                  ),
                ),
              ),
              24.height,
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  InkWell(
                    onTap: () {
                      showCancelRideReasonDialog(context);
                    },
                    child: buildButton(
                      image: AppAssets.closeCircle,
                      textColor: AppColor.red,
                      title: "CANCEL",
                    ),
                  ),
                  20.width,
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        BottomToTopTransition(ScheduleRide()),
                      );
                    },
                    child: buildButton(
                      image: AppAssets.edit,
                      title: "RESCHEDULE",
                    ),
                  ),
                  20.width,
                  InkWell(
                    onTap: () {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    child: buildButton(image: AppAssets.home, title: "HOME"),
                  ),
                ],
              ),
              24.height,
            ],
          ),
        ),
      ),
    );
  }

  Widget buildButton({String? image, title, Color textColor = AppColor.title}) {
    return Column(
      children: [
        Container(
          height: ResSize.h * 50,
          width: ResSize.w * 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xffF3F6FB),
          ),
          child: Center(
            child: Image.asset(
              image!,
              height: ResSize.h * 27,
              color: textColor,
            ),
          ),
        ),
        8.height,
        TextWidget(
          text: title,
          fontSize: 12,
          fontWeight: fwMedium,
          color: textColor,
        ),
      ],
    );
  }
}
