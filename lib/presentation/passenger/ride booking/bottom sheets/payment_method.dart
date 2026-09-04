// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:riding_app/constants/appassets.dart';
import 'package:riding_app/constants/appcolors.dart';
import 'package:riding_app/constants/appfontweight.dart';
import 'package:riding_app/widgets/custom_btn.dart';
import 'package:riding_app/widgets/custom_text_widget.dart';
import 'package:riding_app/widgets/custom_textfield.dart';
import 'package:riding_app/widgets/responsive_size.dart';
import 'package:riding_app/widgets/sizedbox_extention.dart';

class BookRidePaymentMethods extends StatelessWidget {
  final VoidCallback onNext;
  const BookRidePaymentMethods({super.key, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: AppColor.secondary,
          boxShadow: [
            BoxShadow(
              color: Color(0xff000000).withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 5),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: ResSize.w * 12,
            vertical: ResSize.h * 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextWidget(
                text: "Payment Method",
                color: AppColor.primary,
                fontSize: 18,
                fontWeight: fwSemiBold,
              ),
              16.height,
              customTextfield(
                keyboardType: TextInputType.number,
                hint: "3445  6464  7885  3321",
                prefixWidget: Padding(
                  padding: EdgeInsets.only(
                    left: ResSize.w * 12,
                    right: ResSize.w * 5,
                  ),
                  child: Image.asset(
                    AppAssets.visa,
                    height: ResSize.h * 20,
                    width: ResSize.w * 40,
                  ),
                ),
                suffixWidget: Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: AppColor.hintText,
                  size: ResSize.h * 18,
                ),
              ),
              4.height,
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {},
                    child: Row(
                      children: [
                        Icon(
                          Icons.add,
                          color: AppColor.primary,
                          size: ResSize.h * 24,
                        ),
                        6.width,
                        Text(
                          "Add Promo code",
                          style: GoogleFonts.poppins(
                            fontSize: ResSize.setSp(16),
                            decoration: TextDecoration.underline,
                            fontWeight: fwMedium,
                            decorationColor: AppColor.primary,
                            color: AppColor.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              16.height,
              CustomButton(
                centerContent: "Confirm Ride",
                onPressed: onNext,
                fontSize: 16,
                height: 50,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
