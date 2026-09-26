import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movera_rider/core/constants/appcolors.dart';
import 'package:movera_rider/core/constants/appfontweight.dart';
import 'package:movera_rider/features/auth/application/auth_controller.dart';
import 'package:movera_rider/features/auth/domain/otp_challenge.dart';
import 'package:movera_rider/features/home/presentation/home.dart';
import 'package:movera_rider/shared/design_system/movera_toast.dart';
import 'package:movera_rider/shared/widgets/custom_btn.dart';
import 'package:movera_rider/shared/widgets/custom_text_widget.dart';
import 'package:movera_rider/shared/widgets/responsive_size.dart';
import 'package:movera_rider/shared/widgets/sizedbox_extention.dart';
import 'package:pinput/pinput.dart';

class PhoneVerification extends StatefulWidget {
  const PhoneVerification({
    super.key,
    this.challenge,
    this.phoneNumber,
    this.controller,
  });

  final OtpChallenge? challenge;
  final String? phoneNumber;
  final AuthController? controller;

  @override
  State<PhoneVerification> createState() => _PhoneVerificationState();
}

class _PhoneVerificationState extends State<PhoneVerification> {
  bool _showHome = false;
  bool _submitting = false;
  bool _resending = false;
  String _pin = '';
  late final AuthController _auth;
  OtpChallenge? _challenge;
  DateTime? _canResendAt;

  String? get _phone => _challenge?.phone ?? widget.phoneNumber;

  @override
  void initState() {
    super.initState();
    _auth = widget.controller ?? AuthController();
    _challenge = widget.challenge;
    final challenge = _challenge;
    if (challenge != null) {
      _canResendAt = DateTime.now().toUtc().add(challenge.retryAfter);
    }
  }

  Future<void> _resend() async {
    if (_resending) return;
    final phone = _phone?.trim();
    if (phone == null || phone.isEmpty) {
      MoveraToast.show(context, 'Enter your phone number again to request a code.');
      return;
    }
    final canResendAt = _canResendAt;
    if (canResendAt != null && DateTime.now().toUtc().isBefore(canResendAt)) {
      final seconds = canResendAt.difference(DateTime.now().toUtc()).inSeconds + 1;
      MoveraToast.show(context, 'You can request another code in $seconds seconds.');
      return;
    }

    setState(() => _resending = true);
    try {
      final next = await _auth.requestOtp(phone: phone);
      if (!mounted) return;
      setState(() {
        _challenge = next;
        _canResendAt = DateTime.now().toUtc().add(next.retryAfter);
        _pin = '';
      });
      MoveraToast.show(context, 'We sent another code to $phone.');
    } catch (_) {
      if (!mounted) return;
      MoveraToast.show(context, 'Could not send another code.');
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  Future<void> _verify() async {
    if (_submitting) return;
    final challenge = _challenge;
    if (challenge == null) {
      MoveraToast.show(context, 'Request a new verification code first.');
      return;
    }
    if (challenge.isExpired) {
      MoveraToast.show(context, 'This verification code has expired. Request a new one.');
      return;
    }
    if (!RegExp(r'^\d{4}$').hasMatch(_pin)) {
      MoveraToast.show(context, 'Enter the 4-digit verification code.');
      return;
    }

    setState(() => _submitting = true);
    try {
      await _auth.verifyOtp(challenge: challenge, code: _pin);
      if (!mounted) return;
      setState(() => _showHome = true);
    } catch (_) {
      if (!mounted) return;
      MoveraToast.show(context, 'That verification code is not valid.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

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
                      onPressed: () => Navigator.pop(context),
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
                    text: 'Phone verification',
                    fontSize: 24,
                    fontWeight: fwExtraBold,
                  ),
                  9.height,
                  RichText(
                    textAlign: TextAlign.start,
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: _phone == null
                              ? 'We sent a verification code to your phone.'
                              : 'Verification code has been sent to',
                          style: GoogleFonts.poppins(
                            fontSize: ResSize.setSp(16),
                            fontWeight: fwNormal,
                            color: AppColor.subtitle,
                          ),
                        ),
                        if (_phone != null)
                          TextSpan(
                            text: ' $_phone.',
                            style: GoogleFonts.poppins(
                              decoration: TextDecoration.underline,
                              fontSize: ResSize.setSp(16),
                              fontWeight: fwMedium,
                              color: AppColor.title,
                            ),
                          ),
                        TextSpan(
                          text: ' Enter your 4-digit code',
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
                            onChanged: (value) => _pin = value,
                            onCompleted: (value) => _pin = value,
                          ),
                        ),
                        14.height,
                        Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            TextWidget(
                              text: 'Didn’t get a code?',
                              color: AppColor.title,
                              fontSize: 15,
                              fontWeight: fwNormal,
                            ),
                            TextButton(
                              onPressed: _resending ? null : _resend,
                              child: TextWidget(
                                text: _resending ? 'Sending…' : 'Resend code',
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
                      centerContent: 'Continue',
                      onPressed: _submitting ? null : _verify,
                      isLoading: _submitting,
                      loader: const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
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
