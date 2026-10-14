import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movera_rider/app/di.dart';
import 'package:movera_rider/core/constants/appassets.dart';
import 'package:movera_rider/features/wallet/presentation/wallet.dart';
import 'package:movera_rider/features/history/presentation/ride_history.dart';
import 'package:movera_rider/features/notifications/presentation/notifications.dart';
import 'package:movera_rider/features/saved_places/presentation/saved_places.dart';
import 'package:movera_rider/features/support/presentation/support.dart';
import 'package:movera_rider/features/safety/presentation/safety_hub.dart';
import 'package:movera_rider/shared/widgets/navigation_transition.dart';

class RiderSideMenu extends StatelessWidget {
  const RiderSideMenu({super.key, this.onStartBooking, this.onCoveredChanged});

  /// Called when a menu page asks to go straight to booking (for example
  /// Ride History's empty-state "Book a ride") instead of back to the menu.
  final VoidCallback? onStartBooking;

  /// U7: told `true` when a full-screen menu page is pushed over Home and
  /// `false` once it is popped, so Home can pause its puck work while hidden.
  final ValueChanged<bool>? onCoveredChanged;

  static const Color _ink = Color(0xFF1D252C);
  static const Color _muted = Color(0xFF6B757D);
  static const Color _card = Color(0xFFF3F4F5);
  static const Color _avatarTint = Color(0xFFE6EAEE);
  static const Color _chevron = Color(0xFFC5CBD1);

  Future<void> _pushPage(BuildContext context, Widget page) async {
    final nav = Navigator.of(context);
    final scaffold = Scaffold.of(context);
    scaffold.closeDrawer();

    // U7: push straight away and let the drawer close underneath. Waiting
    // for the close animation first added its full length to every
    // menu-to-page transition.
    if (!nav.mounted) return;
    onCoveredChanged?.call(true);
    final Object? result;
    try {
      result = await nav.push<Object?>(RightToLeftTransition(page));
    } finally {
      onCoveredChanged?.call(false);
    }
    if (!scaffold.mounted) return;
    if (result == RideHistory.startBookingResult) {
      onStartBooking?.call();
      return;
    }
    // U1: the menu page was opened from the drawer, so Back returns to the
    // drawer. Only reopen it once Home is genuinely the top route again —
    // never when the page was replaced or something else now sits above Home.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scaffold.mounted || scaffold.isDrawerOpen) return;
      final homeRoute = ModalRoute.of(scaffold.context);
      if (homeRoute != null && !homeRoute.isCurrent) return;
      scaffold.openDrawer();
    });
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final groups = _groups(context);
    return Drawer(
      backgroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      width: media.size.width * 0.92,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: ColoredBox(
        color: Colors.white,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _profileHeader(),
                      const SizedBox(height: 26),
                      // Wallet as the wide card, the rest as a grid of tiles,
                      // About as the closing wide card: the account-page
                      // layout, with our sections and wording.
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
              _footer(),
            ],
          ),
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

  /// The rider's name, large, with the avatar beside it.
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
        const SizedBox(width: 14),
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

  /// A wide grey card: icon, bold title, detail or chevron on the right.
  Widget _wideCard(_MenuItem item) {
    return _tap(
      item,
      height: 76,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
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
                  color: _chevron,
                ),
          ],
        ),
      ),
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
      height: 72,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Icon(item.icon, size: 22, color: _ink),
            const SizedBox(width: 10),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  item.title,
                  maxLines: 1,
                  style: _text(14.5, weight: FontWeight.w600),
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
          icon: Icons.verified_user_outlined,
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

  /// The wallet balance, shown under "Wallet" on its card.
  Widget _walletBalance() {
    return FutureBuilder<double>(
      future: AppScope.instance.walletController.loadBalance(),
      builder: (context, snapshot) {
        final balance = snapshot.data;
        if (balance == null) return const SizedBox.shrink();
        return Text(
          'kr ${balance.toStringAsFixed(0)}',
          maxLines: 1,
          style: _text(18, weight: FontWeight.w700),
        );
      },
    );
  }

  Widget _footer() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 18),
      child: Row(
        children: [
          Image.asset(
            excludeFromSemantics: true,
            AppAssets.logo,
            height: 18,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              'Movera Rider',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _text(12, color: _muted),
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

  /// A small line under the title on a shortcut card (the wallet balance).
  final Widget? detail;
}
