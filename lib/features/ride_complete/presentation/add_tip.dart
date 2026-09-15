import 'package:flutter/material.dart';
import 'package:movera_rider/core/constants/appcolors.dart';
import 'package:movera_rider/core/constants/appfontweight.dart';
import 'package:movera_rider/shared/widgets/custom_text_widget.dart';
import 'package:movera_rider/shared/widgets/sizedbox_extention.dart';

class RideCompletedAddTip extends StatelessWidget {
  const RideCompletedAddTip({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Center(
          child: TextWidget(
            text: 'Tip your driver',
            color: AppColor.title,
            fontSize: 16,
            fontWeight: fwSemiBold,
          ),
        ),
        8.height,
        Center(
          child: TextWidget(
            text: 'Tips unavailable',
            color: AppColor.title,
            fontSize: 14,
            fontWeight: fwMedium,
          ),
        ),
        4.height,
        Center(
          child: TextWidget(
            text: "Tipping isn't available in this build.",
            color: AppColor.subtitle,
            fontSize: 12,
            fontWeight: fwNormal,
          ),
        ),
      ],
    );
  }
}
