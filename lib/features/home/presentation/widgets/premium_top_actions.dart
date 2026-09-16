import 'package:flutter/material.dart';
import 'package:movera_rider/core/constants/appcolors.dart';
import 'package:movera_rider/shared/design_system/movera_icon_button.dart';
import 'package:movera_rider/shared/widgets/responsive_size.dart';

/// The menu/account pill in Home's top-right corner.
class PremiumTopActions extends StatelessWidget {
  const PremiumTopActions({
    super.key,
    required this.onMenuTap,
    required this.onAccountTap,
  });

  static const Color _premiumLine = Color(0xFFE7EBEE);

  final VoidCallback onMenuTap;
  final VoidCallback onAccountTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MoveraIconButton.minTap + 8,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColor.white.withValues(alpha: 0.99),
            const Color(0xFFF8FAFA).withValues(alpha: 0.98),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _premiumLine, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF162C36).withValues(alpha: 0.13),
            blurRadius: 22,
            offset: const Offset(0, 7),
          ),
          BoxShadow(
            color: AppColor.white.withValues(alpha: 0.88),
            blurRadius: 2,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PremiumTopAction(
            icon: Icons.menu_open_rounded,
            semanticLabel: 'Menu',
            onTap: onMenuTap,
          ),
          Container(height: ResSize.h * 23, width: 0.8, color: _premiumLine),
          _PremiumTopAction(
            icon: Icons.person_rounded,
            semanticLabel: 'Account',
            onTap: onAccountTap,
          ),
        ],
      ),
    );
  }
}

class _PremiumTopAction extends StatelessWidget {
  const _PremiumTopAction({
    required this.icon,
    required this.semanticLabel,
    required this.onTap,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(19),
          child: SizedBox(
            height: MoveraIconButton.minTap,
            width: MoveraIconButton.minTap,
            child: ExcludeSemantics(
              child: Icon(icon, size: 24, color: const Color(0xFF11181D)),
            ),
          ),
        ),
      ),
    );
  }
}
