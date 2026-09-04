// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:riding_app/constants/appassets.dart';
import 'package:riding_app/constants/appcolors.dart';
import 'package:riding_app/constants/appfontweight.dart';
import 'package:riding_app/widgets/custom_text_widget.dart';
import 'package:riding_app/widgets/responsive_size.dart';
import 'package:riding_app/widgets/sizedbox_extention.dart';

class DriverProfile extends StatelessWidget {
  const DriverProfile({super.key});

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
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: Icon(
                    Icons.arrow_back_rounded,
                    size: ResSize.h * 20,
                    color: AppColor.primary,
                  ),
                ),
                TextWidget(
                  text: "Profile",
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
                  24.height,
                  Center(
                    child: Container(
                      height: ResSize.h * 100,
                      width: ResSize.w * 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        image: DecorationImage(
                          image: AssetImage(AppAssets.profile),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  4.height,

                  Center(
                    child: TextWidget(
                      text: "Mac Mort",
                      color: AppColor.primary,
                      fontSize: 18,
                      fontWeight: fwSemiBold,
                    ),
                  ),
                  2.height,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextWidget(
                        text: "Rating:",
                        color: AppColor.subtitle,
                        fontSize: 14,
                        fontWeight: fwNormal,
                      ),
                      4.width,
                      Icon(
                        Icons.star_rounded,
                        size: ResSize.h * 16,
                        color: AppColor.yellow,
                      ),
                      2.width,
                      TextWidget(
                        text: "4.8",
                        color: AppColor.subtitle,
                        fontSize: 14,
                        fontWeight: fwNormal,
                      ),
                    ],
                  ),
                  30.height,
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: ResSize.w * 16,
                      vertical: ResSize.h * 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColor.secondary,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          offset: const Offset(0, 5),
                          color: Color(0xff000000).withOpacity(0.08),
                          blurRadius: 20,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    height: ResSize.h * 40,
                                    width: ResSize.w * 40,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Color(0xffF6F6F6),
                                    ),
                                    child: Center(
                                      child: Image.asset(
                                        AppAssets.trip,
                                        height: ResSize.h * 20,
                                      ),
                                    ),
                                  ),
                                  8.width,
                                  TextWidget(
                                    text: "400 Trips",
                                    color: AppColor.primary,
                                    fontSize: 18,
                                    fontWeight: fwSemiBold,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: ResSize.h * 45,
                          child: VerticalDivider(
                            color: AppColor.border,
                            thickness: 1,
                          ),
                        ),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TextWidget(
                                text: "Member since 2020",
                                color: Color(0xff1E1E1E),
                                fontSize: 14,
                                fontWeight: fwMedium,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  24.height,
                  Container(
                    padding: EdgeInsets.all(ResSize.w * 16),
                    decoration: BoxDecoration(
                      color: AppColor.secondary,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          offset: const Offset(0, 5),
                          color: Color(0xff000000).withOpacity(0.08),
                          blurRadius: 20,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextWidget(
                          text: "Personal Info",
                          color: AppColor.primary,
                          fontSize: 18,
                          fontWeight: fwSemiBold,
                        ),
                        12.height,
                        _buildRow("Name", "Mac mort"),
                        14.height,
                        _buildRow("Phone", "+92 322122322"),
                        14.height,
                        _buildRow("Email", "example23@gmail.com"),
                      ],
                    ),
                  ),
                  24.height,
                  Container(
                    padding: EdgeInsets.all(ResSize.w * 16),
                    decoration: BoxDecoration(
                      color: AppColor.secondary,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          offset: const Offset(0, 5),
                          color: Color(0xff000000).withOpacity(0.08),
                          blurRadius: 20,
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextWidget(
                          text: "Vehicle Detail",
                          color: AppColor.primary,
                          fontSize: 18,
                          fontWeight: fwSemiBold,
                        ),
                        12.height,
                        _buildRow("Car", "Toyota Corolla"),
                        14.height,
                        _buildRow("Color", "Black"),
                        14.height,
                        _buildRow("Plate Number", "ABC 123"),
                        14.height,
                        _buildRow("Ride Category", "Standard"),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            40.height,
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextWidget(
          text: label,
          fontSize: 14,
          fontWeight: fwNormal,
          color: AppColor.subtitle,
        ),
        TextWidget(
          text: amount,
          fontSize: 14,
          fontWeight: fwMedium,
          color: AppColor.primary,
        ),
      ],
    );
  }
}
