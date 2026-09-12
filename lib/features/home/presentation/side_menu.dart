import 'package:flutter/material.dart';
import 'package:movera_rider/core/constants/appassets.dart';
import 'package:movera_rider/core/constants/appcolors.dart';
import 'package:movera_rider/core/constants/appfontweight.dart';
import 'package:movera_rider/features/profile/application/profile_controller.dart';
import 'package:movera_rider/features/wallet/presentation/wallet.dart';
import 'package:movera_rider/features/promotions/presentation/promotions.dart';
import 'package:movera_rider/features/history/presentation/ride_history.dart';
import 'package:movera_rider/features/history/presentation/my_rides.dart';
import 'package:movera_rider/features/support/presentation/support.dart';
import 'package:movera_rider/features/profile/presentation/refer_and_earn.dart';
import 'package:movera_rider/features/notifications/presentation/notifications.dart';
import 'package:movera_rider/shared/widgets/custom_text_widget.dart';
import 'package:movera_rider/shared/widgets/navigation_transition.dart';
import 'package:movera_rider/shared/widgets/responsive_size.dart';
import 'package:movera_rider/shared/widgets/sizedbox_extention.dart';

class RiderSideMenu extends StatelessWidget {
  const RiderSideMenu({super.key});

  static const Color _ink = Color(0xFF1D252C);
  static const Color _muted = Color(0xFF66727C);
  static const Color _accent = Color(0xFF2D5878);
  static const Color _softSurface = Color(0xFFF6F8FA);
  static const Color _line = Color(0xFFE9EDF0);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColor.white,
      elevation: 14,
      surfaceTintColor: Colors.transparent,
      width: MediaQuery.of(context).size.width * 0.83,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(26),
          bottomRight: Radius.circular(26),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Container(
        color: AppColor.white,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _profileHeader(),
              const Divider(height: 1, thickness: 1, color: _line),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    ResSize.w * 18,
                    ResSize.h * 10,
                    ResSize.w * 18,
                    ResSize.h * 14,
                  ),
                  child: Column(
                    children: [
                      _buildMenuItem(
                        icon: AppAssets.wallet2,
                        title: "Wallet",
                        onTap: () {
                          Navigator.push(
                            context,
                            RightToLeftTransition(const WalletHome()),
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
                        onTap: () {
                          Navigator.push(
                            context,
                            RightToLeftTransition(const WalletScreen()),
                          );
                        },
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
                        onTap: () {
                          Navigator.push(
                            context,
                            RightToLeftTransition(
                              const HelpArticle(
                                title: 'Safety',
                                body:
                                    'Share your trip, call emergency services, and keep trusted contacts close. Movera Support can also help if a ride does not feel right.',
                              ),
                            ),
                          );
                        },
                      ),
                      _buildMenuItem(
                        icon: AppAssets.support,
                        title: "Support",
                        onTap: () {
                          Navigator.push(
                            context,
                            RightToLeftTransition(const SupportHome()),
                          );
                        },
                      ),
                      _buildMenuItem(
                        icon: AppAssets.inviteFriends,
                        title: "Invite Friends",
                        onTap: () {
                          Navigator.push(
                            context,
                            RightToLeftTransition(const ReferAndEarn()),
                          );
                        },
                      ),
                      _buildMenuItem(
                        icon: AppAssets.about,
                        title: "About",
                        onTap: () {
                          Navigator.push(
                            context,
                            RightToLeftTransition(
                              const HelpArticle(
                                title: 'About Movera',
                                body:
                                    'Movera is a premium ride app for Sweden. Book Movera, Comfort, Premium, Priority, XL, Electric, and Pet — then pay with card, Swish, Apple Pay, or cash.',
                              ),
                            ),
                          );
                        },
                      ),
                      10.height,
                      _becomeDriverCard(),
                    ],
                  ),
                ),
              ),
              _footer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _profileHeader() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        ResSize.w * 24,
        ResSize.h * 22,
        ResSize.w * 24,
        ResSize.h * 20,
      ),
      child: Row(
        children: [
          Container(
            width: ResSize.w * 66,
            height: ResSize.h * 66,
            padding: const EdgeInsets.all(2.5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColor.white,
              border: Border.all(color: _line, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 18,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(AppAssets.profileImg, fit: BoxFit.cover),
            ),
          ),
          15.width,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextWidget(
                  text: ProfileController().displayName(),
                  color: _ink,
                  fontSize: 18,
                  fontWeight: fwSemiBold,
                ),
                7.height,
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: ResSize.w * 9,
                    vertical: ResSize.h * 4,
                  ),
                  decoration: BoxDecoration(
                    color: _softSurface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _line, width: 0.8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.star_rounded,
                        color: const Color(0xFFF4B928),
                        size: 16 * ResSize.h,
                      ),
                      4.width,
                      TextWidget(
                        text: "4.9",
                        color: _ink,
                        fontSize: 13,
                        fontWeight: fwSemiBold,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required String icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: ResSize.h * 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: _accent.withOpacity(0.06),
          highlightColor: _accent.withOpacity(0.035),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: ResSize.w * 7,
              vertical: ResSize.h * 8,
            ),
            child: Row(
              children: [
                Container(
                  height: ResSize.h * 38,
                  width: ResSize.w * 38,
                  decoration: BoxDecoration(
                    color: _softSurface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _line, width: 0.7),
                  ),
                  alignment: Alignment.center,
                  child: Image.asset(
                    icon,
                    height: 20 * ResSize.h,
                    color: _accent,
                  ),
                ),
                14.width,
                Expanded(
                  child: TextWidget(
                    text: title,
                    color: _ink,
                    fontSize: 15.5,
                    fontWeight: fwMedium,
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: ResSize.h * 19,
                  color: _muted.withOpacity(0.55),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _becomeDriverCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: ResSize.w * 15,
        vertical: ResSize.h * 14,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F5F8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDCE7ED), width: 0.9),
      ),
      child: Row(
        children: [
          Container(
            width: ResSize.w * 38,
            height: ResSize.h * 38,
            decoration: BoxDecoration(
              color: AppColor.white.withOpacity(0.82),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Image.asset(
              AppAssets.driverIcon,
              height: 21 * ResSize.h,
              color: _accent,
            ),
          ),
          13.width,
          TextWidget(
            text: "Become a driver",
            color: _accent,
            fontSize: 16,
            fontWeight: fwSemiBold,
          ),
        ],
      ),
    );
  }

  Widget _footer() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        ResSize.w * 18,
        ResSize.h * 15,
        ResSize.w * 18,
        ResSize.h * 18,
      ),
      decoration: const BoxDecoration(
        color: AppColor.white,
        border: Border(top: BorderSide(color: _line, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(AppAssets.logo, height: ResSize.h * 20),
          8.width,
          TextWidget(
            text: "Powered by",
            color: _muted,
            fontSize: 11.5,
            fontWeight: fwMedium,
          ),
          8.width,
          Image.asset(AppAssets.skypulse, height: ResSize.h * 20),
        ],
      ),
    );
  }
}
