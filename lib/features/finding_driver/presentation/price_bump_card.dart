import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PriceBumpCard extends StatelessWidget {
  const PriceBumpCard({
    super.key,
    required this.currentPrice,
    required this.steps,
    required this.selected,
    required this.onSelect,
    required this.onConfirm,
    required this.onKeepWaiting,
  });

  final double currentPrice;
  final List<int> steps;
  final int? selected;
  final ValueChanged<int> onSelect;
  final VoidCallback onConfirm;
  final VoidCallback onKeepWaiting;

  @override
  Widget build(BuildContext context) {
    final next = currentPrice + (selected ?? 0);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7EBEE)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Want to improve your chances?',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1D252C),
                  ),
                ),
              ),
              GestureDetector(
                onTap: onKeepWaiting,
                child: const Icon(Icons.close_rounded, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            "Increase your offer and we'll search again with your updated price.",
            style: GoogleFonts.poppins(
              fontSize: 13,
              height: 1.35,
              color: const Color(0xFF5C656C),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Current ${currentPrice.round()} kr',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF778189),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (var i = 0; i < steps.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(
                  child: _Step(
                    label: '+${steps[i]} kr',
                    selected: selected == steps[i],
                    onTap: () => onSelect(steps[i]),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: selected == null ? null : onConfirm,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF11181D),
                disabledBackgroundColor: const Color(0xFFE7EBEE),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                selected == null
                    ? 'Confirm new price'
                    : 'Confirm ${next.round()} kr',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: selected == null
                      ? const Color(0xFF9AA3A9)
                      : Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: onKeepWaiting,
              child: Text(
                'Keep waiting',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF5C656C),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFF1D252C) : const Color(0xFFF6F8FA),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : const Color(0xFF1D252C),
            ),
          ),
        ),
      ),
    );
  }
}
