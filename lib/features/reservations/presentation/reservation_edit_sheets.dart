import 'package:flutter/material.dart';
import 'package:movera_rider/features/finding_driver/domain/cancellation_reason.dart';
import 'package:movera_rider/features/finding_driver/presentation/cancel_reason_sheet.dart';
import 'package:movera_rider/features/reservations/domain/reservation.dart';
import 'package:movera_rider/features/reservations/presentation/reservation_format.dart';
import 'package:movera_rider/features/reservations/presentation/reservation_widgets.dart';
import 'package:movera_rider/features/ride_selection/application/ride_selection_controller.dart';
import 'package:movera_rider/shared/design_system/movera_sheet.dart';

Future<DateTime?> showReservationTimeSheet(
  BuildContext context, {
  required DateTime initial,
}) async {
  final now = DateTime.now();
  final date = await showDatePicker(
    context: context,
    initialDate: initial.isAfter(now)
        ? initial
        : now.add(const Duration(hours: 1)),
    firstDate: now,
    lastDate: now.add(const Duration(days: 180)),
    helpText: 'Choose pickup date',
  );
  if (date == null || !context.mounted) return null;
  final time = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.fromDateTime(initial),
    helpText: 'Choose pickup time',
  );
  if (time == null) return null;
  return DateTime(date.year, date.month, date.day, time.hour, time.minute);
}

Future<ReservationPlace?> showReservationPlaceSheet(
  BuildContext context, {
  required String title,
  required ReservationPlace current,
}) {
  return MoveraSheet.show<ReservationPlace>(
    context: context,
    builder: (sheetContext) {
      return _PlaceEditorSheet(title: title, current: current);
    },
  );
}

class _PlaceEditorSheet extends StatefulWidget {
  const _PlaceEditorSheet({required this.title, required this.current});

  final String title;
  final ReservationPlace current;

  @override
  State<_PlaceEditorSheet> createState() => _PlaceEditorSheetState();
}

class _PlaceEditorSheetState extends State<_PlaceEditorSheet> {
  late final TextEditingController _label;
  late final TextEditingController _subtitle;

  @override
  void initState() {
    super.initState();
    _label = TextEditingController(text: widget.current.label);
    _subtitle = TextEditingController(text: widget.current.subtitle ?? '');
  }

  @override
  void dispose() {
    _label.dispose();
    _subtitle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.paddingOf(context).bottom;
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
            widget.title,
            style: reservationText(20, weight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'This updates the same reservation. Other details stay as they are.',
            style: reservationText(13, color: kReservationMuted, height: 1.4),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _label,
            autofocus: true,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: 'Address',
              labelStyle: reservationText(13, color: kReservationMuted),
              filled: true,
              fillColor: kReservationSoft,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _subtitle,
            decoration: InputDecoration(
              labelText: 'Area or note (optional)',
              labelStyle: reservationText(13, color: kReservationMuted),
              filled: true,
              fillColor: kReservationSoft,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: FilledButton(
              onPressed: () {
                final label = _label.text.trim();
                if (label.isEmpty) return;
                Navigator.pop(
                  context,
                  widget.current.copyWith(
                    label: label,
                    subtitle: _subtitle.text.trim().isEmpty
                        ? widget.current.subtitle
                        : _subtitle.text.trim(),
                  ),
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: kReservationCta,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: Text(
                'Save',
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
  }
}

Future<String?> showReservationPaymentSheet(
  BuildContext context, {
  required String current,
}) {
  final methods = RideSelectionController().payments();
  return MoveraSheet.show<String>(
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
              'Payment method',
              style: reservationText(20, weight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            for (final method in methods)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  method.name,
                  style: reservationText(15, weight: FontWeight.w600),
                ),
                subtitle: Text(
                  method.detail,
                  style: reservationText(12.5, color: kReservationMuted),
                ),
                trailing: method.name == current
                    ? const Icon(Icons.check_rounded, color: kReservationAccent)
                    : null,
                onTap: () => Navigator.pop(sheetContext, method.name),
              ),
          ],
        ),
      );
    },
  );
}

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
