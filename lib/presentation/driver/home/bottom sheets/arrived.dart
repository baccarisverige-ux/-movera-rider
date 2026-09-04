// ignore_for_file: deprecated_member_use

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

class DriverArrivedSheet extends StatefulWidget {
  final VoidCallback onStartRide;
  final VoidCallback onCancel;
  const DriverArrivedSheet({
    super.key,
    required this.onStartRide,
    required this.onCancel,
  });

  @override
  State<DriverArrivedSheet> createState() => _DriverArrivedSheetState();
}

class _DriverArrivedSheetState extends State<DriverArrivedSheet> {
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
                text: "Passenger Detail",
                color: AppColor.primary,
                fontSize: 18,
                fontWeight: fwSemiBold,
              ),

              12.height,
              Row(
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
                ],
              ),
              12.height,
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
                        Expanded(
                          child: DottedLine(
                            dashLength: 6,
                            dashGapLength: 8,
                            lineThickness: 1.4,
                            dashRadius: 0,
                            dashColor: Color(0xffC9C9C9),
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
                            TextWidget(
                              text: "From",
                              fontSize: 14,
                              fontWeight: fwNormal,
                              color: AppColor.subtitle,
                            ),
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
                          ],
                        ),
                        22.height,
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextWidget(
                              text: "To",
                              fontSize: 14,
                              fontWeight: fwNormal,
                              color: AppColor.subtitle,
                            ),
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
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              24.height,
              CustomButton(
                centerContent: "Start Ride",
                onPressed: widget.onStartRide,
              ),
              6.height,
              Center(
                child: TextButton(
                  onPressed: widget.onCancel,
                  child: Text(
                    "Cancel Ride",
                    style: GoogleFonts.poppins(
                      fontSize: ResSize.setSp(16),
                      decoration: TextDecoration.underline,
                      fontWeight: fwMedium,
                      decorationColor: AppColor.red,
                      color: AppColor.red,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
