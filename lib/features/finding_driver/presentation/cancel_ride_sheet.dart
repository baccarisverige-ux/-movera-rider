import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movera_rider/features/finding_driver/domain/cancellation_reason.dart';
import 'package:movera_rider/features/finding_driver/presentation/cancel_reason_sheet.dart';

Future<CancelOutcome> showCancelRideSheet(
  BuildContext context, {
  required bool takingLonger,
  CancelPhase phase = CancelPhase.searching,
}) async {
  final confirmed = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.white,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (_) => CancelRideSheet(
      takingLonger: takingLonger,
      matched: phase == CancelPhase.matched,
    ),
  );
  if (confirmed != true || !context.mounted) return const CancelOutcome.keep();
  return showCancelReasonSheet(context, phase: phase);
}

class CancelRideSheet extends StatelessWidget {
  const CancelRideSheet({
    super.key,
    required this.takingLonger,
    this.matched = false,
  });

  final bool takingLonger;
  final bool matched;

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.paddingOf(context).bottom;
    final body = matched
        ? 'Your driver is already on the way. If you cancel now, you will need to request again.'
        : takingLonger
            ? 'This is taking longer than usual. We are still searching for a nearby driver. If you cancel, you will need to request again.'
            : 'Movera is still searching for a nearby driver. Your trip should be confirmed shortly.';
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 10, 20, 16 + inset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SizedBox(width: 40),
              Expanded(
                child: Text(
                  'Cancel ride?',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1D252C),
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context, false),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Are you sure you want to cancel?',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1D252C),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: GoogleFonts.poppins(
              fontSize: 14,
              height: 1.4,
              color: const Color(0xFF5C656C),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFF4F5F6),
                foregroundColor: const Color(0xFFB42318),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                'Cancel request',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: FilledButton(
              onPressed: () => Navigator.pop(context, false),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF11181D),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                matched
                    ? 'Keep ride'
                    : takingLonger
                        ? 'Keep searching'
                        : 'Wait for driver',
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
    );
  }
}
