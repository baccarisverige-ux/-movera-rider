// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:movera_rider/core/constants/appassets.dart';
import 'package:movera_rider/core/constants/appcolors.dart';
import 'package:movera_rider/core/constants/appfontweight.dart';
import 'package:movera_rider/shared/widgets/custom_text_widget.dart';
import 'package:movera_rider/shared/widgets/responsive_size.dart';
import 'package:movera_rider/shared/widgets/sizedbox_extention.dart';
import 'package:movera_rider/features/rider/support/support.dart';
import 'package:movera_rider/shared/widgets/navigation_transition.dart';

class RiderProfile extends StatelessWidget {
  final VoidCallback? onClose;
  final PanelController controller;
  const RiderProfile({
    super.key,
    required this.onClose,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return SlidingUpPanel(
      color: AppColor.white,
      backdropColor: Colors.transparent,
      margin: EdgeInsets.all(0),
      minHeight: ResSize.h * 0,
      padding: EdgeInsets.symmetric(
        // horizontal: screenHorizPadding,
        vertical: ResSize.h * 20,
      ),
      boxShadow: [],
      isDraggable: true,
      defaultPanelState: PanelState.CLOSED,
      maxHeight: ResSize.h * 700,
      parallaxEnabled: false,
      controller: controller,
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(21),
        topRight: Radius.circular(21),
      ),
      panelBuilder: (ScrollController sc) => panelColumn(sc),
      // panelBuilder: (ScrollController sc) => panelColumn(sc, context),
      // body: widget.body,
    );
  }

  Widget panelColumn(ScrollController sc) {
    return SingleChildScrollView(
      controller: sc,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: screenHorizPadding),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                InkWell(
                  onTap: onClose,
                  child: Container(
                    height: ResSize.h * 22,
                    width: ResSize.w * 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xffE8E8E8),
                    ),
                    child: Center(
                      child: Icon(Icons.close_rounded, size: ResSize.h * 19),
                    ),
                  ),
                ),
                20.height,
              ],
            ),
          ),
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                height: ResSize.h * 85,
                width: ResSize.w * 85,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: AssetImage(AppAssets.profileImg),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Container(
                height: ResSize.h * 26,
                width: ResSize.w * 26,
                decoration: BoxDecoration(
                  color: AppColor.primary,
                  borderRadius: BorderRadius.circular(20 * ResSize.w),
                  border: Border.all(color: Colors.white, width: 1),
                ),
                child: Center(
                  child: Image.asset(AppAssets.camera, height: ResSize.h * 17),
                ),
              ),
            ],
          ),
          10.height,
          Center(
            child: TextWidget(
              text: "Ben Gleason",
              fontSize: 16,
              fontWeight: fwSemiBold,
              color: AppColor.darkTitle,
            ),
          ),
          26.height,
          Container(
            height: ResSize.h * 11,
            width: double.infinity,
            color: Color(0xffF3F3F3),
          ),
          14.height,
          Padding(
            padding: EdgeInsets.symmetric(horizontal: screenHorizPadding),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                card(icon: AppAssets.safety, title: "Safety"),
                15.width,
                card(
                  icon: AppAssets.support,
                  title: "Support",
                  onTap: () {
                    Navigator.push(
                      context,
                      RightToLeftTransition(const SupportHome()),
                    );
                  },
                ),
                15.width,
                card(icon: AppAssets.setting, title: "Settings"),
              ],
            ),
          ),
          14.height,
          Container(
            height: ResSize.h * 11,
            width: double.infinity,
            color: Color(0xffF3F3F3),
          ),
          16.height,
          _menuItem(title: 'Terms & conditions', onTap: () {}),
          _menuItem(title: 'Privacy policy', onTap: () {}),
          _menuItem(
            title: 'Need help?',
            onTap: () {
              Navigator.push(
                context,
                RightToLeftTransition(const SupportHome()),
              );
            },
          ),
          _menuItem(title: 'Log out', onTap: () {}, isLogout: true),

          // ✅ Rest of your code untouched
        ],
      ),
    );
  }

  Widget card({String? icon, title, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
      children: [
        Container(
          height: ResSize.h * 35,
          width: ResSize.w * 35,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xffEEEEEE),
          ),
          child: Center(
            child: Image.asset(
              icon!,
              height: ResSize.h * 20,
              color: AppColor.black,
            ),
          ),
        ),
        7.height,
        TextWidget(
          text: title,
          fontSize: 14,
          fontWeight: fwNormal,
          color: AppColor.subtitle,
        ),
      ],
      ),
    );
  }

  Widget _menuItem({
    required String title,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    return InkWell(
      onTap: onTap,
      splashColor: isLogout
          ? AppColor.red.withOpacity(0.1)
          : AppColor.primary.withOpacity(0.1),
      highlightColor: isLogout
          ? AppColor.red.withOpacity(0.1)
          : AppColor.primary.withOpacity(0.1),
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: 12 * ResSize.h,
          horizontal: screenHorizPadding,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextWidget(
              text: title,
              color: isLogout ? AppColor.red : AppColor.title,
              fontSize: 16,
              fontWeight: fwMedium,
            ),
            isLogout
                ? SizedBox()
                : Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: AppColor.subtitle,
                    size: ResSize.h * 18,
                  ),
          ],
        ),
      ),
    );
  }
}
