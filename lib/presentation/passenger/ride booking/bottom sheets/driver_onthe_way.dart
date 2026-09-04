// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movera_rider/constants/appassets.dart';
import 'package:movera_rider/constants/appcolors.dart';
import 'package:movera_rider/constants/appfontweight.dart';
import 'package:movera_rider/widgets/custom_btn.dart';
import 'package:movera_rider/widgets/custom_text_widget.dart';
import 'package:movera_rider/widgets/responsive_size.dart';
import 'package:movera_rider/widgets/sizedbox_extention.dart';

class BookRideDriverOnTheWay extends StatefulWidget {
  final VoidCallback onNext;
  const BookRideDriverOnTheWay({super.key, required this.onNext});

  @override
  State<BookRideDriverOnTheWay> createState() => _BookRideDriverOnTheWayState();
}

class _BookRideDriverOnTheWayState extends State<BookRideDriverOnTheWay> {
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
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: ResSize.w * 14,
                  vertical: ResSize.h * 10,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColor.border, width: 1),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextWidget(
                          text: "L - 2323 F",
                          color: AppColor.primary,
                          fontSize: 20,
                          fontWeight: fwSemiBold,
                        ),
                        4.height,
                        TextWidget(
                          text: "Toyota HR-V",
                          color: AppColor.subtitle,
                          fontSize: 14,
                          fontWeight: fwMedium,
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        TextWidget(
                          text: "Standard",
                          color: AppColor.primary,
                          fontSize: 16,
                          fontWeight: fwMedium,
                        ),
                        2.height,
                        TextWidget(
                          text: "up to 4 seats",
                          color: AppColor.subtitle,
                          fontSize: 14,
                          fontWeight: fwNormal,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              12.height,

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextWidget(
                          text: "Pickup Address",
                          color: AppColor.primary,
                          fontSize: 18,
                          fontWeight: fwSemiBold,
                        ),
                        6.height,
                        Text(
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          "1901 Thornridge Cir. Shiloh....",
                          style: GoogleFonts.poppins(
                            color: AppColor.primary,
                            fontSize: 16,
                            fontWeight: fwMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                  20.width,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            height: ResSize.h * 30,
                            width: ResSize.w * 30,
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
                          4.width,
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
                    ],
                  ),
                ],
              ),
              16.height,

              TextWidget(
                text: "Driver Detail",
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
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextWidget(
                            text: "Morgan Mill",
                            color: AppColor.primary,
                            fontSize: 16,
                            fontWeight: fwMedium,
                          ),
                          2.height,
                          Row(
                            children: [
                              Icon(Icons.star_rounded, color: Colors.amber),
                              4.width,
                              TextWidget(
                                text: "4.8",
                                color: AppColor.subtitle,
                                fontSize: 14,
                                fontWeight: fwNormal,
                              ),
                            ],
                          ),
                        ],
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
                textColor: AppColor.red,
                borderColor: AppColor.red,
                borderwidth: 1,
                btncolor: Colors.transparent,
                centerContent: "Cancel Ride",
                onPressed: () {},
                fontSize: 16,
                height: 50,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
