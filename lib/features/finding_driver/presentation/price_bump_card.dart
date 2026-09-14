import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movera_rider/shared/design_system/motion/movera_motion.dart';
import 'package:movera_rider/shared/design_system/tokens.dart';

/// Flat offer controls for delayed search — no nested dialog chrome.
class PriceBumpCard extends StatefulWidget {
  const PriceBumpCard({
    super.key,
    required this.currentPrice,
    required this.steps,
    required this.onConfirm,
    required this.onKeepWaiting,
  });

  final double currentPrice;
  final List<int> steps;
  final ValueChanged<int> onConfirm;
  final VoidCallback onKeepWaiting;

  @override
  State<PriceBumpCard> createState() => _PriceBumpCardState();
}

class _PriceBumpCardState extends State<PriceBumpCard> {
  final _price = TextEditingController();
  final _focus = FocusNode();
  int? _selectedStep;

  int get _current => widget.currentPrice.round();

  int? get _typedTotal {
    final raw = _price.text.trim();
    if (raw.isEmpty) return null;
    return int.tryParse(raw);
  }

  int? get _increase {
    final total = _typedTotal;
    if (total == null) return _selectedStep;
    final extra = total - _current;
    if (extra <= 0) return null;
    return extra;
  }

  bool get _canConfirm => _increase != null && _increase! > 0;

  @override
  void dispose() {
    _price.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _selectStep(int step) {
    setState(() {
      _selectedStep = step;
      _price.text = '${_current + step}';
      _price.selection = TextSelection.collapsed(offset: _price.text.length);
    });
  }

  void _onTyped(String value) {
    final total = int.tryParse(value.trim());
    setState(() {
      if (total == null) {
        _selectedStep = null;
        return;
      }
      final extra = total - _current;
      _selectedStep = widget.steps.contains(extra) ? extra : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final next = _current + (_increase ?? 0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Offer',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
                color: MoveraTokens.muted,
              ),
            ),
            const Spacer(),
            IconButton(
              onPressed: widget.onKeepWaiting,
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              icon: const Icon(
                Icons.close_rounded,
                size: 20,
                color: MoveraTokens.muted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Want to improve your chances?',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: MoveraTokens.ink,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Raise your offer. Nearby drivers see the new price first.',
          style: GoogleFonts.poppins(
            fontSize: 13,
            height: 1.35,
            color: const Color(0xFF5C656C),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Current $_current kr',
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF778189),
          ),
        ),
        const SizedBox(height: 10),
        for (var row = 0; row < widget.steps.length; row += 2) ...[
          if (row > 0) const SizedBox(height: 8),
          Row(
            children: [
              for (
                var i = row;
                i < row + 2 && i < widget.steps.length;
                i++
              ) ...[
                if (i > row) const SizedBox(width: 8),
                Expanded(
                  child: _Step(
                    label: '+${widget.steps[i]} kr',
                    selected: _selectedStep == widget.steps[i],
                    onTap: () => _selectStep(widget.steps[i]),
                  ),
                ),
              ],
            ],
          ),
        ],
        const SizedBox(height: 14),
        Text(
          'Or set a new price',
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: MoveraTokens.ink,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _price,
          focusNode: _focus,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: _onTyped,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: MoveraTokens.ink,
          ),
          decoration: InputDecoration(
            hintText: '$_current',
            hintStyle: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF9AA3A9),
            ),
            suffixText: 'kr',
            suffixStyle: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF5C656C),
            ),
            filled: true,
            fillColor: const Color(0xFFF6F8FA),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: MoveraTokens.line),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: MoveraTokens.line),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: MoveraTokens.accent),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton(
            onPressed: _canConfirm ? () => widget.onConfirm(_increase!) : null,
            style: FilledButton.styleFrom(
              backgroundColor: MoveraTokens.cta,
              disabledBackgroundColor: MoveraTokens.line,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              _canConfirm ? 'Confirm $next kr' : 'Set new price',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: _canConfirm ? Colors.white : const Color(0xFF9AA3A9),
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Center(
          child: TextButton(
            onPressed: widget.onKeepWaiting,
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
    return MoveraMotion.selection(
      selected: selected,
      child: Material(
        color: selected ? MoveraTokens.ink : Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? MoveraTokens.ink : MoveraTokens.line,
              ),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : MoveraTokens.ink,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
