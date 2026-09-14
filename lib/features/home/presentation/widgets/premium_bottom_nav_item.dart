import 'package:flutter/material.dart';
import 'package:movera_rider/core/constants/appfontweight.dart';
import 'package:movera_rider/shared/widgets/custom_text_widget.dart';
import 'package:movera_rider/shared/widgets/responsive_size.dart';
import 'package:movera_rider/shared/widgets/sizedbox_extention.dart';

/// One item in Home's bottom nav bar (Home / Wallet / Reservations / Account).
class PremiumBottomNavItem extends StatelessWidget {
  const PremiumBottomNavItem({
    super.key,
    required this.iconAsset,
    required this.label,
    required this.onTap,
    this.active = false,
    this.floatingFraction = 0,
  });

  static const Color _premiumInk = Color(0xFF1D252C);

  final String iconAsset;
  final String label;
  final VoidCallback onTap;
  final bool active;
  final double floatingFraction;

  @override
  Widget build(BuildContext context) {
    final activeColor = Color.lerp(
      const Color(0xFF2A7A84),
      _premiumInk,
      floatingFraction,
    )!;
    final color = active ? activeColor : const Color(0xFF899197);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          height: ResSize.h * 52,
          margin: EdgeInsets.symmetric(
            horizontal: ResSize.w * 2.5 * floatingFraction,
          ),
          decoration: BoxDecoration(
            color: active
                ? Color.lerp(
                    Colors.transparent,
                    const Color(0xFFF2F2F2),
                    floatingFraction,
                  )
                : Colors.transparent,
            borderRadius: BorderRadius.circular(
              24 * floatingFraction + 14 * (1 - floatingFraction),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: ResSize.h * 30,
                width: ResSize.w * 30,
                child: Center(
                  child: Opacity(
                    opacity: active ? 1 : 0.86,
                    child: Image.asset(
                      iconAsset,
                      height: ResSize.h * 18.68,
                      width: ResSize.w * 18.68,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                ),
              ),
              3.height,
              Padding(
                padding: EdgeInsets.symmetric(horizontal: ResSize.w * 2),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: TextWidget(
                    text: label,
                    color: color,
                    fontSize: 9.5,
                    fontWeight: active ? fwSemiBold : fwMedium,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
