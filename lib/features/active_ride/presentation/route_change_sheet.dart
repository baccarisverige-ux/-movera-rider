import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movera_rider/features/active_ride/application/route_change_controller.dart';
import 'package:movera_rider/shared/design_system/movera_sheet.dart';

/// True for "Pay in car": the price is only shown, nothing is charged now.
bool isCashPayment(String paymentMethod) {
  final m = paymentMethod.trim().toLowerCase();
  return m == 'cash' || m.contains('pay in car');
}

/// Where a refund goes when the new route is cheaper.
enum RefundDestination { wallet, originalMethod }

/// What the rider decided on the route change sheet.
class RouteChangeDecision {
  const RouteChangeDecision({required this.confirmed, this.refundTo});
  final bool confirmed;

  /// Set only for a confirmed refund on a non-cash method.
  final RefundDestination? refundTo;

  static const declined = RouteChangeDecision(confirmed: false);
}

/// "New route, new price": the rider confirms a priced route change. For a
/// card, Apple Pay or wallet a second step confirms the payment update; a
/// refund also asks where the money should go.
class RouteChangeSheet extends StatefulWidget {
  const RouteChangeSheet({super.key, required this.quote, required this.paymentMethod});

  final RouteChangeQuote quote;
  final String paymentMethod;

  static Future<RouteChangeDecision> confirm(
    BuildContext context, {
    required RouteChangeQuote quote,
    required String paymentMethod,
  }) async {
    final result = await MoveraSheet.show<RouteChangeDecision>(
      context: context,
      builder: (_) => RouteChangeSheet(quote: quote, paymentMethod: paymentMethod),
    );
    return result ?? RouteChangeDecision.declined;
  }

  @override
  State<RouteChangeSheet> createState() => _RouteChangeSheetState();
}

class _RouteChangeSheetState extends State<RouteChangeSheet> {
  static const Color _ink = Color(0xFF1D252C);
  static const Color _muted = Color(0xFF5C656C);
  static const Color _accent = Color(0xFF2D5878);

  bool _paymentStep = false;
  RefundDestination _refundTo = RefundDestination.wallet;

  RouteChangeQuote get quote => widget.quote;
  String get paymentMethod => widget.paymentMethod;
  bool get _cash => isCashPayment(paymentMethod);
  double get _diff => quote.differenceKr;

  String _kr(double value) => '${value.round()} kr';

  void _confirmRoute() {
    if (_cash || _diff.abs() < 0.5) {
      Navigator.pop(context, const RouteChangeDecision(confirmed: true));
      return;
    }
    setState(() => _paymentStep = true);
  }

  void _confirmPayment() {
    Navigator.pop(
      context,
      RouteChangeDecision(
        confirmed: true,
        refundTo: _diff < 0 ? _refundTo : null,
      ),
    );
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
        _secondary(
          'Keep current route',
          () => Navigator.pop(context, RouteChangeDecision.declined),
        ),
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
          more ? 'Confirm payment' : 'Choose your refund',
          style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: _ink),
        ),
        const SizedBox(height: 6),
        Text(
          more
              ? 'The additional amount for the new route is charged to your payment method now.'
              : 'Your new route costs less. Please choose how you would like to receive the difference.',
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
                more ? 'Charged now' : 'Refund amount',
                '${more ? '+' : ''}${_kr(diff.abs())}',
                bold: true,
              ),
            ],
          ),
        ),
        if (!more) ...[
          const SizedBox(height: 14),
          _refundOption(
            RefundDestination.wallet,
            key: const ValueKey('refund-to-wallet'),
            title: 'Movera Wallet',
            subtitle:
                'Available immediately and used first on your next ride.',
            icon: Icons.account_balance_wallet_outlined,
          ),
          const SizedBox(height: 8),
          _refundOption(
            RefundDestination.originalMethod,
            key: const ValueKey('refund-to-original'),
            title: paymentMethod,
            subtitle:
                'Returned to your original payment method within 2 to 3 business days.',
            icon: Icons.credit_card_outlined,
          ),
        ],
        const SizedBox(height: 18),
        _primary(
          key: const ValueKey('route-change-pay'),
          label: more
              ? 'Confirm and pay ${_kr(diff)}'
              : _refundTo == RefundDestination.wallet
              ? 'Confirm refund to Movera Wallet'
              : 'Confirm refund to $paymentMethod',
          onPressed: _confirmPayment,
        ),
        const SizedBox(height: 8),
        _secondary('Back', () => setState(() => _paymentStep = false)),
      ],
    );
  }

  Widget _refundOption(
    RefundDestination value, {
    required Key key,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final selected = _refundTo == value;
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        key: key,
        borderRadius: BorderRadius.circular(14),
        onTap: () => setState(() => _refundTo = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? _ink : const Color(0xFFE2E6EA),
              width: selected ? 1.8 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, size: 22, color: _ink),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(fontSize: 14.5, fontWeight: FontWeight.w600, color: _ink),
                    ),
                    const SizedBox(height: 2),
                    Text(subtitle, style: GoogleFonts.poppins(fontSize: 12.5, color: _muted)),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                size: 22,
                color: selected ? _ink : const Color(0xFFC3C9CE),
              ),
            ],
          ),
        ),
      ),
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
