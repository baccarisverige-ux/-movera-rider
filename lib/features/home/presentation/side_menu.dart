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
  static const Color _panel = Color(0xFF11181D);
  static const Color _line = Color(0xFFEEF1F4);
  static const Color _chevron = Color(0xFFB8C0C7);
  static const Color _blue = Color(0xFF1A73E8);
  static const Color _blueTint = Color(0xFFE8F0FC);
  static const Color _green = Color(0xFF1E9E5A);
  static const Color _greenTint = Color(0xFFE6F5EC);
  static const Color _slate = Color(0xFF4A555E);
  static const Color _slateTint = Color(0xFFEEF1F4);

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
      backgroundColor: _panel,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      width: media.size.width * 0.86,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: ColoredBox(
        color: _panel,
        child: SafeArea(
          bottom: false,
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
                      _menuCard(context),
                    ],
                  ),
                ),
              ),
              _footer(context),
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

  /// Ringed avatar and the rider's name in white on the dark panel.
  Widget _profileHeader() {
    final controller = AppScope.instance.profile;
    final profile = controller.profile;
    final hasPhoto = profile.photoAsset.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.28),
                width: 1.5,
              ),
            ),
            child: ClipOval(
              child: hasPhoto
                  ? Image.asset(
                      excludeFromSemantics: true,
                      profile.photoAsset,
                      fit: BoxFit.cover,
                    )
                  : ColoredBox(
                      color: Colors.white.withValues(alpha: 0.12),
                      child: const Icon(
                        Icons.person_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              controller.displayName(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: _text(
                21,
                weight: FontWeight.w700,
                color: Colors.white,
                height: 1.15,
                letterSpacing: -0.3,
              ),
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
          trailing: _walletBalance(),
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
          icon: Icons.notifications_outlined,
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

    return [
      for (var g = 0; g < groups.length; g++) ...[
        if (g > 0)
          const Padding(
            padding: EdgeInsets.only(left: 76, right: 20),
            child: Divider(height: 1, thickness: 1, color: _line),
          ),
        for (final item in groups[g]) _menuRow(item, _tints[g]),
      ],
    ];
  }

  /// Icon colours by group: money in brand blue, places in brand green,
  /// help in slate.
  static const _tints = <(Color, Color)>[
    (_blue, _blueTint),
    (_green, _greenTint),
    (_slate, _slateTint),
  ];

  Widget _menuCard(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(28),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: _menuGroups(context),
        ),
      ),
    );
  }

  Widget _menuIcon(_MenuItem item, (Color, Color) tint) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(color: tint.$2, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Icon(item.icon, size: 22, color: tint.$1),
    );
  }

  /// The wallet row shows the balance on the right, like a receipt line.
  Widget _walletBalance() {
    return FutureBuilder<double>(
      future: AppScope.instance.walletController.loadBalance(),
      builder: (context, snapshot) {
        final balance = snapshot.data;
        if (balance == null) return const SizedBox.shrink();
        return Text(
          'kr ${balance.toStringAsFixed(0)}',
          style: _text(16, weight: FontWeight.w700),
        );
      },
    );
  }

  Widget _menuRow(_MenuItem item, (Color, Color) tint) {
    return Semantics(
      button: true,
      label: item.title,
      onTap: item.onTap,
      child: ExcludeSemantics(
        child: InkWell(
          onTap: item.onTap,
          splashColor: _ink.withValues(alpha: 0.05),
          highlightColor: _ink.withValues(alpha: 0.04),
          child: SizedBox(
            height: 62,
            child: Padding(
              padding: const EdgeInsets.only(left: 16, right: 14),
              child: Row(
                children: [
                  _menuIcon(item, tint),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _text(16, weight: FontWeight.w600),
                    ),
                  ),
                  if (item.trailing != null) ...[
                    item.trailing!,
                    const SizedBox(width: 6),
                  ],
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
    );
  }

  Widget _footer(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 8, 24, 20 + bottom),
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
              style: _text(
                12,
                color: Colors.white.withValues(alpha: 0.6),
              ),
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
    this.trailing,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Widget? trailing;
}
