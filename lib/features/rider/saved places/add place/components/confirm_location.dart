// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:movera_rider/core/constants/appassets.dart';
import 'package:movera_rider/core/constants/appcolors.dart';
import 'package:movera_rider/core/constants/appfontweight.dart';
import 'package:movera_rider/shared/widgets/custom_text_widget.dart';
import 'package:movera_rider/shared/widgets/responsive_size.dart';
import 'package:movera_rider/shared/widgets/sizedbox_extention.dart';

Future<T?> showPickupLocationBottomSheet<T>(BuildContext context) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext context) {
      return PickupLocationBottomSheet();
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
        decoration: BoxDecoration(
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
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pickup Location Section
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
                            text: "Pickup location",
                            color: AppColor.subtitle,
                            fontSize: 10,
                            fontWeight: fwMedium,
                          ),
                          TextWidget(
                            text: "F10 markaz, Islamabad",
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
              // Location List
              ...List.generate(5, (index) => _buildLocationItem(index)),
              300.height,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationItem(int index) {
    final locations = [
      {
        'title': '765 Ludwig Passage',
        'subtitle': 'Hotel - Tashkent, Alisher Navol Stree, A',
      },
      {
        'title': '765 Ludwig Passage',
        'subtitle': 'Hotel - Tashkent, Alisher Navol Stree, A',
      },
      {
        'title': '765 Ludwig Passage',
        'subtitle': 'Hotel - Tashkent, Alisher Navol Stree, A',
      },
      {
        'title': '765 Ludwig Passage',
        'subtitle': 'Hotel - Tashkent, Alisher Navol Stree, A',
      },
      {
        'title': '765 Ludwig Passage',
        'subtitle': 'Hotel - Tashkent, Alisher Navol Stree, A',
      },
    ];

    return Column(
      children: [
        InkWell(
          onTap: () {
            Get.back();
          },
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset(
                AppAssets.locationFill,
                color: Colors.grey.shade400,
                height: ResSize.h * 20,
              ),
              12.width,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextWidget(
                      text: locations[index]['title']!,
                      color: AppColor.title,
                      fontSize: 16,
                      fontWeight: fwNormal,
                    ),
                    4.height,
                    TextWidget(
                      text: locations[index]['subtitle']!,
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
        if (index < 4) ...[
          10.height,
          Padding(
            padding: EdgeInsets.only(left: ResSize.w * 30),
            child: Divider(color: Colors.grey.shade200, height: 1),
          ),
          10.height,
        ],
      ],
    );
  }
}
