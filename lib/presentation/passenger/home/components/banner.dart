import 'package:flutter/material.dart';
import 'package:riding_app/constants/appassets.dart';
import 'package:riding_app/constants/appcolors.dart';
import 'package:riding_app/constants/appfontweight.dart';
import 'package:riding_app/widgets/custom_btn.dart';
import 'package:riding_app/widgets/custom_text_widget.dart';
import 'package:riding_app/widgets/responsive_size.dart';
import 'package:riding_app/widgets/sizedbox_extention.dart';

class PassengerHomeBanner extends StatelessWidget {
  const PassengerHomeBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ResSize.w * 18,
        vertical: ResSize.h * 18,
      ),
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        image: DecorationImage(
          image: AssetImage(AppAssets.homeBanner),
          fit: BoxFit.cover,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextWidget(
            text: "20% off on your\nfirst ride",
            fontSize: ResSize.setSp(20),
            fontWeight: fwBold,
            color: AppColor.secondary,
          ),
          41.height,
          CustomButton(
            centerContent: "Take a trip",
            onPressed: () {},
            btncolor: AppColor.secondary,
            textColor: AppColor.primary,
            width: ResSize.w * 130,
            height: ResSize.h * 38,
            fontSize: 16,
          ),
        ],
      ),
    );
  }
}
