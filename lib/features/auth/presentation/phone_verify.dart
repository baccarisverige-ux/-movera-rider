import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movera_rider/core/constants/appcolors.dart';
import 'package:movera_rider/core/constants/appfontweight.dart';
import 'package:movera_rider/features/auth/application/auth_controller.dart';
import 'package:movera_rider/features/home/presentation/home.dart';
import 'package:movera_rider/shared/design_system/movera_toast.dart';
import 'package:movera_rider/shared/widgets/custom_btn.dart';
import 'package:movera_rider/shared/widgets/custom_text_widget.dart';
import 'package:movera_rider/shared/widgets/responsive_size.dart';
import 'package:movera_rider/shared/widgets/sizedbox_extention.dart';
import 'package:pinput/pinput.dart';

class PhoneVerification extends StatefulWidget {
  const PhoneVerification({super.key, this.phoneNumber});

  /// The number the rider just entered. Null when it is not known, in which
  /// case the screen says so rather than naming a number nobody typed.
  final String? phoneNumber;

  @override
  State<PhoneVerification> createState() => _PhoneVerificationState();
}

class _PhoneVerificationState extends State<PhoneVerification> {
  bool _showHome = false;

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 50,
      height: 50,
      textStyle: GoogleFonts.poppins(
        fontSize: ResSize.setSp(20),
        color: AppColor.title,
        fontWeight: fwSemiBold,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: AppColor.textfieldFill,
      ),
    );

    return Stack(
      fit: StackFit.expand,
      children: [
        // Keep the real Home widget alive behind verification. This lets the
        // Google Maps platform view, tiles and Movera styling initialize while
        // the user is entering the verification code. When Continue is tapped
        // we reveal this exact Home instance instead of creating a fresh map.
        IgnorePointer(ignoring: !_showHome, child: const Home()),
        if (!_showHome)
          Scaffold(
            body: Padding(
              padding: EdgeInsets.symmetric(horizontal: screenHorizPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  56.height,
                  Transform.translate(
                    offset: Offset(ResSize.w * -10, 0),
                    child: IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      tooltip: 'Back',
                      icon: Icon(
                        Icons.arrow_back_ios_rounded,
                        color: AppColor.title,
                        size: ResSize.h * 22,
                      ),
                    ),
                  ),
                  18.height,
                  TextWidget(
                    text: "Phone verification",
                    fontSize: 24,
                    fontWeight: fwExtraBold,
                  ),
                  9.height,
                  RichText(
                    textAlign: TextAlign.start,
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: widget.phoneNumber == null
                              ? 'We sent a verification code to your phone.'
                              : 'Verification code has been sent to',
                          style: GoogleFonts.poppins(
                            fontSize: ResSize.setSp(16),
                            fontWeight: fwNormal,
                            color: AppColor.subtitle,
                          ),
                        ),
                        if (widget.phoneNumber != null)
                          TextSpan(
                            text: ' ${widget.phoneNumber}.',
                            style: GoogleFonts.poppins(
                              decoration: TextDecoration.underline,
                              fontSize: ResSize.setSp(16),
                              fontWeight: fwMedium,
                              color: AppColor.title,
                            ),
                          ),
                        TextSpan(
                          text: " Enter your 4-digit code",
                          style: GoogleFonts.poppins(
                            fontSize: ResSize.setSp(16),
                            fontWeight: fwNormal,
                            color: AppColor.subtitle,
                          ),
                        ),
                      ],
                    ),
                  ),
                  24.height,
                  Container(
                    padding: EdgeInsets.symmetric(vertical: ResSize.h * 14),
                    decoration: BoxDecoration(
                      color: AppColor.secondary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        10.height,
                        Center(
                          child: Pinput(
                            length: 4,
                            defaultPinTheme: defaultPinTheme,
                            focusedPinTheme: defaultPinTheme.copyDecorationWith(
                              borderRadius: BorderRadius.circular(6),
                              color: AppColor.textfieldFill,
                            ),
                            followingPinTheme: defaultPinTheme,
                            separatorBuilder: (index) => 26.width,
                            showCursor: true,
                            onCompleted: (pin) {},
                          ),
                        ),
                        14.height,
                        // Wrap, not Row: "Didn't get a code?" plus the action
                        // overflowed the screen by 46px at 390 wide.
                        Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            TextWidget(
                              text: "Didn’t get a code?",
                              color: AppColor.title,
                              fontSize: 15,
                              fontWeight: fwNormal,
                            ),
                            TextButton(
                              // Was labelled "Sign in" — an answer to a
                              // different question — and did nothing at all.
                              onPressed: () {
                                AuthController().requestOtp(
                                  phone: widget.phoneNumber ?? '',
                                );
                                MoveraToast.show(
                                  context,
                                  widget.phoneNumber == null
                                      ? 'We sent another code to your phone.'
                                      : 'We sent another code to '
                                            '${widget.phoneNumber}.',
                                );
                              },
                              child: TextWidget(
                                text: "Resend code",
                                color: AppColor.primary,
                                fontSize: 15,
                                fontWeight: fwNormal,
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
            bottomNavigationBar: SizedBox(
              height: ResSize.h * 80,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: screenHorizPadding),
                child: Column(
                  children: [
                    CustomButton(
                      centerContent: "Continue",
                      onPressed: () {
                        AuthController().signIn(provider: 'phone');
                        setState(() {
                          _showHome = true;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
