import 'package:flutter/material.dart';
import 'package:movera_rider/core/constants/appassets.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movera_rider/features/promotions/application/rider_promotion_controller.dart';
import 'package:movera_rider/shared/design_system/movera_sheet.dart';
import 'package:movera_rider/shared/formatters/money.dart';

/// Rides left, end date and rules of the rider's promotion.
class PromotionDetailsSheet extends StatelessWidget {
  const PromotionDetailsSheet({super.key, required this.promotion});

  static const Color _ink = Color(0xFF1D252C);
  static const Color _muted = Color(0xFF5C656C);
  static const Color _line = Color(0xFFE7EBEE);
  static const Color _accent = Color(0xFF2D5878);

  final RiderPromotion promotion;

  static Future<void> open(BuildContext context, RiderPromotion promotion) {
    return MoveraSheet.show<void>(
      context: context,
      builder: (_) => PromotionDetailsSheet(promotion: promotion),
    );
  }

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  TextStyle _t(double size, {FontWeight w = FontWeight.w500, Color c = _ink}) =>
      GoogleFonts.poppins(fontSize: size, fontWeight: w, color: c);

  @override
  Widget build(BuildContext context) {
    final ends = promotion.endsAt;
    final used = (promotion.ridesTotal - promotion.ridesLeft).clamp(0, 999);
    final rows = <(String, String)>[
      ('Discount', '${promotion.percentOff}% off'),
      ('Rides left', '${promotion.ridesLeft} of ${promotion.ridesTotal}'),
      if (ends != null)
        ('Ends', '${ends.day} ${_months[ends.month - 1]} ${ends.year}'),
      if (promotion.maxDiscountMinor != null)
        ('Max per ride', formatSek(promotion.maxDiscountMinor!)),
    ];
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: _line,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Center(
              child: Image.asset(
                AppAssets.promoCard,
                height: 70,
                excludeFromSemantics: true,
              ),
            ),
            const SizedBox(height: 10),
            Text(promotion.title, style: _t(20, w: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(
              'Applied automatically to your next rides.',
              style: _t(13, c: _muted),
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: promotion.ridesTotal == 0
                    ? 0
                    : used / promotion.ridesTotal,
                minHeight: 6,
                backgroundColor: const Color(0xFFEAF2F8),
                color: _accent,
              ),
            ),
            const SizedBox(height: 14),
            for (final (label, value) in rows)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: _line)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(label, style: _t(14, c: _muted)),
                    ),
                    Text(value, style: _t(14, w: FontWeight.w600)),
                  ],
                ),
              ),
            if (promotion.rules.isNotEmpty) ...[
              const SizedBox(height: 12),
              for (final rule in promotion.rules)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('• $rule', style: _t(12.5, c: _muted)),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
