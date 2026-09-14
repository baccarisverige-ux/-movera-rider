import 'package:flutter/material.dart';
import 'package:movera_rider/core/constants/appcolors.dart';
import 'package:movera_rider/core/constants/appfontweight.dart';
import 'package:movera_rider/shared/widgets/custom_text_widget.dart';
import 'package:movera_rider/shared/widgets/responsive_size.dart';
import 'package:movera_rider/shared/widgets/sizedbox_extention.dart';

/// The dismissible promotion ticket above Home's "Where to?" card.
class RidePromotionTicket extends StatelessWidget {
  const RidePromotionTicket({
    super.key,
    required this.title,
    required this.onTap,
    required this.onDismiss,
  });

  static const Color _premiumInk = Color(0xFF1D252C);
  static const Color _premiumMuted = Color(0xFF778189);
  static const Color _premiumLine = Color(0xFFE7EBEE);

  final String title;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: title,
      child: Container(
        height: ResSize.h * 48,
        decoration: BoxDecoration(
          color: AppColor.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0xFFDDE2E4), width: 0.9),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF142D39).withValues(alpha: 0.09),
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
                  onTap: onTap,
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(15),
                  ),
                  child: Padding(
                    padding: EdgeInsets.only(left: ResSize.w * 11),
                    child: Row(
                      children: [
                        Container(
                          width: ResSize.w * 45,
                          height: ResSize.h * 34,
                          alignment: Alignment.center,
                          child: Image.asset(
                            'assets/images/promo_card_img.png',
                            width: ResSize.w * 43,
                            height: ResSize.h * 31,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.high,
                          ),
                        ),
                        8.width,
                        Expanded(
                          child: TextWidget(
                            text: title,
                            color: _premiumInk,
                            fontSize: 12.2,
                            fontWeight: fwSemiBold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Container(width: 0.8, height: ResSize.h * 24, color: _premiumLine),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onDismiss,
                borderRadius: const BorderRadius.horizontal(
                  right: Radius.circular(15),
                ),
                child: SizedBox(
                  width: ResSize.w * 45,
                  height: double.infinity,
                  child: Icon(
                    Icons.close_rounded,
                    size: ResSize.h * 20,
                    color: _premiumMuted,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
