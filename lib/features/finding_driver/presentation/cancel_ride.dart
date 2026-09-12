import 'package:flutter/material.dart';
import 'package:movera_rider/core/constants/appcolors.dart';
import 'package:movera_rider/features/finding_driver/application/finding_driver_controller.dart';
import 'package:movera_rider/core/constants/appfontweight.dart';
import 'package:movera_rider/shared/widgets/custom_text_widget.dart';
import 'package:movera_rider/shared/widgets/responsive_size.dart';
import 'package:movera_rider/shared/widgets/sizedbox_extention.dart';

class RideCancellationDialog extends StatefulWidget {
  const RideCancellationDialog({super.key});

  @override
  State<RideCancellationDialog> createState() => _RideCancellationDialogState();
}

class _RideCancellationDialogState extends State<RideCancellationDialog> {
  double price = 7.50;
  // Add these fields
  void increasePrice() {
    setState(() {
      price = double.parse((price + 0.05).toStringAsFixed(2));
    });
  }

  void decreasePrice() {
    setState(() {
      // Optional: prevent going below 0
      if (price > 0) {
        price = double.parse((price - 0.05).toStringAsFixed(2));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: ResSize.w * 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(ResSize.w * 16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with close button
            Padding(
              padding: EdgeInsets.only(
                top: ResSize.h * 16,
                right: ResSize.w * 12,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: ResSize.w * 22,
                      height: ResSize.h * 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF2D3E50),
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.close,
                        size: ResSize.w * 18,
                        color: const Color(0xFF2D3E50),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Title
            Padding(
              padding: EdgeInsets.only(
                top: ResSize.h * 8,
                left: ResSize.w * 24,
                right: ResSize.w * 24,
              ),
              child: TextWidget(
                text: "Request canceled",
                color: const Color(0xFF333333),
                fontSize: 16,
                fontWeight: FontWeight.w600,
                textAlign: TextAlign.center,
              ),
            ),
            8.height,

            // Subtitle
            Padding(
              padding: EdgeInsets.symmetric(horizontal: ResSize.w * 24),
              child: TextWidget(
                text:
                    "Your ride was canceled by the driver. looking for another driver",
                color: const Color(0xFF333333),
                fontSize: 14,
                fontWeight: FontWeight.w400,
                textAlign: TextAlign.center,
              ),
            ),

            12.height,
            Padding(
              padding: EdgeInsets.symmetric(horizontal: ResSize.w * 8),
              child: Container(
                height: ResSize.h * 51,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Color(0xffF3F6FB),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: ResSize.w * 12),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: GestureDetector(
                          onTap: decreasePrice,
                          child: Container(
                            height: ResSize.h * 27,
                            width: ResSize.w * 27,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColor.white,
                            ),
                            child: Center(
                              child: Container(
                                width: ResSize.w * 14,
                                height: ResSize.h * 2,
                                color: AppColor.black,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: increasePrice,
                          child: Container(
                            height: ResSize.h * 27,
                            width: ResSize.w * 27,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColor.white,
                            ),
                            child: Center(
                              child: Icon(Icons.add, color: AppColor.black),
                            ),
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          50.width,
                          TextWidget(
                            text: "\$${price.toStringAsFixed(2)}",
                            color: AppColor.black,
                            fontSize: 20,
                            fontWeight: fwSemiBold,
                          ),
                          7.width,
                          TextWidget(
                            text: "recommend fare",
                            color: AppColor.black,
                            fontSize: 12,
                            fontWeight: fwNormal,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            20.height,

            // Search again button
            InkWell(
              onTap: () {
                FindingDriverController().cancelSearch();
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: Container(
                height: ResSize.h * 47,
                decoration: BoxDecoration(
                  color: AppColor.primary,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(ResSize.w * 8),
                    bottomRight: Radius.circular(ResSize.w * 8),
                  ),
                ),
                child: Center(
                  child: TextWidget(
                    text: "Search again",
                    color: AppColor.white,
                    fontSize: 16,
                    fontWeight: fwNormal,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
