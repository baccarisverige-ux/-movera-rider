import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movera_rider/core/constants/appassets.dart';

/// "Add card". Card numbers are only ever typed into the payment partner's
/// secure form (e.g. Stripe), so until that is connected this screen shows
/// the card setup without taking any card details.
class AddCardPage extends StatelessWidget {
  const AddCardPage({super.key});

  static const String unavailableNote =
      'Card setup isn\'t connected yet. Your card will be saved by our secure '
      'payment partner — Movera never sees the full number. For now, choose '
      'Pay in car, Apple Pay or Google Pay.';

  static Future<void> open(BuildContext context) => Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => const AddCardPage()),
  );

  static const Color _ink = Color(0xFF1D252C);
  static const Color _muted = Color(0xFF5C656C);
  static const Color _accent = Color(0xFF2D5878);
  static const Color _field = Color(0xFFF6F7F7);

  TextStyle _t(double size, {FontWeight w = FontWeight.w500, Color c = _ink}) =>
      GoogleFonts.poppins(fontSize: size, fontWeight: w, color: c);

  Widget _box(String label, String placeholder) => Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(14, 9, 14, 11),
    decoration: BoxDecoration(
      color: _field,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE7EBEE)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _t(11, c: _muted)),
        const SizedBox(height: 2),
        Text(placeholder, style: _t(16, w: FontWeight.w400, c: const Color(0xFF9AA2A8))),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        foregroundColor: _ink,
        title: Text('Add card', style: _t(18, w: FontWeight.w700)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Container(
              height: 190,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_accent, Color(0xFF1A3449)],
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: _accent.withValues(alpha: 0.35),
                    blurRadius: 30,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 30,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE9D8A6), Color(0xFFC8A85C)],
                      ),
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '••••  ••••  ••••  ••••',
                    style: _t(20, c: Colors.white).copyWith(letterSpacing: 2),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'NAME ON CARD',
                          style: _t(11, c: Colors.white70),
                        ),
                      ),
                      Text('MM/YY', style: _t(11, c: Colors.white70)),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Image.asset(AppAssets.visa, height: 14),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            _box('Card number', '1234 5678 9012 3456'),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _box('Expiry', 'MM / YY')),
                const SizedBox(width: 12),
                Expanded(child: _box('CVC', '123')),
              ],
            ),
            const SizedBox(height: 10),
            _box('Name on card', 'Your name'),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF2F8),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lock_outline_rounded, color: _accent, size: 20),
                  const SizedBox(width: 10),
                  Expanded(child: Text(unavailableNote, style: _t(12.5, c: _accent))),
                ],
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 54,
              child: FilledButton(
                onPressed: null,
                style: FilledButton.styleFrom(
                  disabledBackgroundColor: const Color(0xFFD5DADD),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: Text(
                  'Save card and continue',
                  style: _t(16, w: FontWeight.w600, c: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
