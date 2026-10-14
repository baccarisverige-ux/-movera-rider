import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movera_rider/app/di.dart';
import 'package:movera_rider/core/constants/appassets.dart';
import 'package:movera_rider/features/home/presentation/widgets/premium_bottom_nav_item.dart';
import 'package:movera_rider/features/wallet/presentation/wallet.dart';
import 'package:movera_rider/features/history/presentation/ride_history.dart';
import 'package:movera_rider/features/notifications/presentation/notifications.dart';
import 'package:movera_rider/features/saved_places/presentation/saved_places.dart';
import 'package:movera_rider/features/support/presentation/support.dart';
import 'package:movera_rider/features/safety/presentation/safety_hub.dart';
import 'package:movera_rider/shared/widgets/navigation_transition.dart';

/// The rider's menu as a full-screen page: name and photo, Wallet as a wide
/// card, the other destinations as a grid of soft tiles, About as the
/// closing card, and Home's bottom bar underneath.
class RiderMenuPage extends StatelessWidget {
  const RiderMenuPage({
    super.key,
    this.onStartBooking,
    this.onPayment,
    this.onSchedule,
    this.onAccount,
  });

  /// Called when a menu page asks to go straight to booking (for example
  /// Ride History's empty-state "Book a ride") instead of back to the menu.
  final VoidCallback? onStartBooking;

  /// Home's bottom-bar actions, so the bar works here exactly as on Home.
  final VoidCallback? onPayment;
  final VoidCallback? onSchedule;
  final VoidCallback? onAccount;

  static Future<void> open(
    BuildContext context, {
    VoidCallback? onStartBooking,
    VoidCallback? onPayment,
    VoidCallback? onSchedule,
    VoidCallback? onAccount,
  }) {
    return Navigator.of(context).push(
      RightToLeftTransition(
        RiderMenuPage(
          onStartBooking: onStartBooking,
          onPayment: onPayment,
          onSchedule: onSchedule,
          onAccount: onAccount,
        ),
      ),
    );
  }

  static const Color _ink = Color(0xFF1D252C);
  static const Color _muted = Color(0xFF6B757D);
  static const Color _card = Color(0xFFF3F4F5);
  static const Color _line = Color(0xFFE7EBEE);
  static const Color _avatarTint = Color(0xFFE6EAEE);

