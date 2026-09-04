import 'package:flutter/material.dart';
import 'package:movera_rider/constants/appassets.dart';
import 'package:movera_rider/constants/appcolors.dart';
import 'package:movera_rider/constants/appfontweight.dart';
import 'package:movera_rider/widgets/custom_btn.dart';
import 'package:movera_rider/widgets/custom_text_widget.dart';
import 'package:movera_rider/widgets/responsive_size.dart';
import 'package:movera_rider/widgets/sizedbox_extention.dart';

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
