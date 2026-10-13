import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movera_rider/features/active_ride/application/route_change_controller.dart';
import 'package:movera_rider/shared/design_system/movera_sheet.dart';

/// "New route, new price": the rider confirms a priced route change.
/// Resolves true when confirmed.
class RouteChangeSheet extends StatelessWidget {
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

  static const Color _ink = Color(0xFF1D252C);
  static const Color _muted = Color(0xFF5C656C);
  static const Color _accent = Color(0xFF2D5878);

  String _kr(double value) => '${value.round()} kr';

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.paddingOf(context).bottom;
    final diff = quote.differenceKr;
    final String priceNote;
    if (diff.abs() < 0.5) {
      priceNote = 'Same price as before.';
    } else if (diff > 0) {
      priceNote = '+${_kr(diff)} more, charged to $paymentMethod.';
    } else {
      priceNote = '${_kr(-diff)} less — the difference comes back to you.';
    }
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 16 + inset),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'New route',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: _ink,
            ),
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
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _muted,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        priceNote,
                        style: GoogleFonts.poppins(fontSize: 12.5, color: _muted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _kr(quote.newPriceKr),
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: _ink,
                      ),
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
          SizedBox(
            width: double.infinity,
            height: 54,
            child: FilledButton(
              key: const ValueKey('route-change-confirm'),
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF11181D),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                'Confirm change',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: TextButton(
              onPressed: () => Navigator.pop(context, false),
              style: TextButton.styleFrom(foregroundColor: _accent),
              child: Text(
                'Keep current route',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
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
