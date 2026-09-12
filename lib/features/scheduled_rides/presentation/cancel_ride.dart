import 'package:flutter/material.dart';
import 'package:movera_rider/core/constants/appcolors.dart';
import 'package:movera_rider/core/constants/appassets.dart';
import 'package:movera_rider/core/constants/appfontweight.dart';
import 'package:movera_rider/features/scheduled_rides/data/scheduled_rides_repository.dart';
import 'package:movera_rider/shared/widgets/custom_btn.dart';
import 'package:movera_rider/shared/widgets/custom_text_widget.dart';
import 'package:movera_rider/shared/widgets/custom_textfield.dart';
import 'package:movera_rider/shared/widgets/responsive_size.dart';
import 'package:movera_rider/shared/widgets/sizedbox_extention.dart';

void showCancelRideReasonDialog(BuildContext context) {
  final List<String> reasons = CancelReasonCatalog().all();

  String selectedReason = "";
  final TextEditingController otherReasonController = TextEditingController();

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            insetPadding: EdgeInsets.symmetric(horizontal: ResSize.w * 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            backgroundColor: Colors.white,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: ResSize.w * 20,
                vertical: ResSize.h * 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 🚫 Icon
                    Image.asset(AppAssets.cancelRide, height: ResSize.h * 60),
                    16.height,

                    // 🟢 Title
                    TextWidget(
                      text: "What Went Wrong?",
                      color: AppColor.title,
                      fontSize: 24,
                      fontWeight: fwSemiBold,
                    ),
                    8.height,

                    // 🔘 Reasons List
                    ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: reasons.length,
                      itemBuilder: (context, index) {
                        String reason = reasons[index];
                        return InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () {
                            setState(() {
                              selectedReason = reason;
                            });
                          },
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: TextWidget(
                                  text: reason,
                                  color: AppColor.title,
                                  fontSize: 16,
                                  fontWeight: fwMedium,
                                ),
                              ),
                              Radio<String>(
                                visualDensity: VisualDensity.compact,
                                value: reason,
                                groupValue: selectedReason,
                                onChanged: (value) {
                                  setState(() {
                                    selectedReason = value!;
                                  });
                                },
                                activeColor: AppColor.primary,
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    // ✏️ Text field (only when "Other" selected)
                    if (selectedReason == "Other") ...[
                      12.height,
                      customTextfield(
                        hint: "Kindly share the reason for canceling the ride.",
                        maxline: 4,
                        fontSize: 13,
                        contentHorizPadding: 5,
                        contentVertPadding: 5,
                        borderWidth: 0.5,
                        borderColor: Color(0xffDDE1E6),
                        fillColor: Color(0xffEEEEEE),
                      ),
                    ],

                    20.height,

                    // 🔘 Buttons Row
                    Row(
                      children: [
                        Expanded(
                          child: CustomButton(
                            centerContent: "CANCEL",
                            btncolor: Colors.transparent,
                            height: ResSize.h * 38,
                            borderColor: AppColor.red,
                            borderwidth: 0.85,
                            fontSize: 12,
                            textColor: AppColor.red,
                            onPressed: () {
                              Navigator.pop(context);
                            },
                          ),
                        ),

                        // Cancel button (outlined red)
                        15.width,

                        // Go back button (filled blue)
                        Expanded(
                          child: CustomButton(
                            centerContent: "GO BACK",
                            fontSize: 12,
                            height: ResSize.h * 38,
                            onPressed: () {
                              Navigator.of(context).popUntil((route) => route.isFirst);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}
