import 'package:country_pickers/country.dart';
import 'package:country_pickers/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movera_rider/core/constants/appcolors.dart';
import 'package:movera_rider/core/constants/appfontweight.dart';
import 'package:movera_rider/features/auth/application/auth_controller.dart';
import 'package:movera_rider/features/auth/presentation/phone_verify.dart';
import 'package:movera_rider/shared/design_system/movera_toast.dart';
import 'package:movera_rider/shared/widgets/checkbox.dart';
import 'package:movera_rider/shared/widgets/custom_btn.dart';
import 'package:movera_rider/shared/widgets/custom_text_widget.dart';
import 'package:movera_rider/shared/widgets/custom_textfield.dart';
import 'package:movera_rider/shared/widgets/navigation_transition.dart';
import 'package:movera_rider/shared/widgets/phone_picker.dart';
import 'package:movera_rider/shared/widgets/responsive_size.dart';
import 'package:movera_rider/shared/widgets/sizedbox_extention.dart';

class CreateAccount extends StatefulWidget {
  const CreateAccount({super.key, this.controller});

  final AuthController? controller;

  @override
  State<CreateAccount> createState() => _CreateAccountState();
}

class _CreateAccountState extends State<CreateAccount> {
  String selectedCountryCode = '+46';
  Country? selectedCountry;
  final TextEditingController _name = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  late final AuthController _auth;
  bool isAccept = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _auth = widget.controller ?? AuthController();
    selectedCountry = CountryPickerUtils.getCountryByIsoCode('SE');
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  void updateCountryCode(String newCode, Country country) {
    setState(() {
      selectedCountryCode = newCode;
      selectedCountry = country;
    });
  }

  Future<void> _continue() async {
    if (_submitting) return;
    final name = _name.text.trim();
    final digits = _phone.text.replaceAll(RegExp(r'\s+'), '').trim();
    if (name.length < 2) {
      MoveraToast.show(context, 'Enter your full name.');
      return;
    }
    if (digits.length < 6) {
      MoveraToast.show(context, 'Enter a valid phone number.');
      return;
    }
    if (!isAccept) {
      MoveraToast.show(context, 'Accept the Terms and Privacy Policy to continue.');
      return;
    }
    final number = '$selectedCountryCode$digits';
    setState(() => _submitting = true);
    try {
      final challenge = await _auth.requestOtp(
        phone: number,
        fullName: name,
      );
      if (!mounted) return;
      await Navigator.push(
        context,
        BottomToTopTransition(
          PhoneVerification(
            challenge: challenge,
            controller: _auth,
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      MoveraToast.show(context, 'Could not start phone verification.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
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
              text: 'Create account',
              fontSize: 24,
              fontWeight: fwExtraBold,
            ),
            9.height,
            TextWidget(
              textAlign: TextAlign.start,
              text:
                  'Enter a valid phone number where we will send a verification code',
              color: AppColor.subtitle,
              fontSize: 16,
              fontWeight: fwMedium,
            ),
            14.height,
            customTextfield(
              controller: _name,
              hint: 'Full name',
              prefixWidget: Icon(
                Icons.person_outline_rounded,
                size: ResSize.h * 25,
                color: AppColor.hintText,
              ),
            ),
            16.height,
            customTextfield(
              controller: _phone,
              contentHorizPadding: 0,
              hint: 'Phone number',
              keyboardType: TextInputType.phone,
              prefixWidget: InkWell(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => PhoneNumberPicker(
                      onCountryCodeSelected: updateCountryCode,
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: 5,
                    top: 7,
                    bottom: 7,
                    right: 0,
                  ),
                  child: SizedBox(
                    width: ResSize.w * 64,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (selectedCountry != null)
                          CountryPickerUtils.getDefaultFlagImage(
                            selectedCountry!,
                          ),
                        5.width,
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: AppColor.hintText,
                          size: ResSize.h * 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            13.height,
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Transform.translate(
                  offset: Offset(ResSize.w * -10, -7),
                  child: CustomCheckBox(
                    value: isAccept,
                    onPressed: () => setState(() => isAccept = !isAccept),
                  ),
                ),
                Expanded(
                  child: Transform.translate(
                    offset: Offset(ResSize.w * -10, 0),
                    child: RichText(
                      textAlign: TextAlign.start,
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: ' By continuing, I agree to the',
                            style: GoogleFonts.poppins(
                              fontSize: ResSize.setSp(14),
                              fontWeight: fwNormal,
                              color: AppColor.subtitle,
                            ),
                          ),
                          TextSpan(
                            text: ' Terms of Use',
                            style: GoogleFonts.poppins(
                              decoration: TextDecoration.underline,
                              fontSize: ResSize.setSp(14),
                              fontWeight: fwNormal,
                              color: AppColor.title,
                            ),
                          ),
                          TextSpan(
                            text: ' and',
                            style: GoogleFonts.poppins(
                              fontSize: ResSize.setSp(14),
                              fontWeight: fwNormal,
                              color: AppColor.subtitle,
                            ),
                          ),
                          TextSpan(
                            text: ' Privacy Policy',
                            style: GoogleFonts.poppins(
                              decoration: TextDecoration.underline,
                              fontSize: ResSize.setSp(14),
                              fontWeight: fwNormal,
                              color: AppColor.title,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
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
                onPressed: _submitting ? null : _continue,
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
    );
  }
}
