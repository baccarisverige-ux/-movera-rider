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

  static const Color _ink = Color(0xFF1C2329);
  static const Color _muted = Color(0xFF7A858E);
  static const Color _accent = Color(0xFF2D5878);
  static const Color _icon = Color(0xFF2F3A44);
  static const Color _line = Color(0xFFEDF0F2);
  static const Color _avatarTint = Color(0xFFE8EEF2);

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
    return Drawer(
      backgroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      width: media.size.width * 0.86,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(28),
          bottomRight: Radius.circular(28),
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
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _profileHeader(),
                      const SizedBox(height: 22),
                      const Divider(height: 1, thickness: 1, color: _line),
                      const SizedBox(height: 12),
                      ..._menuGroups(context),
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

  /// Avatar above the name, with room for a long greeting.
  Widget _profileHeader() {
    final controller = AppScope.instance.profile;
    final profile = controller.profile;
    final hasPhoto = profile.photoAsset.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                      child: Icon(
                        Icons.person_rounded,
                        color: _muted,
                        size: 34,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            controller.displayName(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: _text(
              24,
              weight: FontWeight.w700,
              height: 1.15,
              letterSpacing: -0.4,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _menuGroups(BuildContext context) {
    final groups = <List<_MenuItem>>[
      [
        _MenuItem(
          icon: Icons.account_balance_wallet_outlined,
          title: 'Wallet',
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
          onTap: () => _pushPage(
            context,
            const WalletAndPaymentsScreen(initialTab: 1),
          ),
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
          image: AppAssets.safetyShield,
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

    return [
      for (var g = 0; g < groups.length; g++) ...[
        if (g > 0)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
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
            borderRadius: BorderRadius.circular(16),
            splashColor: _accent.withValues(alpha: 0.06),
            highlightColor: _accent.withValues(alpha: 0.04),
            child: SizedBox(
              height: 58,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 28,
                      height: 28,
                      child: item.image != null
                          ? Image.asset(
                              excludeFromSemantics: true,
                              item.image!,
                              fit: BoxFit.contain,
                            )
                          : Icon(item.icon, size: 25, color: _icon),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _text(17, weight: FontWeight.w500),
                      ),
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
          ),
          const SizedBox(width: 8),
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
    this.icon,
    this.image,
    required this.title,
    required this.onTap,
  });

  final IconData? icon;
  final String? image;
  final String title;
  final VoidCallback onTap;
}
