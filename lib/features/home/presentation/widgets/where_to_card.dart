import 'package:flutter/material.dart';
import 'package:movera_rider/core/constants/appassets.dart';
import 'package:movera_rider/core/constants/appcolors.dart';
import 'package:movera_rider/core/constants/appfontweight.dart';
import 'package:movera_rider/features/home/presentation/widgets/short_address.dart';
import 'package:movera_rider/shared/widgets/custom_text_widget.dart';
import 'package:movera_rider/shared/widgets/responsive_size.dart';
import 'package:movera_rider/shared/widgets/sizedbox_extention.dart';

/// The "Where to? / Later" card on Home's collapsed sheet.
class WhereToCard extends StatelessWidget {
  const WhereToCard({
    super.key,
    required this.destinationAddress,
    required this.onDestinationTap,
    required this.onOpenSchedule,
  });

  static const Color _premiumInk = Color(0xFF1D252C);
  static const Color _premiumLine = Color(0xFFE7EBEE);

  final String? destinationAddress;
  final VoidCallback onDestinationTap;
  final VoidCallback onOpenSchedule;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: ResSize.h * 58,
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(ResSize.w * 4, 0, ResSize.w * 7, 0),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9F9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8EDEF), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF173B4D).withValues(alpha: 0.035),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onDestinationTap,
                borderRadius: BorderRadius.circular(18),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: ResSize.w * 13),
                  child: Row(
                    children: [
                      Icon(
                        Icons.search_rounded,
                        size: ResSize.h * 26,
                        color: _premiumInk,
                      ),
                      12.width,
                      Expanded(
                        child: TextWidget(
                          text: destinationAddress == null
                              ? 'Where to?'
                              : shortAddress(destinationAddress, maxLength: 28),
                          color: _premiumInk.withValues(alpha: 0.72),
                          fontSize: destinationAddress == null ? 16.5 : 12.5,
                          fontWeight: fwMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onOpenSchedule,
              borderRadius: BorderRadius.circular(18),
              child: Container(
                height: ResSize.h * 28.4,
                padding: EdgeInsets.symmetric(horizontal: ResSize.w * 8),
                decoration: BoxDecoration(
                  color: AppColor.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _premiumLine, width: 0.8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.045),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      AppAssets.navSchedule,
                      height: ResSize.h * 20.4,
                      width: ResSize.w * 20.4,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                    ),
                    4.width,
                    TextWidget(
                      text: 'Later',
                      color: _premiumInk,
                      fontSize: 9.2,
                      fontWeight: fwSemiBold,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
