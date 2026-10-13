import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movera_rider/features/active_ride/application/route_change_controller.dart';
import 'package:movera_rider/shared/design_system/movera_sheet.dart';

/// True for "Pay in car": the price is only shown, nothing is charged now.
bool isCashPayment(String paymentMethod) {
  final m = paymentMethod.trim().toLowerCase();
  return m == 'cash' || m.contains('pay in car');
}

/// "New route, new price": the rider confirms a priced route change. For a
/// card, Apple Pay or wallet a second step confirms the payment update.
/// Resolves true when confirmed.
class RouteChangeSheet extends StatefulWidget {
  const RouteChangeSheet({super.key, required this.quote, required this.paymentMethod});

  final RouteChangeQuote quote;
  final String paymentMethod;

  static Future<bool> confirm(
    BuildContext context, {
    required RouteChangeQuote quote,
    required String paymentMethod,
  }) async {
    final result = await MoveraSheet.show<bool>(
      context: context,
      builder: (_) => RouteChangeSheet(quote: quote, paymentMethod: paymentMethod),
    );
    return result == true;
  }

  @override
  State<RouteChangeSheet> createState() => _RouteChangeSheetState();
}

class _RouteChangeSheetState extends State<RouteChangeSheet> {
  static const Color _ink = Color(0xFF1D252C);
  static const Color _muted = Color(0xFF5C656C);
  static const Color _accent = Color(0xFF2D5878);

  bool _paymentStep = false;

  RouteChangeQuote get quote => widget.quote;
  String get paymentMethod => widget.paymentMethod;
  bool get _cash => isCashPayment(paymentMethod);
  double get _diff => quote.differenceKr;

  String _kr(double value) => '${value.round()} kr';

  void _confirmRoute() {
    if (_cash || _diff.abs() < 0.5) {
      Navigator.pop(context, true);
      return;
    }
    setState(() => _paymentStep = true);
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + inset),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: _paymentStep ? _payment(context) : _route(context),
      ),
    );
  }

  Widget _route(BuildContext context) {
    final diff = _diff;
    final String priceNote;
    if (diff.abs() < 0.5) {
      priceNote = 'Same price as before.';
    } else if (_cash) {
      priceNote = diff > 0
          ? '+${_kr(diff)} more. You pay the new price in the car.'
          : '${_kr(-diff)} less. You pay the new price in the car.';
    } else if (diff > 0) {
      priceNote = '+${_kr(diff)} more, charged to $paymentMethod.';
    } else {
      priceNote = '${_kr(-diff)} less, returned to $paymentMethod.';
    }
    return Column(
      key: const ValueKey('route-change-step-route'),
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'New route',
          style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: _ink),
        ),
        const SizedBox(height: 14),
        _row(Icons.radio_button_checked, const Color(0xFF079A60), quote.pickupAddress),
        for (var i = 0; i < quote.stops.length; i++)
          _row(Icons.circle_outlined, _ink, quote.stops[i].address, label: 'Stop ${i + 1}'),
        _row(Icons.square, const Color(0xFF1769E8), quote.destinationAddress),
        const SizedBox(height: 16),
        Container(
          key: const ValueKey('route-change-price'),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F6FB),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'New price',
                      style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: _muted),
                    ),
                    const SizedBox(height: 2),
                    Text(priceNote, style: GoogleFonts.poppins(fontSize: 12.5, color: _muted)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _kr(quote.newPriceKr),
                    style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: _ink),
                  ),
                  if (diff.abs() >= 0.5)
                    Text(
                      _kr(quote.oldPriceKr),
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: _muted,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _primary(
          key: const ValueKey('route-change-confirm'),
          label: _cash || diff.abs() < 0.5 ? 'Confirm change' : 'Confirm · next: payment',
          onPressed: _confirmRoute,
        ),
        const SizedBox(height: 8),
        _secondary('Keep current route', () => Navigator.pop(context, false)),
      ],
    );
  }

  Widget _payment(BuildContext context) {
    final diff = _diff;
    final more = diff > 0;
    return Column(
      key: const ValueKey('route-change-step-payment'),
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Update payment',
          style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: _ink),
        ),
        const SizedBox(height: 6),
        Text(
          more
              ? 'The difference is charged now to your payment method.'
              : 'The difference goes back to your payment method.',
          style: GoogleFonts.poppins(fontSize: 13.5, color: _muted),
        ),
        const SizedBox(height: 16),
        Container(
          key: const ValueKey('route-change-payment'),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F6FB),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              _kv('Payment method', paymentMethod),
              const SizedBox(height: 8),
              _kv('Booked price', _kr(quote.oldPriceKr)),
              const SizedBox(height: 8),
              _kv('New price', _kr(quote.newPriceKr)),
              const Divider(height: 20),
              _kv(
                more ? 'Charged now' : 'Returned to you',
                '${more ? '+' : '−'}${_kr(diff.abs())}',
                bold: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _primary(
          key: const ValueKey('route-change-pay'),
          label: more ? 'Confirm and pay ${_kr(diff)}' : 'Confirm refund',
          onPressed: () => Navigator.pop(context, true),
        ),
        const SizedBox(height: 8),
        _secondary('Back', () => setState(() => _paymentStep = false)),
      ],
    );
  }

  Widget _primary({required Key key, required String label, required VoidCallback onPressed}) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton(
        key: key,
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF11181D),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.white),
        ),
      ),
    );
  }

  Widget _secondary(String label, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(foregroundColor: _accent),
        child: Text(label, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15)),
      ),
    );
  }

  Widget _kv(String left, String right, {bool bold = false}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            left,
            style: GoogleFonts.poppins(fontSize: 14, color: bold ? _ink : _muted, fontWeight: bold ? FontWeight.w600 : FontWeight.w500),
          ),
        ),
        Text(
          right,
          style: GoogleFonts.poppins(fontSize: bold ? 16 : 14, fontWeight: bold ? FontWeight.w700 : FontWeight.w600, color: _ink),
        ),
      ],
    );
  }

  Widget _row(IconData icon, Color color, String address, {String? label}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(width: 22, child: Icon(icon, size: 16, color: color)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (label != null)
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: _muted,
                    ),
                  ),
                Text(
                  address,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _ink,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
