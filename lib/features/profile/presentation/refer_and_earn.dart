import 'package:flutter/material.dart';
import 'package:movera_rider/core/constants/appcolors.dart';
import 'package:movera_rider/core/constants/appfontweight.dart';
import 'package:movera_rider/shared/widgets/custom_text_widget.dart';
import 'package:movera_rider/shared/widgets/responsive_size.dart';
import 'package:movera_rider/shared/widgets/sizedbox_extention.dart';

class ReferAndEarn extends StatelessWidget {
  const ReferAndEarn({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            55.height,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  tooltip: 'Back',
                  icon: Icon(
                    Icons.arrow_back_rounded,
                    size: ResSize.h * 20,
                    color: AppColor.primary,
                  ),
                ),
                TextWidget(
                  text: 'Refer & Earn',
                  color: AppColor.primary,
                  fontSize: 18,
                  fontWeight: fwSemiBold,
                ),
                const SizedBox(width: 48, height: 48),
              ],
            ),
            40.height,
            Padding(
              padding: EdgeInsets.symmetric(horizontal: screenHorizPadding),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: ResSize.w * 24,
                  vertical: ResSize.h * 32,
                ),
                decoration: BoxDecoration(
                  color: AppColor.secondary,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      offset: const Offset(0, 5),
                      color: const Color(0xff000000).withValues(alpha: 0.08),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: ResSize.w * 64,
                      height: ResSize.w * 64,
                      decoration: BoxDecoration(
                        color: AppColor.primary.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.group_add_outlined,
                        color: AppColor.primary,
                        size: ResSize.w * 30,
                      ),
                    ),
                    20.height,
                    TextWidget(
                      textAlign: TextAlign.center,
                      text: 'Referrals aren’t available yet',
                      color: AppColor.primary,
                      fontSize: 18,
                      fontWeight: fwSemiBold,
                    ),
                    8.height,
                    TextWidget(
                      textAlign: TextAlign.center,
                      text:
                          'Your referral code and rewards will appear here when the Movera referral programme launches.',
                      color: AppColor.subtitle,
                      fontSize: 13,
                      fontWeight: fwNormal,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
