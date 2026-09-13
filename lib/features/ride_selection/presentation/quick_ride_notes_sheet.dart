import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movera_rider/features/ride_booking/application/sheet_coordinator.dart';
import 'package:movera_rider/features/ride_booking/domain/ride_notes.dart';
import 'package:movera_rider/shared/design_system/motion/movera_motion.dart';
import 'package:movera_rider/shared/design_system/movera_sheet.dart';

Future<RideNotes?> showQuickRideNotesSheet(BuildContext context) {
  SheetCoordinator.instance.open(RideSheet.notes);
  return MoveraSheet.show<RideNotes>(
    context: context,
    builder: (_) => const QuickRideNotesSheet(),
  ).whenComplete(() => SheetCoordinator.instance.close(RideSheet.notes));
}

class QuickRideNotesSheet extends StatefulWidget {
  const QuickRideNotesSheet({super.key});

  @override
  State<QuickRideNotesSheet> createState() => _QuickRideNotesSheetState();
}

class _QuickRideNotesSheetState extends State<QuickRideNotesSheet> {
  RideNotes _notes = RideNotes.empty;

  TextStyle _text(
    double size, {
    FontWeight weight = FontWeight.w400,
    Color color = const Color(0xFF1D252C),
  }) {
    return GoogleFonts.poppins(
      fontSize: size,
      fontWeight: weight,
      color: color,
    );
  }

  void _submit() => Navigator.pop(context, _notes);

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.paddingOf(context).bottom;
    const items = [
      (key: 'bags', label: 'Bags', icon: Icons.luggage_outlined),
      (key: 'pet', label: 'Pet', icon: Icons.pets_outlined),
      (key: 'baby', label: 'Baby', icon: Icons.child_care_outlined),
      (key: 'child', label: 'Child', icon: Icons.escalator_warning_outlined),
    ];
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 10, 20, 16 + inset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE7EBEE),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Anything we should know?', style: _text(20, weight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(
            'Optional. Your driver will see this.',
            style: _text(13, color: const Color(0xFF778189)),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final item in items)
                _Chip(
                  label: item.label,
                  icon: item.icon,
                  selected: switch (item.key) {
                    'bags' => _notes.bags,
                    'pet' => _notes.pet,
                    'baby' => _notes.baby,
                    _ => _notes.child,
                  },
                  onTap: () => setState(() => _notes = _notes.toggle(item.key)),
                ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: TextButton(
              onPressed: () => Navigator.pop(context, RideNotes.empty),
              child: Text(
                'None / Skip',
                style: _text(14, weight: FontWeight.w600, color: const Color(0xFF778189)),
              ),
            ),
          ),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: FilledButton(
              onPressed: _submit,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF11181D),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: Text('Find driver', style: _text(16, weight: FontWeight.w600, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFFEAF2F8) : const Color(0xFFF6F8FA),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: MoveraMotion.selection(
          selected: selected,
          child: Container(
            width: 84,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? const Color(0xFF2D5878) : const Color(0xFFE7EBEE),
              ),
            ),
            child: Column(
              children: [
                Icon(icon, size: 22, color: const Color(0xFF1D252C)),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1D252C),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
