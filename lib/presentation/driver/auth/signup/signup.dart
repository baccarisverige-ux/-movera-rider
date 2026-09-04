import 'package:country_pickers/country.dart';
import 'package:country_pickers/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:riding_app/constants/appassets.dart';
import 'package:riding_app/constants/appcolors.dart';
import 'package:riding_app/constants/appfontweight.dart';
import 'package:riding_app/presentation/driver/auth/verify%20phone/verify_phone.dart';
import 'package:riding_app/widgets/checkbox.dart';
import 'package:riding_app/widgets/custom_btn.dart';
import 'package:riding_app/widgets/custom_text_widget.dart';
import 'package:riding_app/widgets/custom_textfield.dart';
import 'package:riding_app/widgets/navigation_transition.dart';
import 'package:riding_app/widgets/phone_picker.dart';
import 'package:riding_app/widgets/responsive_size.dart';
import 'package:riding_app/widgets/sizedbox_extention.dart';

class DriverSignup extends StatefulWidget {
  const DriverSignup({super.key});

  @override
  State<DriverSignup> createState() => _DriverSignupState();
}

class _DriverSignupState extends State<DriverSignup> {
  String selectedCountryCode = '+92';

  Country? selectedCountry;
  // Add this to store the selected country
  @override
  void initState() {
    super.initState();
    // Set default country (United States)
    selectedCountry = CountryPickerUtils.getCountryByIsoCode('US');
    selectedCountryCode = '+1';
  }

  void updateCountryCode(String newCode, Country country) {
    setState(() {
      selectedCountryCode = newCode;
      selectedCountry = country;
    });
  }

  bool isAccept = false;
  @override
  Widget build(BuildContext context) {
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
              text: "Signup",
              color: AppColor.primary,
              fontSize: ResSize.setSp(24),
              fontWeight: fwSemiBold,
            ),
            2.height,
            TextWidget(
              text:
                  "Welcome Back, enter your phone number to create your account",
              color: AppColor.primary,
              fontSize: ResSize.setSp(14),
              fontWeight: fwNormal,
            ),
            70.height,
            TextWidget(
              text: "Phone Number",
              color: AppColor.primary,
              fontSize: ResSize.setSp(16),
              fontWeight: fwMedium,
            ),
            8.height,
            customTextfield(
              hint: "(308) 555-0121",
              keyboardType: TextInputType.phone,
              contentVertPadding: 0,
              prefixWidget: InkWell(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return PhoneNumberPicker(
                        onCountryCodeSelected: updateCountryCode,
                      );
                    },
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: 5,
                    top: 0,
                    bottom: 0,
                    right: 0,
                  ),
                  child: SizedBox(
                    width: ResSize.w * 75,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Display country flag instead of country code
                        if (selectedCountry != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: CountryPickerUtils.getDefaultFlagImage(
                              selectedCountry!,
                            ),
                          ),
                        5.width,
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: AppColor.hintText,
                          size: ResSize.h * 20,
                        ),
                        4.width,
                        Container(
                          height: ResSize.h * 55,
                          width: ResSize.w * 0.6,
                          decoration: BoxDecoration(color: AppColor.border),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            16.height,
            Row(
              children: [
                Transform.translate(
                  offset: Offset(ResSize.w * -10, 0),
                  child: CustomCheckBox(
                    value: isAccept,
                    onPressed: () {
                      setState(() {
                        isAccept = !isAccept;
                      });
                    },
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
                            text: "By continuing, I agree to the ",
                            style: GoogleFonts.poppins(
                              fontSize: ResSize.setSp(14),
                              fontWeight: fwMedium,
                              color: AppColor.primary,
                            ),
                          ),
                          TextSpan(
                            text: "Terms of Use",
                            style: GoogleFonts.poppins(
                              decoration: TextDecoration.underline,
                              fontSize: ResSize.setSp(14),
                              fontWeight: fwMedium,
                              decorationColor: AppColor.primary,
                              color: AppColor.primary,
                            ),
                          ),
                          TextSpan(
                            text: " and ",
                            style: GoogleFonts.poppins(
                              fontSize: ResSize.setSp(14),
                              fontWeight: fwMedium,
                              color: AppColor.primary,
                            ),
                          ),
                          TextSpan(
                            text: "Privacy Policy",
                            style: GoogleFonts.poppins(
                              decoration: TextDecoration.underline,
                              fontSize: ResSize.setSp(14),
                              fontWeight: fwMedium,
                              decorationColor: AppColor.primary,
                              color: AppColor.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            41.height,
            CustomButton(
              centerContent: "Signup",
              onPressed: () {
                Navigator.push(
                  context,
                  RightToLeftTransition(DriverVerifyPhone()),
                );
              },
            ),
            43.height,
            Row(
              children: [
                Expanded(
                  child: Divider(color: AppColor.border, thickness: 0.6),
                ),
                10.width,
                TextWidget(
                  text: "Signup with google",
                  color: AppColor.subtitle,
                  fontSize: 14,
                  fontWeight: fwMedium,
                ),
                10.width,
                Expanded(
                  child: Divider(color: AppColor.border, thickness: 0.6),
                ),
              ],
            ),
            42.height,
            CustomButton(
              centerContent: "Google",
              onPressed: () {},
              textColor: AppColor.primary,
              btncolor: Colors.transparent,
              borderColor: AppColor.border,
              borderwidth: 1,
              fontSize: 14,
              icon: Padding(
                padding: EdgeInsets.only(right: ResSize.w * 12),
                child: Image.asset(AppAssets.google, height: ResSize.h * 20),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SizedBox(
        height: ResSize.h * 60,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: screenHorizPadding),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextWidget(
                    text: "Already have an account?",
                    color: AppColor.subtitle,
                    fontSize: 14,
                    fontWeight: fwMedium,
                  ),
                  TextButton(
                    onPressed: () {
                      Get.back();
                    },
                    child: TextWidget(
                      text: "Login",
                      color: AppColor.primary,
                      fontSize: 14,
                      fontWeight: fwMedium,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
