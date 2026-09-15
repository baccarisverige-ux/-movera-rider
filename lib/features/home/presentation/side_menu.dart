import 'package:flutter/material.dart';
import 'package:movera_rider/app/di.dart';
import 'package:movera_rider/core/constants/appassets.dart';
import 'package:movera_rider/core/constants/appfontweight.dart';
import 'package:movera_rider/features/wallet/presentation/wallet.dart';
import 'package:movera_rider/features/history/presentation/ride_history.dart';
import 'package:movera_rider/features/support/presentation/support.dart';
import 'package:movera_rider/features/safety/presentation/safety_hub.dart';
import 'package:movera_rider/features/profile/presentation/refer_and_earn.dart';
import 'package:movera_rider/shared/widgets/custom_text_widget.dart';
import 'package:movera_rider/shared/widgets/navigation_transition.dart';
import 'package:movera_rider/shared/widgets/responsive_size.dart';
import 'package:movera_rider/shared/widgets/sizedbox_extention.dart';

class RiderSideMenu extends StatelessWidget {
  const RiderSideMenu({super.key});

  static const Color _ink = Color(0xFF1C2329);
  static const Color _muted = Color(0xFF7A858E);
  static const Color _accent = Color(0xFF2D5878);
  static const Color _canvas = Color(0xFFF3F5F6);
  static const Color _card = Color(0xFFFFFFFF);
  static const Color _icon = Color(0xFF3A4550);

  Future<void> _pushPage(BuildContext context, Widget page) async {
    final nav = Navigator.of(context);
    final scaffold = Scaffold.of(context);
    scaffold.closeDrawer();
    await nav.push(RightToLeftTransition(page));
    if (scaffold.mounted) scaffold.openDrawer();
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: _canvas,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      width: MediaQuery.of(context).size.width * 0.84,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: ColoredBox(
        color: _canvas,
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    ResSize.w * 16,
                    ResSize.h * 12,
                    ResSize.w * 16,
                    ResSize.h * 12,
                  ),
                  child: Column(
                    children: [
                      _profileCard(),
                      14.height,
                      _menuCard(context),
                      14.height,
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

  Widget _cardSurface({required Widget child, EdgeInsetsGeometry? padding}) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _profileCard() {
    final controller = AppScope.instance.profile;
    final profile = controller.profile;
    final hasPhoto = profile.photoAsset.trim().isNotEmpty;

    return _cardSurface(
      padding: EdgeInsets.fromLTRB(
        ResSize.w * 18,
        ResSize.h * 18,
        ResSize.w * 18,
        ResSize.h * 18,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipOval(
                child: SizedBox(
                  width: ResSize.w * 56,
                  height: ResSize.h * 56,
                  child: hasPhoto
                      ? Image.asset(profile.photoAsset, fit: BoxFit.cover)
                      : ColoredBox(
                          color: const Color(0xFFE7EDF1),
                          child: Icon(
                            Icons.person_outline_rounded,
                            color: _muted,
                            size: 28 * ResSize.h,
                          ),
                        ),
                ),
              ),
              14.width,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextWidget(
                      text: controller.displayName(),
                      color: _ink,
                      fontSize: 18,
                      fontWeight: fwSemiBold,
                    ),
                    4.height,
                    TextWidget(
                      text: 'Rider',
                      color: _muted,
                      fontSize: 13,
                      fontWeight: fwMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
          14.height,
          Row(
            children: [
              Icon(
                Icons.star_border_rounded,
                color: _accent,
                size: 18 * ResSize.h,
              ),
              6.width,
              TextWidget(
                text: 'Rating unavailable',
                color: _muted,
                fontSize: 13.5,
                fontWeight: fwMedium,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _menuCard(BuildContext context) {
    final items = <({IconData? icon, String? image, String title, VoidCallback onTap})>[
      (
        icon: Icons.account_balance_wallet_outlined,
        image: null,
        title: 'Wallet',
        onTap: () => _pushPage(context, const WalletHome()),
      ),
      (
        icon: Icons.history_rounded,
        image: null,
        title: 'Ride History',
        onTap: () => _pushPage(context, RideHistory()),
      ),
      (
        icon: Icons.credit_card_outlined,
        image: null,
        title: 'Payments',
        onTap: () => _pushPage(context, const WalletScreen()),
      ),
      (
        icon: null,
        image: AppAssets.safetyShield,
        title: 'Safety',
        onTap: () => _pushPage(context, const SafetyHub()),
      ),
      (
        icon: Icons.headset_mic_outlined,
        image: null,
        title: 'Support',
        onTap: () => _pushPage(context, const SupportHome()),
      ),
      (
        icon: Icons.mail_outline_rounded,
        image: null,
        title: 'Invite Friends',
        onTap: () => _pushPage(context, const ReferAndEarn()),
      ),
      (
        icon: Icons.info_outline_rounded,
        image: null,
        title: 'About',
        onTap: () => _pushPage(
          context,
          const HelpArticle(
            title: 'About Movera',
            body:
                'Movera is a premium ride app for Sweden. Book Movera, Comfort, Premium, Priority, XL, Electric, and Pet — then pay with card, Swish, Apple Pay, or cash.',
          ),
        ),
      ),
    ];

    return _cardSurface(
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++)
            _menuRow(
              icon: items[i].icon,
              image: items[i].image,
              title: items[i].title,
              onTap: items[i].onTap,
              isFirst: i == 0,
              isLast: i == items.length - 1,
            ),
        ],
      ),
    );
  }

  Widget _menuRow({
    IconData? icon,
    String? image,
    required String title,
    required VoidCallback onTap,
    required bool isFirst,
    required bool isLast,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.vertical(
          top: isFirst ? const Radius.circular(22) : Radius.zero,
          bottom: isLast ? const Radius.circular(22) : Radius.zero,
        ),
        splashColor: _accent.withValues(alpha: 0.05),
        highlightColor: _accent.withValues(alpha: 0.03),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            ResSize.w * 18,
            ResSize.h * 16,
            ResSize.w * 18,
            ResSize.h * 16,
          ),
          child: Row(
            children: [
              SizedBox(
                width: ResSize.w * 26,
                height: ResSize.h * 26,
                child: image != null
                    ? Image.asset(image, fit: BoxFit.contain)
                    : Icon(icon, size: 22 * ResSize.h, color: _icon),
              ),
              16.width,
              Expanded(
                child: TextWidget(
                  text: title,
                  color: _ink,
                  fontSize: 16,
                  fontWeight: fwMedium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _becomeDriverCard() {
    return _cardSurface(
      padding: EdgeInsets.symmetric(
        horizontal: ResSize.w * 18,
        vertical: ResSize.h * 16,
      ),
      child: Row(
        children: [
          Icon(
            Icons.directions_car_outlined,
            size: 22 * ResSize.h,
            color: _accent,
          ),
          16.width,
          TextWidget(
            text: 'Become a driver',
            color: _ink,
            fontSize: 16,
            fontWeight: fwMedium,
          ),
        ],
      ),
    );
  }

  Widget _footer() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        ResSize.w * 16,
        ResSize.h * 8,
        ResSize.w * 16,
        ResSize.h * 16,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(AppAssets.logo, height: ResSize.h * 18),
          8.width,
          TextWidget(
            text: 'Powered by',
            color: _muted,
            fontSize: 11,
            fontWeight: fwMedium,
          ),
          8.width,
          Image.asset(AppAssets.skypulse, height: ResSize.h * 18),
        ],
      ),
    );
  }
}
