import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movera_rider/app/di.dart';
import 'package:movera_rider/features/promotions/application/promotions_controller.dart';
import 'package:movera_rider/features/promotions/domain/promotion.dart';
import 'package:movera_rider/features/promotions/presentation/voucher_code_sheet.dart';
import 'package:movera_rider/shared/design_system/movera_empty_state.dart';
import 'package:movera_rider/shared/design_system/tokens.dart';

/// Every promotion the rider has, with a way to add a code.
class OffersScreen extends StatefulWidget {
  const OffersScreen({super.key, this.controller});

  final PromotionsController? controller;

  @override
  State<OffersScreen> createState() => _OffersScreenState();
}

class _OffersScreenState extends State<OffersScreen> {
  late final PromotionsController _promotions =
      widget.controller ?? AppScope.instance.promotions;

  @override
  void initState() {
    super.initState();
    _promotions.addListener(_changed);
    _promotions.load();
  }

  @override
  void dispose() {
    _promotions.removeListener(_changed);
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  TextStyle _style(double size, {FontWeight weight = FontWeight.w500, Color color = MoveraTokens.ink, double? height}) =>
      GoogleFonts.poppins(fontSize: size, fontWeight: weight, color: color, height: height);

  @override
  Widget build(BuildContext context) {
    final live = _promotions.live;
    final past = _promotions.past;
    return Scaffold(
      backgroundColor: MoveraTokens.bg,
      appBar: AppBar(
        backgroundColor: MoveraTokens.bg,
        elevation: 0,
        foregroundColor: MoveraTokens.ink,
        title: Text('Offers & vouchers', style: _style(18, weight: FontWeight.w700)),
      ),
      body: RefreshIndicator(
        onRefresh: _promotions.load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            _AddCodeTile(onTap: () => showVoucherCodeSheet(context, controller: _promotions)),
            if (_promotions.error != null && live.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  'Movera could not refresh your offers. Showing what the phone remembers.',
                  style: _style(12, color: MoveraTokens.muted),
                ),
              ),
            const SizedBox(height: 18),
            if (live.isEmpty && !_promotions.loading)
              const MoveraEmptyState(
                icon: Icons.local_offer_outlined,
                title: 'No offers right now',
                message: 'When Movera gives you a promotion, or you add a code, it shows here and is taken off your next rides.',
                compact: true,
              )
            else ...[
              Text('READY TO USE', style: _style(10, weight: FontWeight.w600, color: MoveraTokens.muted).copyWith(letterSpacing: 1.25)),
              const SizedBox(height: 10),
              for (final item in live) ...[
                _PromotionCard(promotion: item, live: true),
                const SizedBox(height: 10),
              ],
            ],
            if (past.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text('ENDED', style: _style(10, weight: FontWeight.w600, color: MoveraTokens.muted).copyWith(letterSpacing: 1.25)),
              const SizedBox(height: 10),
              for (final item in past) ...[
                _PromotionCard(promotion: item, live: false),
                const SizedBox(height: 10),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _AddCodeTile extends StatelessWidget {
  const _AddCodeTile({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              const Icon(Icons.confirmation_number_outlined, color: MoveraTokens.ink),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Add a voucher code',
                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: MoveraTokens.ink),
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: MoveraTokens.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _PromotionCard extends StatelessWidget {
  const _PromotionCard({required this.promotion, required this.live});
  final Promotion promotion;
  final bool live;

  @override
  Widget build(BuildContext context) {
    final ink = live ? MoveraTokens.ink : MoveraTokens.muted;
    final until = promotion.validTo;
    return Semantics(
      label: '${promotion.title}, ${promotion.label}',
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: MoveraTokens.line),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: live
                    ? const LinearGradient(colors: [Color(0xFF2D5878), Color(0xFF7FB2D8)])
                    : null,
                color: live ? null : MoveraTokens.bg,
              ),
              child: Icon(Icons.local_offer_outlined, color: live ? Colors.white : MoveraTokens.muted, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(promotion.title, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: ink)),
                  const SizedBox(height: 2),
                  Text(promotion.label, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: live ? MoveraTokens.accent : MoveraTokens.muted)),
                  const SizedBox(height: 4),
                  Text(
                    live
                        ? '${promotion.ridesLeft} ride${promotion.ridesLeft == 1 ? '' : 's'} left · until ${until.day}/${until.month} · ${promotion.code}'
                        : 'Ended ${until.day}/${until.month} · ${promotion.code}',
                    style: GoogleFonts.poppins(fontSize: 11.5, color: MoveraTokens.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
