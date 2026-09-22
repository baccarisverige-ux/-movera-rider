import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movera_rider/features/finding_driver/application/cancel_first.dart';
import 'package:movera_rider/features/finding_driver/domain/cancellation_reason.dart';
import 'package:movera_rider/features/finding_driver/presentation/cancel_reason_sheet.dart';
import 'package:movera_rider/features/ride_booking/application/sheet_coordinator.dart';
import 'package:movera_rider/shared/design_system/movera_sheet.dart';

/// Confirm cancel, then optionally collect a why-reason.
///
/// **Cancel-first:** after **Cancel request**, matching + snapshot are cleared
/// before the why-sheet (via [onCancelConfirmed] or [commitCancelFirst]).
/// **Keep ride** on the why-sheet must not undo cancel.
Future<CancelOutcome> showCancelRideSheet(
  BuildContext context, {
  required bool takingLonger,
  CancelPhase phase = CancelPhase.searching,
  Future<void> Function()? onCancelConfirmed,
}) async {
  SheetCoordinator.instance.open(RideSheet.cancel);
  final confirmed = await MoveraSheet.show<bool>(
    context: context,
    swipeDismissible: false,
    barrierDismissible: false,
    builder: (_) => CancelRideSheet(
      takingLonger: takingLonger,
      phase: phase,
    ),
  );
  SheetCoordinator.instance.close(RideSheet.cancel);
  if (confirmed != true) return const CancelOutcome.keep();

  if (onCancelConfirmed != null) {
    await onCancelConfirmed();
  } else {
    await commitCancelFirst();
  }
  if (!context.mounted) return const CancelOutcome.cancel();
  final outcome = await showCancelReasonSheet(context, phase: phase);
  if (!outcome.cancelled) {
    return const CancelOutcome.cancel();
  }
  return outcome;
}

class CancelRideSheet extends StatelessWidget {
  const CancelRideSheet({
    super.key,
    required this.takingLonger,
    this.phase = CancelPhase.searching,
  });

  final bool takingLonger;
  final CancelPhase phase;

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.paddingOf(context).bottom;
    final matched = phase == CancelPhase.matched;
    final inTrip = phase == CancelPhase.inTrip;
    final body = inTrip
        ? 'Your trip is already in progress. Cancelling will end this ride and return you to Home.'
        : matched
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
                tooltip: 'Close',
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
                inTrip ? 'Cancel ride' : 'Cancel request',
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
              onPressed: () => Navigator.pop(context, false),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF11181D),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                (matched || inTrip)
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