  Future<void> _pushPage(BuildContext context, Widget page) async {
    final nav = Navigator.of(context);
    final result = await nav.push<Object?>(RightToLeftTransition(page));
    if (!nav.mounted) return;
    // D-026: Ride History's "Book a ride" goes to booking, not back here.
    if (result == RideHistory.startBookingResult) {
      nav.pop();
      onStartBooking?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final groups = _groups(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _profileHeader(),
                    const SizedBox(height: 28),
                    _wideCard(groups.first.first),
                    const SizedBox(height: 10),
                    _grid([
                      ...groups.first.skip(1),
                      ...groups[1],
                      ...groups[2].take(2),
                    ]),
                    const SizedBox(height: 10),
                    _wideCard(groups[2].last),
                  ],
                ),
              ),
            ),
            _bottomBar(context),
          ],
        ),
      ),
    );
  }

  TextStyle _text(
    double size, {
    FontWeight weight = FontWeight.w500,
    Color color = _ink,
    double? height,
    double? letterSpacing,
  }) {
    return GoogleFonts.poppins(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  /// The rider's name, large, with the photo on the right.
  Widget _profileHeader() {
    final controller = AppScope.instance.profile;
    final profile = controller.profile;
    final hasPhoto = profile.photoAsset.trim().isNotEmpty;

    return Row(
      children: [
        Expanded(
          child: Text(
            controller.displayName(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: _text(
              30,
              weight: FontWeight.w700,
              height: 1.1,
              letterSpacing: -0.8,
            ),
          ),
        ),
        const SizedBox(width: 16),
        ClipOval(
          child: SizedBox(
            width: 68,
            height: 68,
            child: hasPhoto
                ? Image.asset(
                    excludeFromSemantics: true,
                    profile.photoAsset,
                    fit: BoxFit.cover,
                  )
                : const ColoredBox(
                    color: _avatarTint,
                    child: Icon(Icons.person_rounded, color: _muted, size: 34),
                  ),
          ),
        ),
      ],
    );
  }

  List<List<_MenuItem>> _groups(BuildContext context) {
    return <List<_MenuItem>>[
      [
        _MenuItem(
          icon: Icons.account_balance_wallet_outlined,
          title: 'Wallet',
          detail: _walletBalance(),
          onTap: () => _pushPage(context, const WalletAndPaymentsScreen()),
        ),
        _MenuItem(
          icon: Icons.history_rounded,
          title: 'Ride History',
          onTap: () => _pushPage(context, RideHistory()),
        ),
        _MenuItem(
          icon: Icons.credit_card_outlined,
          title: 'Payments',
          onTap: () =>
              _pushPage(context, const WalletAndPaymentsScreen(initialTab: 1)),
        ),
      ],
      [
        // Notifications and Saved places were both finished screens with no
        // way in: nothing in the app built either of them.
        _MenuItem(
          icon: Icons.notifications_none_rounded,
          title: 'Notifications',
          onTap: () => _pushPage(context, const NotificationScreen()),
        ),
        _MenuItem(
          icon: Icons.bookmark_border_rounded,
          title: 'Saved Places',
          onTap: () => _pushPage(context, SavedPlaces()),
        ),
      ],
      [
        _MenuItem(
          icon: Icons.shield_outlined,
          title: 'Safety',
          onTap: () => _pushPage(context, const SafetyHub()),
        ),
        _MenuItem(
          icon: Icons.headset_mic_outlined,
          title: 'Support',
          onTap: () => _pushPage(context, const SupportHome()),
        ),
        _MenuItem(
          icon: Icons.info_outline_rounded,
          title: 'About',
          onTap: () => _pushPage(
            context,
            const HelpArticle(
              title: 'About Movera',
              body:
                  'Movera is a ride app for Sweden. Available booking and payment options are shown during your ride request.',
            ),
          ),
        ),
      ],
    ];
  }

  /// A wide grey card: icon, bold title, the detail or a chevron on the right.
  Widget _wideCard(_MenuItem item) {
    return _tap(
      item,
      height: 80,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Icon(item.icon, size: 26, color: _ink),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _text(18, weight: FontWeight.w600),
              ),
            ),
            item.detail ??
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 24,
                  color: Color(0xFFB8C0C7),
                ),
          ],
        ),
      ),
    );
  }

  /// The wallet balance on the right of the Wallet card.
  Widget _walletBalance() {
    return FutureBuilder<double>(
      future: AppScope.instance.walletController.loadBalance(),
      builder: (context, snapshot) {
        final balance = snapshot.data;
        if (balance == null) return const SizedBox.shrink();
        return Text(
          'kr ${balance.toStringAsFixed(0)}',
          maxLines: 1,
          style: _text(17, weight: FontWeight.w600),
        );
      },
    );
  }

  /// Two columns of grey tiles, icon then bold label.
  Widget _grid(List<_MenuItem> items) {
    final rows = <Widget>[];
    for (var i = 0; i < items.length; i += 2) {
      rows.add(
        Row(
          children: [
            Expanded(child: _tile(items[i])),
            const SizedBox(width: 10),
            Expanded(
              child: i + 1 < items.length
                  ? _tile(items[i + 1])
                  : const SizedBox(),
            ),
          ],
        ),
      );
      if (i + 2 < items.length) rows.add(const SizedBox(height: 10));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows,
    );
  }

  Widget _tile(_MenuItem item) {
    return _tap(
      item,
      height: 76,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Icon(item.icon, size: 24, color: _ink),
            const SizedBox(width: 12),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  item.title,
                  maxLines: 1,
                  style: _text(16, weight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tap(_MenuItem item, {required double height, required Widget child}) {
    return Semantics(
      button: true,
      label: item.title,
      onTap: item.onTap,
      child: ExcludeSemantics(
        child: Material(
          color: _card,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: item.onTap,
            splashColor: _ink.withValues(alpha: 0.05),
            highlightColor: _ink.withValues(alpha: 0.04),
            child: SizedBox(height: height, child: child),
          ),
        ),
      ),
    );
  }

  /// Home's bottom bar: Map goes back to the map, the rest open the same
  /// screens they open from Home.
  Widget _bottomBar(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 8 + bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _line, width: 0.8)),
      ),
      child: Row(
        children: [
          Expanded(
            child: PremiumBottomNavItem(
              iconAsset: AppAssets.navMap,
              label: 'Map',
              onTap: () => Navigator.of(context).pop(),
            ),
          ),
          Expanded(
            child: PremiumBottomNavItem(
              iconAsset: AppAssets.navPayment,
              label: 'Payment',
              onTap: onPayment ?? () {},
            ),
          ),
          Expanded(
            child: PremiumBottomNavItem(
              iconAsset: AppAssets.navSchedule,
              label: 'Schedule ride',
              onTap: onSchedule ?? () {},
            ),
          ),
          Expanded(
            child: PremiumBottomNavItem(
              iconAsset: AppAssets.navAccount,
              label: 'Account',
              onTap: onAccount ?? () {},
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItem {
  const _MenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.detail,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  /// Shown on the right of a wide card instead of the chevron.
  final Widget? detail;
}
