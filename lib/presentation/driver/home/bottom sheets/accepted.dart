// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:riding_app/constants/appassets.dart';
import 'package:riding_app/constants/appcolors.dart';
import 'package:riding_app/constants/appfontweight.dart';
import 'package:riding_app/widgets/custom_btn.dart';
import 'package:riding_app/widgets/custom_text_widget.dart';
import 'package:riding_app/widgets/responsive_size.dart';
import 'package:riding_app/widgets/sizedbox_extention.dart';

class DriverRideAcceptedSheet extends StatefulWidget {
  final VoidCallback onArrived;
  const DriverRideAcceptedSheet({super.key, required this.onArrived});

  @override
  State<DriverRideAcceptedSheet> createState() =>
      _DriverRideRequestSheetState();
}

class _DriverRideRequestSheetState extends State<DriverRideAcceptedSheet> {
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
              TextWidget(
                text: "Pickup Address",
                fontSize: 18,
                fontWeight: fwSemiBold,
                color: AppColor.primary,
              ),
              6.height,
              TextWidget(
                text: "1901 Thornridge Cir. Shiloh....",
                fontSize: 16,
                fontWeight: fwMedium,
                color: AppColor.subtitle,
              ),
              6.height,
              Row(
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
              TextWidget(
                text: "Passenger Detail",
                color: AppColor.primary,
                fontSize: 18,
                fontWeight: fwSemiBold,
              ),

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
                centerContent: "Arrived",
                onPressed: widget.onArrived,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
