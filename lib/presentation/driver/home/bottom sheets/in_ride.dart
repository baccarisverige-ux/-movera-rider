// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:riding_app/constants/appassets.dart';
import 'package:riding_app/constants/appcolors.dart';
import 'package:riding_app/constants/appfontweight.dart';
import 'package:riding_app/widgets/custom_btn.dart';
import 'package:riding_app/widgets/custom_text_widget.dart';
import 'package:riding_app/widgets/responsive_size.dart';
import 'package:riding_app/widgets/sizedbox_extention.dart';

class DriverInRideSheet extends StatefulWidget {
  final VoidCallback onEndRide;
  const DriverInRideSheet({super.key, required this.onEndRide});

  @override
  State<DriverInRideSheet> createState() => _DriverInRideSheetState();
}

class _DriverInRideSheetState extends State<DriverInRideSheet> {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: AppColor.secondary,
          boxShadow: [
            BoxShadow(
              color: Color(0xff000000).withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 5),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: ResSize.w * 12,
            vertical: ResSize.h * 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextWidget(
                    text: "Destination",
                    color: AppColor.primary,
                    fontSize: 18,
                    fontWeight: fwSemiBold,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      color: Color(0xff838383).withOpacity(0.08),
                      border: Border.all(color: AppColor.primary, width: 1.6),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: ResSize.w * 12,
                        vertical: ResSize.h * 6,
                      ),
                      child: TextWidget(
                        text: "Estimated Fare: \$10.00",
                        fontSize: 13,
                        fontWeight: fwMedium,
                        color: AppColor.primary,
                      ),
                    ),
                  ),
                ],
              ),
              5.height,
              Row(
                children: [
                  Container(
                    height: ResSize.h * 34,
                    width: ResSize.w * 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xffF6F6F6),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Image.asset(
                        AppAssets.location,
                        color: Color(0xffC9C9C9),
                      ),
                    ),
                  ),
                  8.width,
                  Expanded(
                    child: Text(
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      "1901 Thornridge Cir. Shiloh, Hawaii 81063",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: fwNormal,
                        color: AppColor.subtitle,
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Container(
                        height: ResSize.h * 30,
                        width: ResSize.w * 30,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xffEEEEEE),
                        ),
                        child: Center(
                          child: Image.asset(
                            AppAssets.time,
                            height: ResSize.h * 18,
                            color: AppColor.primary,
                          ),
                        ),
                      ),
                      8.width,
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextWidget(
                            text: "Arrive In",
                            color: AppColor.subtitle,
                            fontSize: 12,
                            fontWeight: fwNormal,
                          ),
                          TextWidget(
                            text: "EST:12mins",
                            color: AppColor.primary,
                            fontSize: 14,
                            fontWeight: fwNormal,
                          ),
                        ],
                      ),
                    ],
                  ),
                  24.width,
                  Row(
                    children: [
                      Container(
                        height: ResSize.h * 30,
                        width: ResSize.w * 30,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xffEEEEEE),
                        ),
                        child: Center(
                          child: Image.asset(
                            AppAssets.distance,
                            height: ResSize.h * 18,
                            color: AppColor.primary,
                          ),
                        ),
                      ),
                      8.width,
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextWidget(
                            text: "Distance",
                            color: AppColor.subtitle,
                            fontSize: 12,
                            fontWeight: fwNormal,
                          ),
                          TextWidget(
                            text: "14 Km",
                            color: AppColor.primary,
                            fontSize: 14,
                            fontWeight: fwNormal,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              12.height,
              Divider(color: AppColor.border, thickness: 0.6),

              12.height,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        height: ResSize.h * 50,
                        width: ResSize.w * 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          image: DecorationImage(
                            image: AssetImage(AppAssets.profile),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      8.width,
                      TextWidget(
                        text: "Morgan Mill",
                        color: AppColor.primary,
                        fontSize: 16,
                        fontWeight: fwMedium,
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        height: ResSize.h * 44,
                        width: ResSize.w * 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColor.primary, width: 1),
                        ),
                        child: Center(
                          child: Image.asset(
                            AppAssets.chat,
                            height: ResSize.h * 22,
                          ),
                        ),
                      ),
                      10.width,
                      Container(
                        height: ResSize.h * 44,
                        width: ResSize.w * 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColor.primary, width: 1),
                        ),
                        child: Center(
                          child: Image.asset(
                            AppAssets.call,
                            height: ResSize.h * 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              24.height,
              CustomButton(
                centerContent: "End Ride",
                onPressed: widget.onEndRide,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
