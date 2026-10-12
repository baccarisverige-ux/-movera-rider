import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movera_rider/app/di.dart';
import 'package:movera_rider/features/promotions/application/promotions_controller.dart';
import 'package:movera_rider/features/promotions/data/promotions_repository.dart';
import 'package:movera_rider/features/promotions/domain/promotion.dart';
import 'package:movera_rider/shared/design_system/movera_sheet.dart';
import 'package:movera_rider/shared/design_system/movera_toast.dart';
import 'package:movera_rider/shared/design_system/tokens.dart';

/// Lets the rider type a voucher code. Returns the promotion when one was unlocked.
Future<Promotion?> showVoucherCodeSheet(
  BuildContext context, {
  String? initialCode,
  PromotionsController? controller,
}) {
  return MoveraSheet.show<Promotion>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.28),
    builder: (sheetContext) => VoucherCodeSheet(
      initialCode: initialCode,
      controller: controller,
    ),
  );
}

class VoucherCodeSheet extends StatefulWidget {
  const VoucherCodeSheet({super.key, this.initialCode, this.controller});

  final String? initialCode;
  final PromotionsController? controller;

  @override
  State<VoucherCodeSheet> createState() => _VoucherCodeSheetState();
}

class _VoucherCodeSheetState extends State<VoucherCodeSheet> {
  late final TextEditingController _code =
      TextEditingController(text: widget.initialCode ?? '');
  late final PromotionsController _promotions =
      widget.controller ?? AppScope.instance.promotions;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  TextStyle _style(double size, {FontWeight weight = FontWeight.w500, Color color = MoveraTokens.ink, double? height}) =>
      GoogleFonts.poppins(fontSize: size, fontWeight: weight, color: color, height: height);

  Future<void> _submit() async {
    final code = normalizePromoCode(_code.text);
    if (code.isEmpty) {
      setState(() => _error = 'Type the code from your voucher.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final promotion = await _promotions.redeem(code);
      if (!mounted) return;
      MoveraToast.show(context, '${promotion.title} added: ${promotion.label}.');
      Navigator.of(context).pop(promotion);
    } on RedeemException catch (fault) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = fault.failure.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = RedeemFailure.offline.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(MoveraTokens.radiusSheet),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.confirmation_number_outlined, color: MoveraTokens.ink, size: 34),
            const SizedBox(height: 14),
            Text('Add a voucher code', textAlign: TextAlign.center, style: _style(18, weight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(
              'Type the code from a flyer, a message or a friend. The discount is taken off your next rides.',
              textAlign: TextAlign.center,
              style: _style(12, color: MoveraTokens.muted, height: 1.45),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _code,
              autofocus: widget.initialCode == null || widget.initialCode!.isEmpty,
              enabled: !_busy,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                LengthLimitingTextInputFormatter(16),
              ],
              textAlign: TextAlign.center,
              style: _style(20, weight: FontWeight.w700).copyWith(letterSpacing: 2),
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                hintText: 'CODE',
                hintStyle: _style(20, weight: FontWeight.w700, color: MoveraTokens.line).copyWith(letterSpacing: 2),
                filled: true,
                fillColor: MoveraTokens.bg,
                errorText: _error,
                errorStyle: _style(12, color: const Color(0xFFB3261E)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: MoveraTokens.line),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: _busy ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: MoveraTokens.cta,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _busy
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text('Use code', style: _style(14, weight: FontWeight.w700, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
