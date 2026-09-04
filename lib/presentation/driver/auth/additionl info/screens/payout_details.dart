import 'package:flutter/material.dart';
import 'package:riding_app/constants/appcolors.dart';
import 'package:riding_app/constants/appfontweight.dart';
import 'package:riding_app/widgets/custom_text_widget.dart';
import 'package:riding_app/widgets/custom_textfield.dart';
import 'package:riding_app/widgets/dropdown.dart';
import 'package:riding_app/widgets/responsive_size.dart';
import 'package:riding_app/widgets/sizedbox_extention.dart';

// Personal Detail Screen Example
class AdditionalInfoPayoutDetail extends StatelessWidget {
  AdditionalInfoPayoutDetail({super.key});
  final TextEditingController _bankNameController = TextEditingController();

  final List<String> banksNames = [
    'State Bank of Pakistan',
    'National Bank of Pakistan (NBP)',
    'Habib Bank Limited (HBL)',
    'United Bank Limited (UBL)',
    'Muslim Commercial Bank (MCB)',
    'Allied Bank Limited (ABL)',
    'Bank Alfalah',
    'Standard Chartered Bank Pakistan',
    'Meezan Bank',
    'Askari Bank',
    'Faysal Bank',
    'JS Bank',
    'Bank Al Habib',
    'Soneri Bank',
    'Summit Bank',
    'Silkbank',
    'Habib Metropolitan Bank',
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: ResSize.w * 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextWidget(
              text: "Payout Details",
              fontSize: 18,
              fontWeight: fwSemiBold,
              color: AppColor.primary,
            ),
            2.height,
            TextWidget(
              text: "Where should we send you earning",
              fontSize: 14,
              fontWeight: fwNormal,
              color: AppColor.subtitle,
            ),
            22.height,

            TextWidget(
              text: "Bank Name",
              fontSize: 16,
              fontWeight: fwMedium,
              color: AppColor.primary,
            ),
            8.height,
            AppDropdownField(
              controller: _bankNameController,
              hint: 'Select Bank',
              items: banksNames,
            ),
            16.height,

            // Email Field
            TextWidget(
              text: "Account Number",
              fontSize: 16,
              fontWeight: fwMedium,
              color: AppColor.primary,
            ),
            8.height,
            customTextfield(
              hint: "3445  6464  7885  3321",
              keyboardType: TextInputType.number,
            ),
            16.height,
            // Address Field
            TextWidget(
              text: "IBAN / Sort Code",
              fontSize: 16,
              fontWeight: fwMedium,
              color: AppColor.primary,
            ),
            8.height,
            customTextfield(hint: "GB82 WEST 1234 5698 7654 32"),
            16.height,
            TextWidget(
              text: "You can update this later",
              fontSize: 14,
              fontWeight: fwNormal,
              color: AppColor.subtitle,
            ),

            40.height,
          ],
        ),
      ),
    );
  }
}
