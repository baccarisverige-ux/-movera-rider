import 'package:flutter/material.dart';
import 'package:riding_app/constants/appcolors.dart';
import 'package:riding_app/constants/appfontweight.dart';
import 'package:riding_app/widgets/custom_text_widget.dart';
import 'package:riding_app/widgets/custom_textfield.dart';
import 'package:riding_app/widgets/responsive_size.dart';
import 'package:riding_app/widgets/sizedbox_extention.dart';

// Personal Detail Screen Example
class AdditionalInfoPersonalDetail extends StatelessWidget {
  const AdditionalInfoPersonalDetail({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: ResSize.w * 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextWidget(
              text: "Personal Details",
              fontSize: 18,
              fontWeight: fwSemiBold,
              color: AppColor.primary,
            ),
            2.height,
            TextWidget(
              text: "Tell us about yourself",
              fontSize: 14,
              fontWeight: fwNormal,
              color: AppColor.subtitle,
            ),
            22.height,

            // Full Name Field
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextWidget(
                    text: "Full name",
                    fontSize: 16,
                    fontWeight: fwMedium,
                    color: AppColor.primary,
                  ),
                  8.height,
                  customTextfield(
                    hint: "Phone Number",
                    keyboardType: TextInputType.phone,
                  ),
                  16.height,

                  // Email Field
                  TextWidget(
                    text: "Email",
                    fontSize: 16,
                    fontWeight: fwMedium,
                    color: AppColor.primary,
                  ),
                  8.height,
                  customTextfield(
                    hint: "example23@gmail.com",
                    keyboardType: TextInputType.emailAddress,
                  ),
                  16.height,
                  // Address Field
                  TextWidget(
                    text: "Your Address",
                    fontSize: 16,
                    fontWeight: fwMedium,
                    color: AppColor.primary,
                  ),
                  8.height,
                  customTextfield(hint: "example23@gmail.com"),
                ],
              ),
            ),

            40.height,
          ],
        ),
      ),
    );
  }
}
