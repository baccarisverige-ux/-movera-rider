import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:riding_app/constants/appassets.dart';
import 'package:riding_app/constants/appcolors.dart';
import 'package:riding_app/constants/appfontweight.dart';
import 'package:riding_app/presentation/driver/auth/additionl%20info/navigation.dart';
import 'package:riding_app/widgets/custom_btn.dart';
import 'package:riding_app/widgets/custom_text_widget.dart';
import 'package:riding_app/widgets/navigation_transition.dart';
import 'package:riding_app/widgets/responsive_size.dart';
import 'package:pinput/pinput.dart';
import 'package:riding_app/widgets/sizedbox_extention.dart';

class DriverVerifyPhone extends StatefulWidget {
  const DriverVerifyPhone({super.key});

  @override
  State<DriverVerifyPhone> createState() => _DriverVerifyPhoneState();
}

class _DriverVerifyPhoneState extends State<DriverVerifyPhone> {
  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 70,
      height: 70,
      textStyle: GoogleFonts.poppins(
        fontSize: ResSize.setSp(30),
        color: AppColor.title,
        fontWeight: fwBold,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5.51),
        color: Colors.transparent,
        border: Border.all(color: AppColor.border, width: 1),
      ),
    );
    return Scaffold(
      backgroundColor: AppColor.bg,
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: screenHorizPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            55.height,
            Center(child: Image.asset(AppAssets.logo, height: ResSize.h * 40)),
            36.height,
            TextWidget(
              text: "Verification Code",
              color: AppColor.primary,
              fontSize: ResSize.setSp(24),
              fontWeight: fwSemiBold,
            ),
            2.height,
            TextWidget(
              text:
                  "We send verification code on your Phone numebr 03*******23",
              color: AppColor.primary,
              fontSize: ResSize.setSp(14),
              fontWeight: fwNormal,
            ),
            60.height,
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: ResSize.w * 20,
                vertical: ResSize.h * 24,
              ),
              decoration: BoxDecoration(
                border: Border.all(color: AppColor.border, width: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Center(
                    child: Image.asset(
                      AppAssets.verifyAccount,
                      height: ResSize.h * 56,
                    ),
                  ),
                  18.height,
                  TextWidget(
                    text: "Verify your account",
                    color: AppColor.primary,
                    fontSize: ResSize.setSp(24),
                    fontWeight: fwBold,
                  ),
                  25.height,
                  Center(
                    child: Pinput(
                      length: 4,
                      defaultPinTheme: defaultPinTheme,
                      focusedPinTheme: defaultPinTheme.copyDecorationWith(
                        borderRadius: BorderRadius.circular(6),
                        color: Colors.transparent,
                      ),
                      followingPinTheme: defaultPinTheme,
                      separatorBuilder: (index) => 14.width,
                      showCursor: true,
                      onCompleted: (pin) {},
                    ),
                  ),
                  40.height,
                  CustomButton(
                    centerContent: "Continue",
                    fontSize: 16,
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        BottomToTopTransition(
                          const DriverAdditionalInfoNavigation(),
                        ),
                      );
                    },
                  ),
                  20.height,
                  TextButton(
                    onPressed: () {},
                    child: TextWidget(
                      text: "Resend code?",
                      color: AppColor.primary,
                      fontSize: 16,
                      fontWeight: fwBold,
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
