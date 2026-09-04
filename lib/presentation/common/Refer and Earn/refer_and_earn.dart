import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // <-- Needed for Clipboard
import 'package:riding_app/constants/appassets.dart';
import 'package:riding_app/constants/appcolors.dart';
import 'package:riding_app/constants/appfontweight.dart';
import 'package:riding_app/widgets/custom_btn.dart';
import 'package:riding_app/widgets/custom_text_widget.dart';
import 'package:riding_app/widgets/responsive_size.dart';
import 'package:riding_app/widgets/sizedbox_extention.dart';

class ReferAndEarn extends StatelessWidget {
  const ReferAndEarn({super.key});

  final String referralCode = "RID2ESSA"; // Your referral code

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
                  icon: Icon(
                    Icons.arrow_back_rounded,
                    size: ResSize.h * 20,
                    color: AppColor.primary,
                  ),
                ),
                TextWidget(
                  text: "Refer & Earn",
                  color: AppColor.primary,
                  fontSize: 18,
                  fontWeight: fwSemiBold,
                ),
                IconButton(
                  onPressed: () {},
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  icon: SizedBox(),
                ),
              ],
            ),
            40.height,
            Padding(
              padding: EdgeInsets.symmetric(horizontal: screenHorizPadding),
              child: Column(
                children: [
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
                        TextWidget(
                          textAlign: TextAlign.center,
                          text: "Earn \$5 for every friend you refer!",
                          color: AppColor.primary,
                          fontSize: 18,
                          fontWeight: fwSemiBold,
                        ),
                        16.height,
                        TextWidget(
                          text: "Your Referral code",
                          color: AppColor.primary,
                          fontSize: 18,
                          fontWeight: fwNormal,
                        ),
                        TextWidget(
                          text: referralCode,
                          color: AppColor.primary,
                          fontSize: 24,
                          fontWeight: fwSemiBold,
                        ),
                        32.height,
                        Row(
                          children: [
                            Expanded(
                              child: CustomButton(
                                textColor: AppColor.primary,
                                borderColor: AppColor.primary,
                                borderwidth: 1,
                                icon: Padding(
                                  padding: EdgeInsets.only(
                                    right: ResSize.w * 10,
                                  ),
                                  child: Icon(
                                    Icons.copy_rounded,
                                    color: AppColor.primary,
                                    size: ResSize.h * 20,
                                  ),
                                ),
                                btncolor: Colors.transparent,
                                centerContent: "Copy",
                                fontSize: 16,
                                height: 50,
                                onPressed: () {
                                  // 1️⃣ Copy to clipboard
                                  Clipboard.setData(
                                    ClipboardData(text: referralCode),
                                  );

                                  // 2️⃣ Show snackbar
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        "Referral code copied!",
                                        style: TextStyle(
                                          color: AppColor.secondary,
                                        ),
                                      ),
                                      backgroundColor: AppColor.primary,
                                      duration: Duration(seconds: 2),
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            16.width,
                            Expanded(
                              child: CustomButton(
                                centerContent: "Share",
                                onPressed: () {
                                  // TODO: implement share functionality
                                },
                                icon: Padding(
                                  padding: EdgeInsets.only(
                                    right: ResSize.w * 10,
                                  ),
                                  child: Image.asset(
                                    AppAssets.share,
                                    height: ResSize.h * 20,
                                    color: AppColor.secondary,
                                  ),
                                ),
                                height: 50,
                              ),
                            ),
                          ],
                        ),
                      ],
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
