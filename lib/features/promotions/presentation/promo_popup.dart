import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movera_rider/features/promotions/domain/promotion.dart';
import 'package:movera_rider/shared/design_system/movera_sheet.dart';
import 'package:movera_rider/shared/design_system/tokens.dart';

/// The promotion Movera wants shown once when the app opens.
/// Returns true when the rider tapped "Use it now".
Future<bool> showPromoPopup(BuildContext context, Promotion promotion) async {
  final used = await MoveraSheet.show<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.32),
    builder: (sheetContext) => PromoPopup(promotion: promotion),
  );
  return used ?? false;
}

class PromoPopup extends StatelessWidget {
  const PromoPopup({super.key, required this.promotion});

  final Promotion promotion;

  TextStyle _style(double size, {FontWeight weight = FontWeight.w500, Color color = MoveraTokens.ink, double? height}) =>
      GoogleFonts.poppins(fontSize: size, fontWeight: weight, color: color, height: height);

  @override
  Widget build(BuildContext context) {
    final until = promotion.validTo;
    final untilText = '${until.day}/${until.month}';
    return SafeArea(
      top: false,
      child: Semantics(
        container: true,
        label: 'Promotion ${promotion.title}',
        child: Container(
          margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(MoveraTokens.radiusSheet),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Stack(
                children: [
                  Container(
                    height: 150,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF2D5878), Color(0xFF7FB2D8)],
                      ),
                    ),
                    child: Center(
                      child: Text(
                        promotion.label,
                        textAlign: TextAlign.center,
                        style: _style(30, weight: FontWeight.w800, color: Colors.white),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.of(context).pop(false),
                      icon: const Icon(Icons.close_rounded, color: Colors.white),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(promotion.title, textAlign: TextAlign.center, style: _style(20, weight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Text(
                      promotion.message ??
                          '${promotion.label} on your next ${promotion.ridesLeft} ride${promotion.ridesLeft == 1 ? '' : 's'}. Valid until $untilText.',
                      textAlign: TextAlign.center,
                      style: _style(13, color: MoveraTokens.muted, height: 1.45),
                    ),
                    if (promotion.code.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: MoveraTokens.bg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: MoveraTokens.line),
                        ),
                        child: Text(
                          promotion.code,
                          textAlign: TextAlign.center,
                          style: _style(16, weight: FontWeight.w700).copyWith(letterSpacing: 2),
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    SizedBox(
                      height: 52,
                      child: FilledButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: FilledButton.styleFrom(
                          backgroundColor: MoveraTokens.cta,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Text('Use it now', style: _style(14, weight: FontWeight.w700, color: Colors.white)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text('Maybe later', style: _style(13, color: MoveraTokens.muted)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
