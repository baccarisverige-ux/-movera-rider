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
  static const Color _card = Color(0xFFF4F6F8);
  static const Color _line = Color(0xFFEDF0F3);
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
      width: media.size.width * 0.86,
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
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _profileHeader(),
                      const SizedBox(height: 26),
                      _shortcuts(groups.first),
                      const SizedBox(height: 22),
                      ..._list(groups.skip(1).toList()),
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
              24,
              weight: FontWeight.w700,
              height: 1.15,
              letterSpacing: -0.5,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: _line, width: 1.5),
          ),
          child: ClipOval(
            child: SizedBox(
              width: 54,
              height: 54,
              child: hasPhoto
                  ? Image.asset(
                      excludeFromSemantics: true,
                      profile.photoAsset,
                      fit: BoxFit.cover,
                    )
                  : const ColoredBox(
                      color: _avatarTint,
                      child: Icon(
                        Icons.person_rounded,
                        color: _muted,
                        size: 30,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  /// A round icon badge: white on the grey cards, grey on the white rows.
  Widget _badge(IconData icon, {required Color fill}) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(color: fill, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Icon(icon, size: 21, color: _ink),
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

  /// The money group as three shortcut cards; Wallet carries the balance.
  Widget _shortcuts(List<_MenuItem> items) {
    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(child: _shortcutCard(items[i])),
        ],
      ],
    );
  }

  Widget _shortcutCard(_MenuItem item) {
    return Semantics(
      button: true,
      label: item.title,
      onTap: item.onTap,
      child: ExcludeSemantics(
        child: Material(
          color: _card,
          borderRadius: BorderRadius.circular(18),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: item.onTap,
            splashColor: _ink.withValues(alpha: 0.05),
            highlightColor: _ink.withValues(alpha: 0.04),
            child: SizedBox(
              height: 112,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 6, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _badge(item.icon, fill: Colors.white),
                    const Spacer(),
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: _text(
                        13,
                        weight: FontWeight.w600,
                        height: 1.2,
                        letterSpacing: -0.2,
                      ),
                    ),
                    if (item.detail != null) ...[
                      const SizedBox(height: 2),
                      item.detail!,
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
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
          style: _text(13, weight: FontWeight.w600, color: _muted),
        );
      },
    );
  }

  /// Everything after the money group, as a quiet list.
  List<Widget> _list(List<List<_MenuItem>> groups) {
    return [
      for (var g = 0; g < groups.length; g++) ...[
        if (g > 0)
          const Padding(
            padding: EdgeInsets.fromLTRB(56, 8, 4, 8),
            child: Divider(height: 1, thickness: 1, color: _line),
          ),
        for (final item in groups[g]) _menuRow(item),
      ],
    ];
  }

  Widget _menuRow(_MenuItem item) {
    return Semantics(
      button: true,
      label: item.title,
      onTap: item.onTap,
      child: ExcludeSemantics(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: item.onTap,
            borderRadius: BorderRadius.circular(14),
            splashColor: _ink.withValues(alpha: 0.05),
            highlightColor: _ink.withValues(alpha: 0.04),
            child: SizedBox(
              height: 60,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Row(
                  children: [
                    _badge(item.icon, fill: _card),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _text(16, weight: FontWeight.w500),
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 22,
                      color: _chevron,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
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
