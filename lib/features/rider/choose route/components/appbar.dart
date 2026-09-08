import 'package:flutter/material.dart';
import 'package:movera_rider/core/constants/appcolors.dart';
import 'package:movera_rider/core/constants/appfontweight.dart';
import 'package:movera_rider/shared/widgets/custom_text_widget.dart';
import 'package:movera_rider/shared/widgets/responsive_size.dart';
import 'package:movera_rider/shared/widgets/sizedbox_extention.dart';

class ChooseRouteAppBar extends StatelessWidget {
  final VoidCallback? onAddPressed;

  const ChooseRouteAppBar({super.key, this.onAddPressed});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      actionsPadding: EdgeInsets.all(0),
      automaticallyImplyLeading: false,
      backgroundColor: AppColor.white,
      clipBehavior: Clip.none,
      foregroundColor: AppColor.white,
      elevation: 0,
      centerTitle: true,
      title: TextWidget(
        text: "Choose your route",
        color: AppColor.black,
        fontSize: 16,
        fontWeight: fwMedium,
      ),
      leading: Row(
        children: [
          16.width,
          InkWell(
            onTap: () {
              Navigator.pop(context);
            },
            child: Container(
              height: ResSize.h * 28,
              width: ResSize.w * 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColor.white,
                boxShadow: [
                  BoxShadow(
                    // ignore: deprecated_member_use
                    color: AppColor.black.withOpacity(0.1),
                    blurRadius: 4,
                    spreadRadius: 0,
                    offset: const Offset(0, 0),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  Icons.arrow_back_ios_rounded,
                  color: AppColor.black,
                  size: ResSize.h * 18,
                ),
              ),
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: EdgeInsets.only(right: ResSize.w * 16),
          child: InkWell(
            onTap: onAddPressed,
            child: Container(
              width: ResSize.w * 80,
              height: ResSize.h * 25,
              decoration: BoxDecoration(
                color: AppColor.white,
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(
                    // ignore: deprecated_member_use
                    color: AppColor.black.withOpacity(0.1),
                    blurRadius: 4,
                    spreadRadius: 0,
                    offset: const Offset(0, 0),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_rounded,
                    color: AppColor.black,
                    size: ResSize.h * 18,
                  ),
                  3.width,
                  TextWidget(
                    text: "Add Stop",
                    color: AppColor.black,
                    fontSize: 10,
                    fontWeight: fwNormal,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
