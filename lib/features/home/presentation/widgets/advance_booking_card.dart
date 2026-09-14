import 'package:flutter/material.dart';
import 'package:movera_rider/core/constants/appcolors.dart';
import 'package:movera_rider/core/constants/appfontweight.dart';
import 'package:movera_rider/shared/widgets/custom_text_widget.dart';
import 'package:movera_rider/shared/widgets/responsive_size.dart';
import 'package:movera_rider/shared/widgets/sizedbox_extention.dart';

/// The "Plan ahead. Ride on time." schedule-a-ride promo card.
class AdvanceBookingCard extends StatelessWidget {
  const AdvanceBookingCard({super.key, required this.onOpenSchedule});

  static const Color _premiumInk = Color(0xFF1D252C);
  static const Color _premiumMuted = Color(0xFF778189);
  static const Color _premiumLine = Color(0xFFE7EBEE);
  static const Color _premiumAccent = Color(0xFF2D5878);

  final VoidCallback onOpenSchedule;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onOpenSchedule,
      borderRadius: BorderRadius.circular(26),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(
          ResSize.w * 12,
          ResSize.h * 12,
          ResSize.w * 12,
          ResSize.h * 15,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFA),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: _premiumLine, width: 0.8),
          boxShadow: [
            BoxShadow(
              color: _premiumAccent.withValues(alpha: 0.06),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: SizedBox(
                width: double.infinity,
                height: ResSize.h * 142,
                child: Image.asset(
                  'assets/images/advance_booking_driver.png',
                  fit: BoxFit.cover,
                  alignment: const Alignment(0, -0.28),
                  filterQuality: FilterQuality.high,
                ),
              ),
            ),
            15.height,
            TextWidget(
              text: 'Plan ahead. Ride on time.',
              color: _premiumInk,
              fontSize: 17,
              fontWeight: fwBold,
            ),
            7.height,
            Padding(
              padding: EdgeInsets.symmetric(horizontal: ResSize.w * 8),
              child: TextWidget(
                text:
                    'Book your ride in advance and we’ll help arrange a driver for the time you choose.',
                color: _premiumMuted,
                fontSize: 11.5,
                fontWeight: fwNormal,
                textAlign: TextAlign.center,
              ),
            ),
            14.height,
            Container(
              height: ResSize.h * 42,
              width: double.infinity,
              decoration: BoxDecoration(
                color: _premiumAccent,
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: TextWidget(
                text: 'Schedule a ride',
                color: AppColor.white,
                fontSize: 12.5,
                fontWeight: fwSemiBold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
