// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:riding_app/constants/appassets.dart';
import 'package:riding_app/constants/appcolors.dart';
import 'package:riding_app/constants/appfontweight.dart';
import 'package:riding_app/widgets/custom_btn.dart';
import 'package:riding_app/widgets/custom_text_widget.dart';
import 'package:riding_app/widgets/responsive_size.dart';
import 'package:riding_app/widgets/sizedbox_extention.dart';

class BookRideTripInProgress extends StatefulWidget {
  final VoidCallback onNext;
  const BookRideTripInProgress({super.key, required this.onNext});

  @override
  State<BookRideTripInProgress> createState() => _BookRideTripInProgressState();
}

class _BookRideTripInProgressState extends State<BookRideTripInProgress> {
  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        widget.onNext();
      }
    });
  }

  int selectedOption = 0;
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
                text: "Destination",
                color: AppColor.primary,
                fontSize: 18,
                fontWeight: fwSemiBold,
              ),
              2.height,
              TextWidget(
                text: "1901 Thornridge Cir. Shiloh....",
                color: AppColor.subtitle,
                fontSize: 16,
                fontWeight: fwNormal,
              ),
              12.height,
              Divider(color: AppColor.border, thickness: 1),
              12.height,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        height: ResSize.h * 22,
                        width: ResSize.w * 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xffF8F8F8),
                        ),
                        child: Center(
                          child: Image.asset(
                            AppAssets.time,
                            height: ResSize.h * 18,
                            color: AppColor.subtitle,
                          ),
                        ),
                      ),
                      3.width,
                      TextWidget(
                        text: "12 min left",
                        color: AppColor.primary,
                        fontSize: 12,
                        fontWeight: fwNormal,
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        height: ResSize.h * 22,
                        width: ResSize.w * 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xffF8F8F8),
                        ),
                        child: Center(
                          child: Image.asset(
                            AppAssets.distance,
                            height: ResSize.h * 18,
                            color: AppColor.subtitle,
                          ),
                        ),
                      ),
                      3.width,
                      TextWidget(
                        text: "4.3 Km",
                        color: AppColor.primary,
                        fontSize: 12,
                        fontWeight: fwNormal,
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      TextWidget(
                        text: "Current Rate: ",
                        color: AppColor.subtitle,
                        fontSize: 12,
                        fontWeight: fwNormal,
                      ),
                      TextWidget(
                        text: "\$20.00",
                        color: AppColor.primary,
                        fontSize: 12,
                        fontWeight: fwNormal,
                      ),
                    ],
                  ),
                ],
              ),
              12.height,
              Divider(color: AppColor.border, thickness: 1),
              24.height,

              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      textColor: AppColor.red,
                      borderColor: AppColor.red,
                      borderwidth: 1,
                      icon: Padding(
                        padding: EdgeInsets.only(right: ResSize.w * 10),
                        child: Image.asset(
                          AppAssets.sos,
                          height: ResSize.h * 20,
                        ),
                      ),
                      btncolor: Colors.transparent,
                      centerContent: "SOS",
                      onPressed: () {},
                      fontSize: 16,
                      height: 50,
                    ),
                  ),
                  16.width,
                  Expanded(
                    child: CustomButton(
                      textColor: AppColor.subtitle,
                      borderColor: AppColor.subtitle,
                      borderwidth: 1,
                      btncolor: Colors.transparent,
                      centerContent: "Share Trip",
                      onPressed: () {},
                      icon: Padding(
                        padding: EdgeInsets.only(right: ResSize.w * 10),
                        child: Image.asset(
                          AppAssets.share,
                          height: ResSize.h * 20,
                        ),
                      ),
                      fontSize: 16,
                      height: 50,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
