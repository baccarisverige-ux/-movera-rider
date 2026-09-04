import 'package:flutter/material.dart';
import 'package:riding_app/constants/appassets.dart';
import 'package:riding_app/constants/appcolors.dart';
import 'package:riding_app/constants/appfontweight.dart';
import 'package:riding_app/presentation/common/help%20and%20support/help_and_support.dart';
import 'package:riding_app/presentation/common/trips/trips.dart';
import 'package:riding_app/presentation/driver/documents/document.dart';
import 'package:riding_app/presentation/driver/earnings/earnings.dart';
import 'package:riding_app/presentation/driver/profile/profile.dart';
import 'package:riding_app/presentation/driver/settings/settings.dart';
import 'package:riding_app/widgets/custom_text_widget.dart';
import 'package:riding_app/widgets/navigation_transition.dart';
import 'package:riding_app/widgets/responsive_size.dart';
import 'package:riding_app/widgets/sizedbox_extention.dart';

class DriverSideMenu extends StatelessWidget {
  const DriverSideMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      clipBehavior: Clip.none,
      backgroundColor: AppColor.secondary,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      width: MediaQuery.of(context).size.width * 0.78,
      child: Container(
        decoration: BoxDecoration(color: AppColor.secondary),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              40.height,
              // User Profile Section
              Padding(
                padding: EdgeInsets.symmetric(horizontal: ResSize.w * 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          RightToLeftTransition(DriverProfile()),
                        );
                      },
                      child: Row(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: ResSize.w * 60,
                                height: ResSize.h * 60,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  image: DecorationImage(
                                    image: AssetImage(AppAssets.profile),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              12.width,
                              TextWidget(
                                text: "Morgan Mill",
                                color: AppColor.primary,
                                fontSize: 16,
                                fontWeight: fwMedium,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              11.height,
              Container(
                height: ResSize.h * 4,
                width: double.infinity,
                color: Color(0xffFAFAFA),
              ),
              // Menu Items
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20 * ResSize.w,
                        ),
                        child: Column(
                          children: [
                            _buildMenuItem(
                              icon: AppAssets.earnings,
                              iconScaleSize: 1.3,
                              title: "Earnings",
                              onTap: () {
                                Navigator.push(
                                  context,
                                  RightToLeftTransition(EarningStatsScreen()),
                                );
                              },
                            ),
                            _buildMenuItem(
                              icon: AppAssets.trip,
                              title: "Trips history",
                              onTap: () {
                                Navigator.push(
                                  context,
                                  RightToLeftTransition(
                                    TripsScreen(showBackIcon: true),
                                  ),
                                );
                              },
                            ),
                            _buildMenuItem(
                              icon: AppAssets.documents,
                              title: "Documents",
                              onTap: () {
                                Navigator.push(
                                  context,
                                  RightToLeftTransition(DriverDocuments()),
                                );
                              },
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
                              icon: AppAssets.settings,
                              title: "Settings",
                              onTap: () {
                                Navigator.push(
                                  context,
                                  RightToLeftTransition(DriverSettingsScreen()),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              20.height,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required String icon,
    required String title,
    required VoidCallback onTap,
    double iconScaleSize = 1.2,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 14 * ResSize.h),
        child: Row(
          children: [
            Transform.scale(
              scale: iconScaleSize,
              child: Image.asset(
                icon,
                height: ResSize.h * 20,
                color: Color(0xff6B6B6B),
              ),
            ),
            16.width,
            TextWidget(
              text: title,
              color: Color(0xff6B6B6B),
              fontSize: 16,
              fontWeight: fwMedium,
            ),
          ],
        ),
      ),
    );
  }
}
