// ignore_for_file: deprecated_member_use

import 'dart:async';

import 'package:dotted_line/dotted_line.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:riding_app/constants/appassets.dart';
import 'package:riding_app/constants/appcolors.dart';
import 'package:riding_app/constants/appfontweight.dart';
import 'package:riding_app/widgets/custom_btn.dart';
import 'package:riding_app/widgets/custom_text_widget.dart';
import 'package:riding_app/widgets/responsive_size.dart';
import 'package:riding_app/widgets/sizedbox_extention.dart';
import 'package:circle_progress_bar/circle_progress_bar.dart';

class DriverRideRequestSheet extends StatefulWidget {
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final VoidCallback onTimeout;
  const DriverRideRequestSheet({
    super.key,
    required this.onAccept,
    required this.onDecline,
    required this.onTimeout,
  });

  @override
  State<DriverRideRequestSheet> createState() => _DriverRideRequestSheetState();
}

class _DriverRideRequestSheetState extends State<DriverRideRequestSheet> {
  static const int totalSeconds = 15;
  int remainingSeconds = totalSeconds;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  void startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingSeconds > 0) {
        setState(() {
          remainingSeconds--;
        });
      } else {
        timer.cancel();
        widget.onTimeout(); // 🔥 AUTO DECLINE
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

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
                    text: "Ride Request",
                    fontSize: 18,
                    fontWeight: fwSemiBold,
                    color: AppColor.primary,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Color(0xff0DC216).withOpacity(0.1),
                      border: Border.all(color: AppColor.primary, width: 1.6),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: ResSize.w * 16,
                        vertical: ResSize.h * 4,
                      ),
                      child: TextWidget(
                        text: "\$10.0",
                        fontSize: 18,
                        fontWeight: fwSemiBold,
                        color: AppColor.primary,
                      ),
                    ),
                  ),
                ],
              ),
              16.height,
              // From Location
              Row(
                children: [
                  SizedBox(
                    height: ResSize.h * 100,
                    child: Column(
                      children: [
                        Container(
                          height: ResSize.h * 34,
                          width: ResSize.w * 34,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColor.primary,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(6.0),
                            child: Image.asset(
                              AppAssets.location,
                              color: AppColor.secondary,
                            ),
                          ),
                        ),
                        Expanded(
                          child: DottedLine(
                            dashLength: 6,
                            dashGapLength: 8,
                            lineThickness: 1.4,
                            dashRadius: 0,
                            dashColor: AppColor.subtitle,
                            direction: Axis.vertical,
                          ),
                        ),
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
                      ],
                    ),
                  ),
                  8.width,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              "1901 Thornridge Cir. Shiloh, Hawaii 81063",
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: fwNormal,
                                color: AppColor.subtitle,
                              ),
                            ),
                            TextWidget(
                              text: "12 km away",
                              fontSize: 14,
                              fontWeight: fwNormal,
                              color: AppColor.subtitle,
                            ),
                          ],
                        ),
                        22.height,
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              "1901 Thornridge Cir. Shiloh, Hawaii 81063",
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: fwNormal,
                                color: AppColor.subtitle,
                              ),
                            ),
                            TextWidget(
                              text: "12 km away",
                              fontSize: 14,
                              fontWeight: fwNormal,
                              color: AppColor.subtitle,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              8.height,
              Divider(color: AppColor.border, thickness: 0.6), 8.height,
              Center(
                child: SizedBox(
                  height: ResSize.h * 75,
                  width: ResSize.w * 75,
                  child: CircleProgressBar(
                    strokeWidth: 6,
                    backgroundColor: Color(0xffE8E8E8),
                    foregroundColor: AppColor.primary,
                    value: remainingSeconds / totalSeconds, // 🔥 TIMER VALUE
                    child: Center(
                      child: TextWidget(
                        text: "${remainingSeconds}s",
                        fontSize: 20,
                        color: AppColor.primary,
                        fontWeight: fwSemiBold,
                      ),
                    ),
                  ),
                ),
              ),

              12.height,
              Center(
                child: TextWidget(
                  text: "Respond within 15 second",
                  fontSize: 14,
                  color: AppColor.subtitle,
                  fontWeight: fwNormal,
                ),
              ),
              24.height,
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      centerContent: "Accept",
                      fontSize: 16,
                      onPressed: widget.onAccept,
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
                      centerContent: "Decline",
                      onPressed: widget.onDecline,
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
