import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:riding_app/constants/appassets.dart';
import 'package:riding_app/constants/appcolors.dart';
import 'package:riding_app/constants/appfontweight.dart';
import 'package:riding_app/widgets/custom_text_widget.dart';
import 'package:riding_app/widgets/responsive_size.dart';
import 'package:riding_app/widgets/sizedbox_extention.dart';

class PassengerHomeSavedPlaces extends StatelessWidget {
  const PassengerHomeSavedPlaces({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        card(
          AppAssets.home,
          "Home",
          "1901 Thornridge Cir. Shiloh, Hawaii 81063",
        ),
        14.height,
        card(
          AppAssets.work,
          "Work",
          "1901 Thornridge Cir. Shiloh, Hawaii 81063",
        ),
      ],
    );
  }

  Widget card(String icon, String title, String address) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColor.border, width: 0.6),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: ResSize.w * 12,
          vertical: ResSize.h * 8,
        ),
        child: Row(
          children: [
            Container(
              height: ResSize.h * 42,
              width: ResSize.w * 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xffF5F5F5),
              ),
              child: Center(
                child: Image.asset(
                  icon,
                  height: ResSize.h * 20,
                  color: Color(0xffB5B5B5),
                ),
              ),
            ),
            10.width,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextWidget(
                    text: title,
                    color: Color(0xff2B2B2B),
                    fontSize: ResSize.setSp(16),
                    fontWeight: fwSemiBold,
                  ),
                  2.height,
                  Text(
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    address,
                    style: GoogleFonts.poppins(
                      color: AppColor.subtitle,
                      fontSize: ResSize.setSp(13),
                      fontWeight: fwNormal,
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
