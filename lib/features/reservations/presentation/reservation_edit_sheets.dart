import 'package:flutter/material.dart';
import 'package:movera_rider/features/finding_driver/domain/cancellation_reason.dart';
import 'package:movera_rider/features/finding_driver/presentation/cancel_reason_sheet.dart';
import 'package:movera_rider/features/reservations/domain/reservation.dart';
import 'package:movera_rider/features/reservations/presentation/reservation_format.dart';
import 'package:movera_rider/features/reservations/presentation/reservation_widgets.dart';
import 'package:movera_rider/shared/design_system/movera_sheet.dart';

Future<CancelOutcome> showCancelReservationFlow(
  BuildContext context,
  Reservation ride,
) async {
  final confirmed = await MoveraSheet.show<bool>(
    context: context,
    builder: (sheetContext) {
      final inset = MediaQuery.paddingOf(sheetContext).bottom;
      return Padding(
        padding: EdgeInsets.fromLTRB(20, 10, 20, 16 + inset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: kReservationLine,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Cancel reservation?',
              style: reservationText(20, weight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Your ride for ${ReservationFormat.weekdayDate(ride.scheduledPickupAt)} at ${ReservationFormat.time(ride.scheduledPickupAt)} will move to history. It will not be deleted.',
              style: reservationText(
                14,
                color: kReservationMuted,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: TextButton(
                onPressed: () => Navigator.pop(sheetContext, true),
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFFF4F5F6),
                  foregroundColor: const Color(0xFFB42318),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Cancel reservation',
                  style: reservationText(
                    15,
                    weight: FontWeight.w600,
                    color: const Color(0xFFB42318),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton(
                onPressed: () => Navigator.pop(sheetContext, false),
                style: FilledButton.styleFrom(
                  backgroundColor: kReservationCta,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: Text(
                  'Keep reservation',
                  style: reservationText(
                    16,
                    weight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
  if (confirmed != true || !context.mounted) {
    return const CancelOutcome.keep();
  }
  return showCancelReasonSheet(context, phase: CancelPhase.reservation);
}
