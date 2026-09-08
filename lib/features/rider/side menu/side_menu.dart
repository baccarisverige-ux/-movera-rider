import 'package:flutter/material.dart';
import 'package:movera_rider/core/constants/appassets.dart';
import 'package:movera_rider/core/constants/appcolors.dart';
import 'package:movera_rider/core/constants/appfontweight.dart';
import 'package:movera_rider/features/rider/my%20wallet/wallet.dart';
import 'package:movera_rider/features/rider/promotions/promotions.dart';
import 'package:movera_rider/features/rider/ride%20history/ride_history.dart';
import 'package:movera_rider/features/rider/my%20rides/my_rides.dart';
import 'package:movera_rider/shared/widgets/custom_text_widget.dart';
import 'package:movera_rider/shared/widgets/navigation_transition.dart';
import 'package:movera_rider/shared/widgets/responsive_size.dart';
import 'package:movera_rider/shared/widgets/sizedbox_extention.dart';

class RiderSideMenu extends StatelessWidget {
  const RiderSideMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      clipBehavior: Clip.none,
      backgroundColor: AppColor.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      width: MediaQuery.of(context).size.width * 0.78,
      child: Container(
        decoration: BoxDecoration(color: AppColor.white),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              10.height,
              // User Profile Section
              Padding(
                padding: EdgeInsets.symmetric(horizontal: ResSize.w * 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: ResSize.w * 60,
                      height: ResSize.h * 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        image: DecorationImage(
                          image: AssetImage(AppAssets.profileImg),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    10.height,
                    Row(
                      children: [
                        TextWidget(
                          text: "Ben Gleason",
                          color: AppColor.black,
                          fontSize: 16,
                          fontWeight: fwMedium,
                        ),
                        8.width,
                        Row(
                          children: [
                            Icon(
                              Icons.star_rounded,
                              color: Colors.amber,
                              size: 18 * ResSize.h,
                            ),
                            3.width,
                            TextWidget(
                              text: "4.9",
                              color: AppColor.black,
                              fontSize: 16,
                              fontWeight: fwMedium,
                            ),
                          ],
                        ),
                      ],
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
                              icon: AppAssets.wallet2,
                              title: "Wallet",
                              onTap: () {
                                Navigator.push(
                                  context,
                                  RightToLeftTransition(const WalletScreen()),
                                );
                              },
                            ),
                            _buildMenuItem(
                              icon: AppAssets.rideHistory,
                              title: "Ride History",
                              onTap: () {
                                Navigator.push(
                                  context,
                                  RightToLeftTransition(RideHistory()),
                                );
                              },
                            ),
                            _buildMenuItem(
                              icon: AppAssets.promotions,
                              title: "Promotions",
                              onTap: () {
                                Navigator.push(
                                  context,
                                  RightToLeftTransition(const Promotions()),
                                );
                              },
                            ),
                            _buildMenuItem(
                              icon: AppAssets.payment,
                              title: "Payments",
                              onTap: () {},
                            ),
                            _buildMenuItem(
                              icon: AppAssets.scheduledRides,
                              title: "Scheduled Rides",
                              onTap: () {
                                Navigator.push(
                                  context,
                                  RightToLeftTransition(MyRidesScreen()),
                                );
                              },
                            ),
                            _buildMenuItem(
                              icon: AppAssets.safety,
                              title: "Safety",
                              onTap: () {},
                            ),
                            _buildMenuItem(
                              icon: AppAssets.support,
                              title: "Support",
                              onTap: () {},
                            ),
                            _buildMenuItem(
                              icon: AppAssets.inviteFriends,
                              title: "Invite Friends",
                              onTap: () {},
                            ),
                            _buildMenuItem(
                              icon: AppAssets.about,
                              title: "About",
                              onTap: () {},
                            ),
                          ],
                        ),
                      ),
                      5.height,
                      // Call to Action Section
                      Container(
                        padding: EdgeInsets.only(
                          left: ResSize.w * 35,
                          top: ResSize.h * 14,
                          bottom: ResSize.h * 14,
                        ),
                        decoration: BoxDecoration(
                          // ignore: deprecated_member_use
                          color: const Color(0xFF215277).withOpacity(0.12),
                        ),
                        child: Row(
                          children: [
                            Image.asset(
                              AppAssets.driverIcon,
                              height: 24 * ResSize.h,
                            ),
                            13.width,
                            TextWidget(
                              text: "Become a driver",
                              color: Color(0xff215277),
                              fontSize: 16,
                              fontWeight: fwNormal,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Footer
              Container(
                height: ResSize.h * 4,
                width: double.infinity,
                color: Color(0xffFAFAFA),
              ),
              20.height,
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(AppAssets.logo, height: ResSize.h * 22),
                  7.width,
                  TextWidget(
                    text: "Powered by",
                    color: AppColor.black,
                    fontSize: 12,
                    fontWeight: fwMedium,
                  ),
                  7.width,
                  Image.asset(AppAssets.skypulse, height: ResSize.h * 22),
                ],
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
  }) {
    return InkWell(
      onTap: onTap,
      splashColor: Colors.amber,
      highlightColor: Colors.amber,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 14 * ResSize.h),
        child: Row(
          children: [
            Image.asset(icon, height: 22 * ResSize.h),
            16.width,
            TextWidget(
              text: title,
              color: AppColor.title,
              fontSize: 16,
              fontWeight: fwNormal,
            ),
          ],
        ),
      ),
    );
  }
}
