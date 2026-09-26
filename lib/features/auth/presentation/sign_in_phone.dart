import 'package:country_pickers/country.dart';
import 'package:country_pickers/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:movera_rider/core/constants/appcolors.dart';
import 'package:movera_rider/core/constants/appfontweight.dart';
import 'package:movera_rider/features/auth/application/auth_controller.dart';
import 'package:movera_rider/features/auth/presentation/phone_verify.dart';
import 'package:movera_rider/shared/design_system/movera_toast.dart';
import 'package:movera_rider/shared/widgets/custom_btn.dart';
import 'package:movera_rider/shared/widgets/custom_text_widget.dart';
import 'package:movera_rider/shared/widgets/custom_textfield.dart';
import 'package:movera_rider/shared/widgets/navigation_transition.dart';
import 'package:movera_rider/shared/widgets/phone_picker.dart';
import 'package:movera_rider/shared/widgets/responsive_size.dart';
import 'package:movera_rider/shared/widgets/sizedbox_extention.dart';

class SignInPhone extends StatefulWidget {
  const SignInPhone({super.key, this.controller});

  final AuthController? controller;

  @override
  State<SignInPhone> createState() => _SignInPhoneState();
}

class _SignInPhoneState extends State<SignInPhone> {
  String selectedCountryCode = '+46';
  Country? selectedCountry;
  final TextEditingController _phone = TextEditingController();
  late final AuthController _auth;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _auth = widget.controller ?? AuthController();
    selectedCountry = CountryPickerUtils.getCountryByIsoCode('SE');
    selectedCountryCode = '+46';
  }

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  String? get _enteredNumber {
    final digits = _phone.text.replaceAll(RegExp(r'\s+'), '').trim();
    if (digits.isEmpty) return null;
    return '$selectedCountryCode$digits';
  }

  void updateCountryCode(String newCode, Country country) {
    setState(() {
      selectedCountryCode = newCode;
      selectedCountry = country;
    });
  }

  Future<void> _continue() async {
    if (_submitting) return;
    final number = _enteredNumber;
    if (number == null || number.length < 7) {
      MoveraToast.show(context, 'Enter a valid phone number.');
      return;
    }
    setState(() => _submitting = true);
    try {
      final challenge = await _auth.requestOtp(phone: number);
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
    } catch (error) {
      if (!mounted) return;
      MoveraToast.show(context, 'Could not send a verification code.');
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
              text: 'Sign in with phone number',
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
                    width: ResSize.w * 75,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
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
