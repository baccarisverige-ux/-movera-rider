// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:riding_app/constants/appassets.dart';
import 'package:riding_app/constants/appcolors.dart';
import 'package:riding_app/constants/appfontweight.dart';
import 'package:riding_app/presentation/driver/home/home.dart';
import 'package:riding_app/widgets/custom_btn.dart';
import 'package:riding_app/widgets/custom_text_widget.dart';
import 'package:riding_app/widgets/navigation_transition.dart';
import 'package:riding_app/widgets/responsive_size.dart';
import 'package:riding_app/widgets/sizedbox_extention.dart';

class DriverRideCompleted extends StatelessWidget {
  const DriverRideCompleted({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            55.height,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () {},
                  icon: Icon(
                    Icons.arrow_back_rounded,
                    size: ResSize.h * 20,
                    color: AppColor.primary,
                  ),
                ),
                TextWidget(
                  text: "Trip Completed",
                  color: AppColor.primary,
                  fontSize: 18,
                  fontWeight: fwSemiBold,
                ),
                IconButton(
                  onPressed: () {},
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  icon: SizedBox(),
                ),
              ],
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: screenHorizPadding),
              child: Column(
                children: [
                  50.height,
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: ResSize.w * 16,
                      vertical: ResSize.h * 24,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: AppColor.secondary,
                      boxShadow: [
                        BoxShadow(
                          offset: const Offset(0, 5),
                          spreadRadius: 0,
                          blurRadius: 20,
                          color: Color(0xff000000).withOpacity(0.08),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Image.asset(AppAssets.sucess, height: ResSize.h * 90),
                        4.height,
                        TextWidget(
                          text: "Trip Completed",
                          color: AppColor.primary,
                          fontSize: 18,
                          fontWeight: fwSemiBold,
                        ),
                        8.height,
                        TextWidget(
                          text: "\$20.00",
                          color: AppColor.primary,
                          fontSize: 36,
                          fontWeight: fwBold,
                        ),
                        2.height,
                        TextWidget(
                          text: "Paid via card",
                          color: AppColor.subtitle,
                          fontSize: 14,
                          fontWeight: fwNormal,
                        ),
                        24.height,
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextWidget(
                              text: "Your Earnings",
                              color: AppColor.primary,
                              fontSize: 18,
                              fontWeight: fwSemiBold,
                            ),
                            TextWidget(
                              text: "\$17.00",
                              color: AppColor.primary,
                              fontSize: 18,
                              fontWeight: fwSemiBold,
                            ),
                          ],
                        ),
                        10.height,
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: ResSize.w * 12,
                            vertical: ResSize.h * 10,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(40),
                            color: Color(0xffF1F1F1),
                          ),
                          child: Row(
                            children: [
                              TextWidget(
                                text: "Platform fee: \$3.00",
                                color: AppColor.subtitle,
                                fontSize: 14,
                                fontWeight: fwMedium,
                              ),
                            ],
                          ),
                        ),
                        24.height,
                        CustomButton(
                          centerContent: "Complete Trip",
                          onPressed: () {
                            Navigator.pushReplacement(
                              // ignore: use_build_context_synchronously
                              context,
                              BottomToTopTransition(const DriverHome()),
                            );
                          },
                        ),
                        16.height,
                        Center(
                          child: TextWidget(
                            textAlign: TextAlign.center,
                            text:
                                "Trip details will be saved in your earnings history.",
                            color: AppColor.subtitle,
                            fontSize: 14,
                            fontWeight: fwNormal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  16.height,
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      "Report an issue",
                      style: GoogleFonts.poppins(
                        fontSize: ResSize.setSp(18),
                        decoration: TextDecoration.underline,
                        decorationColor: AppColor.red,
                        fontWeight: fwSemiBold,
                        color: AppColor.red,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
