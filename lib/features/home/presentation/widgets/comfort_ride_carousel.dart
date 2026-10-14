import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movera_rider/core/constants/appcolors.dart';
import 'package:movera_rider/core/constants/appfontweight.dart';
import 'package:movera_rider/features/safety/presentation/safety_hub.dart';
import 'package:movera_rider/shared/widgets/navigation_transition.dart';
import 'package:movera_rider/shared/widgets/responsive_size.dart';
import 'package:movera_rider/shared/widgets/sizedbox_extention.dart';

/// The horizontally-scrolling "Movera Comfort / Safety Toolkit / ..." promo
/// carousel on Home's collapsed sheet.
class ComfortRideCarousel extends StatelessWidget {
  const ComfortRideCarousel({
    super.key,
    required this.onDestinationTap,
    required this.onOpenSchedule,
  });

  final VoidCallback onDestinationTap;
  final VoidCallback onOpenSchedule;

  @override
  Widget build(BuildContext context) {
    final viewportWidth = MediaQuery.of(context).size.width;
    final cardWidth = (viewportWidth * 0.62).clamp(220.0, 270.0).toDouble();
    // Text-only cards (the owner kept pictures for "Plan ahead" alone). Text
    // can wrap to two lines on compact/rescaled layouts: keep a safe band.
    final bandHeight = (ResSize.h * 78).clamp(88.0, 100.0).toDouble();

    return SizedBox(
      height: bandHeight + ResSize.h * 2,
      width: double.infinity,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.only(right: ResSize.w * 8),
        children: [
          _HomePromoCard(
            cardWidth: cardWidth,
            bandHeight: bandHeight,
            title: 'Movera Comfort',
            subtitle: 'Extra space. Elevated comfort. A smoother way to ride.',
            onTap: onDestinationTap,
          ),
          SizedBox(width: ResSize.w * 12),
          _HomePromoCard(
            cardWidth: cardWidth,
            bandHeight: bandHeight,
            title: 'Safety Toolkit',
            subtitle: 'Essential safety tools, ready throughout every ride.',
            onTap: () {
              Navigator.push(context, RightToLeftTransition(const SafetyHub()));
            },
          ),
          SizedBox(width: ResSize.w * 12),
          _HomePromoCard(
            cardWidth: cardWidth,
            bandHeight: bandHeight,
            title: 'Fly with ease',
            subtitle:
                'Reserve your airport ride ahead and travel with less stress.',
            onTap: onOpenSchedule,
          ),
          SizedBox(width: ResSize.w * 12),
          _HomePromoCard(
            cardWidth: cardWidth,
            bandHeight: bandHeight,
            title: 'Reserve for events',
            subtitle:
                'Plan your ride early and arrive exactly when you need to.',
            onTap: onOpenSchedule,
          ),
          SizedBox(width: ResSize.w * 12),
          _HomePromoCard(
            cardWidth: cardWidth,
            bandHeight: bandHeight,
            title: 'Reserve work rides',
            subtitle:
                'Reliable scheduled rides for meetings and important workdays.',
            onTap: onOpenSchedule,
          ),
          SizedBox(width: ResSize.w * 12),
          _HomePromoCard(
            cardWidth: cardWidth,
            bandHeight: bandHeight,
            title: 'Plan for outings',
            subtitle:
                'Book ahead for dinners, appointments and plans around town.',
            onTap: onOpenSchedule,
          ),
          SizedBox(width: ResSize.w * 18),
        ],
      ),
    );
  }
}

class _HomePromoCard extends StatelessWidget {
  const _HomePromoCard({
    required this.cardWidth,
    required this.bandHeight,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  static const Color _premiumInk = Color(0xFF1D252C);
  static const Color _premiumMuted = Color(0xFF5C656C);
  static const Color _premiumLine = Color(0xFFE7EBEE);

  final double cardWidth;
  final double bandHeight;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: cardWidth,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: AppColor.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: _premiumLine, width: 0.8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.055),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  height: bandHeight,
                  color: AppColor.white,
                  padding: EdgeInsets.fromLTRB(
                    ResSize.w * 14,
                    ResSize.h * 10,
                    ResSize.w * 14,
                    ResSize.h * 10,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          color: _premiumInk,
                          fontSize: ResSize.setSp(14),
                          fontWeight: fwBold,
                        ),
                      ),
                      3.height,
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          color: _premiumMuted,
                          fontSize: ResSize.setSp(10),
                          fontWeight: fwNormal,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
