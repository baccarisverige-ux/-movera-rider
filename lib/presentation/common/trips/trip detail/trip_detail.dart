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

class TripDetail extends StatefulWidget {
  const TripDetail({super.key});

  @override
  State<TripDetail> createState() => _TripDetailState();
}

class _TripDetailState extends State<TripDetail> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Map Section
            Stack(
              children: [
                Container(
                  height: ResSize.h * 300,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    image: DecorationImage(
                      image: AssetImage(AppAssets.map), // Use your map asset
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  top: ResSize.h * 50,
                  left: ResSize.w * 20,
                  right: ResSize.w * 20,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: EdgeInsets.all(ResSize.w * 8),
                          decoration: BoxDecoration(
                            color: AppColor.secondary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                offset: const Offset(0, 2),
                                color: Color(0xff000000).withOpacity(0.1),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.arrow_back,
                            color: AppColor.primary,
                            size: ResSize.h * 24,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Content Section
            Transform.translate(
              offset: const Offset(0, -35),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColor.secondary,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(ResSize.w * 24),
                    topRight: Radius.circular(ResSize.w * 24),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: ResSize.w * 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      24.height,

                      // Trip Summary Section
                      TextWidget(
                        text: "Trip Summary",
                        fontSize: 18,
                        fontWeight: fwSemiBold,
                        color: AppColor.primary,
                      ),
                      12.height,

                      // Time and Distance Row
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
                          children: [
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
                                    ],
                                  ),
                                ),
                                8.width,
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
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
                            8.height,
                            Divider(thickness: 0.6, color: AppColor.border),
                            8.height,
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                          ],
                        ),
                      ),

                      24.height,

                      // Fare Summary Section
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
                              text: "Fare Summary",
                              fontSize: 18,
                              fontWeight: fwSemiBold,
                              color: AppColor.primary,
                            ),
                            16.height,
                            _buildFareRow("Base Fare", "\$10.00"),
                            14.height,
                            _buildFareRow("Distance", "\$10.00"),
                            14.height,
                            _buildFareRow("Time", "\$10.00"),
                            14.height,
                            _buildFareRow("Tax", "\$10.00"),
                            14.height,
                            _buildFareRow("Discount", "\$1.00"),
                            16.height,
                            Divider(color: AppColor.border, thickness: 1),
                            14.height,
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                TextWidget(
                                  text: "Total Fare",
                                  fontSize: 18,
                                  fontWeight: fwSemiBold,
                                  color: AppColor.primary,
                                ),
                                TextWidget(
                                  text: "\$30.00",
                                  fontSize: 18,
                                  fontWeight: fwSemiBold,
                                  color: AppColor.primary,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      24.height,

                      // Driver Info Section
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
                            Row(
                              children: [
                                Container(
                                  width: ResSize.w * 51,
                                  height: ResSize.w * 51,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    image: DecorationImage(
                                      image: AssetImage(AppAssets.profile),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                12.width,
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    TextWidget(
                                      text: "Morgan Mill",
                                      fontSize: 16,
                                      fontWeight: fwMedium,
                                      color: AppColor.primary,
                                    ),
                                    4.height,
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.star_rounded,
                                          color: Color(0xFFFAC22F),
                                          size: ResSize.h * 18,
                                        ),
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
                            20.height,

                            // Vehicle Info
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    TextWidget(
                                      text: "L - 2323 F",
                                      fontSize: 20,
                                      fontWeight: fwSemiBold,
                                      color: AppColor.primary,
                                    ),
                                    4.height,
                                    TextWidget(
                                      text: "Toyota HR-V",
                                      fontSize: 14,
                                      fontWeight: fwMedium,
                                      color: AppColor.subtitle,
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    TextWidget(
                                      text: "Standard",
                                      fontSize: 16,
                                      fontWeight: fwSemiBold,
                                      color: AppColor.primary,
                                    ),
                                    4.height,
                                    TextWidget(
                                      text: "up to 4 seats",
                                      fontSize: 14,
                                      fontWeight: fwNormal,
                                      color: AppColor.subtitle,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      24.height,

                      // Payment Method Section
                      TextWidget(
                        text: "Payment Method",
                        fontSize: 18,
                        fontWeight: fwSemiBold,
                        color: AppColor.primary,
                      ),
                      16.height,

                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: ResSize.w * 16,
                          vertical: ResSize.h * 16,
                        ),
                        decoration: BoxDecoration(
                          color: Color(0xffF9F9F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Image.asset(
                              AppAssets.visa,
                              height: ResSize.h * 20,
                              width: ResSize.w * 40,
                            ),
                            12.width,
                            TextWidget(
                              text: "Paid Via Card",
                              fontSize: 14,
                              fontWeight: fwMedium,
                              color: AppColor.primary,
                            ),
                            8.width,
                            TextWidget(
                              text: "***  3321",
                              fontSize: 14,
                              fontWeight: fwNormal,
                              color: AppColor.subtitle,
                            ),
                          ],
                        ),
                      ),

                      24.height,

                      // Download Invoice Button
                      CustomButton(
                        centerContent: "Download Invoice",
                        onPressed: () {},
                        fontSize: 16,
                        icon: Padding(
                          padding: EdgeInsets.only(right: ResSize.w * 10),
                          child: Image.asset(
                            AppAssets.download,
                            color: AppColor.secondary,
                            height: ResSize.h * 24,
                          ),
                        ),
                      ),
                      16.height,

                      // Report Issue Button
                      Center(
                        child: TextButton(
                          onPressed: () {},
                          child: TextWidget(
                            text: "Report an issue",
                            fontSize: 16,
                            fontWeight: fwNormal,
                            color: AppColor.subtitle,
                          ),
                        ),
                      ),

                      24.height,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFareRow(String label, String amount) {
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
          fontWeight: fwNormal,
          color: AppColor.subtitle,
        ),
      ],
    );
  }
}

// Custom Painter for Dotted Line
class DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const dashHeight = 5.0;
    const dashSpace = 3.0;
    double startY = 0;

    while (startY < size.height) {
      canvas.drawLine(Offset(0, startY), Offset(0, startY + dashHeight), paint);
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
