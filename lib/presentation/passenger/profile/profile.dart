import 'package:flutter/material.dart';
import 'package:riding_app/constants/appassets.dart';
import 'package:riding_app/constants/appcolors.dart';
import 'package:riding_app/constants/appfontweight.dart';
import 'package:riding_app/presentation/common/Refer%20and%20Earn/refer_and_earn.dart';
import 'package:riding_app/presentation/common/help%20and%20support/help_and_support.dart';
import 'package:riding_app/presentation/common/trips/trips.dart';
import 'package:riding_app/presentation/passenger/edit%20profile/edit_profile.dart';
import 'package:riding_app/widgets/custom_text_widget.dart';
import 'package:riding_app/widgets/navigation_transition.dart';
import 'package:riding_app/widgets/responsive_size.dart';
import 'package:riding_app/widgets/sizedbox_extention.dart';

class PassengerProfileScreen extends StatelessWidget {
  final bool showBackIcon;
  const PassengerProfileScreen({super.key, this.showBackIcon = true});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(ResSize.h * 70),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            AppBar(
              surfaceTintColor: Colors.transparent,
              clipBehavior: Clip.none,
              backgroundColor: Colors.white,
              elevation: 0,
              leading: showBackIcon
                  ? IconButton(
                      icon: Icon(
                        Icons.arrow_back,
                        color: AppColor.primary,
                        size: ResSize.setSp(24),
                      ),
                      onPressed: () => Navigator.pop(context),
                    )
                  : SizedBox(),
              title: TextWidget(
                text: "Profile",
                fontSize: 18,
                fontWeight: fwSemiBold,
                color: AppColor.primary,
              ),
              centerTitle: true,
              actions: [
                Padding(
                  padding: EdgeInsets.only(right: screenHorizPadding),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        TopToBottomTransition(ReferAndEarn()),
                      );
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: ResSize.w * 9,
                        vertical: ResSize.h * 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextWidget(
                        text: "Refer & Earn",
                        fontSize: 13,
                        fontWeight: fwMedium,
                        color: AppColor.secondary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            24.height,
            // Profile Picture and Name
            Center(
              child: Column(
                children: [
                  Container(
                    width: ResSize.w * 100,
                    height: ResSize.w * 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFF5F5F5),
                      image: const DecorationImage(
                        image: AssetImage(AppAssets.profile),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  16.height,
                  TextWidget(
                    text: "Mac Mort",
                    fontSize: 18,
                    fontWeight: fwSemiBold,
                    color: AppColor.primary,
                  ),
                ],
              ),
            ),
            48.height,
            // Menu Items
            _buildMenuItem(
              icon: AppAssets.profileIcon,
              title: "Edit Profile",
              onTap: () {
                Navigator.push(
                  context,
                  RightToLeftTransition(EditProfileScreen()),
                );
              },
            ),
            _buildMenuItem(
              icon: AppAssets.profileIcon,
              title: "Payment Method",
              onTap: () {
                //   Navigator.push(
                //   context,
                //   RightToLeftTransition(EditProfileScreen()),
                // );
              },
            ),
            _buildMenuItem(
              icon: AppAssets.tripIcon,
              title: "Your Trip",
              onTap: () {
                Navigator.push(
                  context,
                  RightToLeftTransition(TripsScreen(showBackIcon: true)),
                );
              },
            ),
            _buildMenuItem(
              icon: AppAssets.favouriteIcon,
              title: "Favourite",
              onTap: () {},
            ),
            _buildMenuItem(
              icon: AppAssets.helpSupportIcon,
              title: "Help & Support",
              onTap: () {
                Navigator.push(
                  context,
                  RightToLeftTransition(HelpAndSupportScreen()),
                );
              },
            ),
            _buildMenuItem(
              icon: AppAssets.legalIcon,
              title: "Legal",
              onTap: () {},
            ),
            _buildMenuItem(
              icon: AppAssets.logoutIcon,
              title: "Logout",
              isLogout: true,
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required String icon,
    required String title,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: screenHorizPadding),
        padding: EdgeInsets.symmetric(vertical: ResSize.h * 14),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColor.border, width: 1)),
        ),
        child: Row(
          children: [
            Image.asset(
              icon,
              color: isLogout ? AppColor.red : AppColor.subtitle,
              height: ResSize.setSp(24),
            ),
            16.width,
            Expanded(
              child: TextWidget(
                text: title,
                fontSize: 16,
                fontWeight: fwMedium,
                color: isLogout ? AppColor.red : AppColor.subtitle,
              ),
            ),
            if (!isLogout)
              Icon(
                Icons.chevron_right,
                color: AppColor.subtitle,
                size: ResSize.setSp(24),
              ),
          ],
        ),
      ),
    );
  }
}
