import 'package:flutter/material.dart';
import 'package:movera/constants/appassets.dart';
import 'package:movera/constants/appcolors.dart';
import 'package:movera/constants/appfontweight.dart';
import 'package:movera/widgets/custom_text_widget.dart';
import 'package:movera/widgets/responsive_size.dart';
import 'package:movera/widgets/sizedbox_extention.dart';

class ConfirmedsRide extends StatelessWidget {
  const ConfirmedsRide({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: Column(
        children: [
          ...List.generate(2, (index) {
            return Padding(
              padding: EdgeInsets.only(top: index == 0 ? 0 : ResSize.h * 16),
              child: Column(
                children: [
                  SizedBox(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: screenHorizPadding,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header with car info
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        TextWidget(
                                          text: "BMW X7",
                                          color: AppColor.title,
                                          fontSize: 20,
                                          fontWeight: fwBold,
                                        ),
                                        12.width,
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: ResSize.w * 7,
                                            vertical: ResSize.h * 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Color(0xff333333),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: TextWidget(
                                            text: "Confirmed",
                                            color: AppColor.whiteText,
                                            fontSize: 12,
                                            fontWeight: fwBold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    6.height,
                                    TextWidget(
                                      text: "10 Jun 25, 10:30 am",
                                      color: AppColor.subtitle,
                                      fontSize: 14,
                                      fontWeight: fwSemiBold,
                                    ),
                                  ],
                                ),
                              ),
                              Transform.scale(
                                scale: 1.15,
                                child: Image.asset(
                                  AppAssets.car,
                                  height: ResSize.h * 69,
                                ),
                              ),
                            ],
                          ),

                          // Route section
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
                                vertical: ResSize.h * 9,
                              ),
                              child: Row(
                                children: [
                                  Image.asset(
                                    AppAssets.hourglass,
                                    height: ResSize.h * 20,
                                    color: AppColor.title,
                                  ),
                                  8.width,
                                  TextWidget(
                                    text: "Time left",
                                    color: AppColor.title,
                                    fontSize: 14,
                                    fontWeight: fwNormal,
                                  ),
                                  Spacer(),
                                  TextWidget(
                                    text: "2 days 2hrs",
                                    color: AppColor.title,
                                    fontSize: 14,
                                    fontWeight: fwNormal,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  index == 1
                      ? SizedBox()
                      : Column(
                          children: [
                            16.height,
                            Container(
                              height: ResSize.h * 6,
                              color: Color(0xffFAFAFA),
                            ),
                          ],
                        ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
