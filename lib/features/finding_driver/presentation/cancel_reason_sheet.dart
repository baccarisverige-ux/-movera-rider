import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movera_rider/features/finding_driver/domain/cancellation_reason.dart';
import 'package:movera_rider/features/ride_booking/application/sheet_coordinator.dart';
import 'package:movera_rider/shared/design_system/movera_sheet.dart';

Future<CancelOutcome> showCancelReasonSheet(
  BuildContext context, {
  required CancelPhase phase,
}) async {
  SheetCoordinator.instance.open(RideSheet.cancelReason);
  final result = await MoveraSheet.show<CancelOutcome>(
    context: context,
    builder: (_) => CancelReasonSheet(phase: phase),
  );
  SheetCoordinator.instance.close(RideSheet.cancelReason);
  // Already confirmed cancel on the previous sheet. Dismiss still cancels.
  return result ?? const CancelOutcome.cancel();
}

class CancelReasonSheet extends StatefulWidget {
  const CancelReasonSheet({super.key, required this.phase});

  final CancelPhase phase;

  @override
  State<CancelReasonSheet> createState() => _CancelReasonSheetState();
}

class _CancelReasonSheetState extends State<CancelReasonSheet> {
  String? _selected;

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.paddingOf(context).bottom;
    final reasons = CancellationReason.forPhase(widget.phase);
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 10, 20, 16 + inset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                TextButton(
                  onPressed: () =>
                      Navigator.pop(context, const CancelOutcome.cancel()),
                  child: Text(
                    'Skip',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF5C656C),
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Why are you cancelling?',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1D252C),
                    ),
                  ),
                ),
                const SizedBox(width: 56),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              widget.phase == CancelPhase.reservation
                  ? 'Optional. This helps us improve scheduled rides.'
                  : 'Optional. This helps us improve matching.',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: const Color(0xFF5C656C),
              ),
            ),
            const SizedBox(height: 12),
            for (final reason in reasons)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: _selected == reason.id
                      ? const Color(0xFFF3F6FB)
                      : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(
                      color: _selected == reason.id
                          ? const Color(0xFF1D252C)
                          : const Color(0xFFE7EBEE),
                    ),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => setState(() => _selected = reason.id),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              reason.label,
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF1D252C),
                              ),
                            ),
                          ),
                          Icon(
                            _selected == reason.id
                                ? Icons.check_circle_rounded
                                : Icons.circle_outlined,
                            size: 20,
                            color: _selected == reason.id
                                ? const Color(0xFF1D252C)
                                : const Color(0xFFC5CCD1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: TextButton(
                onPressed: _selected == null
                    ? null
                    : () => Navigator.pop(
                        context,
                        CancelOutcome.cancel(reasonId: _selected),
                      ),
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFFF4F5F6),
                  foregroundColor: const Color(0xFFB42318),
                  disabledForegroundColor: const Color(0xFFC5CCD1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Cancel ride',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton(
                onPressed: () =>
                    Navigator.pop(context, const CancelOutcome.keep()),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF11181D),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Keep ride',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
