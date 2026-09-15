// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:movera_rider/core/constants/appcolors.dart';
import 'package:movera_rider/core/constants/appfontweight.dart';
import 'package:movera_rider/shared/design_system/movera_sheet.dart';
import 'package:movera_rider/shared/widgets/custom_text_widget.dart';
import 'package:movera_rider/shared/widgets/responsive_size.dart';
import 'package:movera_rider/shared/widgets/sizedbox_extention.dart';

Future<T?> showPickupLocationBottomSheet<T>(BuildContext context) {
  return MoveraSheet.show<T>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (BuildContext context) {
      return const PickupLocationBottomSheet();
    },
  );
}

class PickupLocationBottomSheet extends StatelessWidget {
  const PickupLocationBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.only(
            left: ResSize.w * 16,
            right: ResSize.w * 16,
            top: ResSize.h * 31,
            bottom: ResSize.h * 31,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: ResSize.w * 7,
                  vertical: ResSize.h * 14,
                ),
                decoration: BoxDecoration(
                  color: AppColor.liteBlue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: ResSize.w * 40,
                      height: ResSize.h * 40,
                      decoration: BoxDecoration(
                        color: AppColor.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.location_on,
                        color: Colors.white,
                        size: 20 * ResSize.h,
                      ),
                    ),
                    12.width,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextWidget(
                            text: 'Pickup location',
                            color: AppColor.subtitle,
                            fontSize: 10,
                            fontWeight: fwMedium,
                          ),
                          TextWidget(
                            text: 'Location unavailable',
                            color: AppColor.darkTitle,
                            fontSize: 16,
                            fontWeight: fwNormal,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              16.height,
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: ResSize.w * 12,
                  vertical: ResSize.h * 14,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColor.border, width: 0.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextWidget(
                      text: 'No location suggestions',
                      color: AppColor.title,
                      fontSize: 14,
                      fontWeight: fwSemiBold,
                    ),
                    4.height,
                    TextWidget(
                      text: 'Location suggestions aren’t connected in this build yet.',
                      color: AppColor.subtitle,
                      fontSize: 12,
                      fontWeight: fwNormal,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
