import 'package:flutter/material.dart';
import 'package:movera_rider/core/constants/appassets.dart';
import 'package:movera_rider/features/reservations/domain/reservation.dart';
import 'package:movera_rider/features/reservations/presentation/reservation_format.dart';
import 'package:movera_rider/features/reservations/presentation/reservation_widgets.dart';
import 'package:movera_rider/features/reservations/presentation/scheduled_ride_terms.dart';

class ReservationReviewPage extends StatelessWidget {
  const ReservationReviewPage({
    super.key,
    required this.draft,
    required this.ctaLabel,
  });

  final ReservationDraft draft;
  final String ctaLabel;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          SizedBox(height: top + 4),
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context, false),
                icon: const Icon(Icons.close_rounded, color: kReservationInk),
              ),
              Expanded(
                child: Text(
                  'SCHEDULE',
                  textAlign: TextAlign.center,
                  style: reservationText(
                    10,
                    weight: FontWeight.w600,
                    color: kReservationMuted,
                    letterSpacing: 1.4,
                  ),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
              children: [
                Text(
                  'Your scheduled ride',
                  style: reservationText(
                    28,
                    weight: FontWeight.w700,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Review the details before you schedule your ride.',
                  style: reservationText(
                    14.5,
                    color: kReservationMuted,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 22),
                ReservationDraftCard(draft: draft),
                const SizedBox(height: 18),
                GestureDetector(
                  onTap: () => ScheduledRideTermsPage.open(context),
                  child: Text(
                    'View scheduled ride terms',
                    style: reservationText(
                      14.5,
                      weight: FontWeight.w600,
                      color: kReservationAccent,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(22, 8, 22, 16 + bottom),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kReservationInk,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: Text(
                  ctaLabel,
                  style: reservationText(
                    15,
                    weight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ReservationDraftCard extends StatelessWidget {
  const ReservationDraftCard({super.key, required this.draft});

  final ReservationDraft draft;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: kReservationLine),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 22,
            offset: Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 72,
                height: 48,
                child: Image.asset(
                  draft.categoryImage,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Image.asset(
                    AppAssets.scheduleRideCar,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      draft.categoryName,
                      style: reservationText(16, weight: FontWeight.w700),
                    ),
                    Text(
                      draft.estimatedDropoffAt == null
                          ? draft.paymentMethod
                          : '${draft.estimatedDropoffAt!.difference(draft.scheduledPickupAt).inMinutes} min  ·  ${draft.paymentMethod}',
                      style: reservationText(12.5, color: kReservationMuted),
                    ),
                  ],
                ),
              ),
              Text(
                ReservationFormat.kr(draft.price),
                style: reservationText(16, weight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(color: kReservationLine),
          _row(
            asset: AppAssets.scheduleCalendar,
            label: 'Pickup date',
            value: ReservationFormat.longDate(draft.scheduledPickupAt),
          ),
          _row(
            asset: AppAssets.time,
            label: 'Pickup time',
            value: ReservationFormat.time(draft.scheduledPickupAt),
          ),
          _row(
            asset: AppAssets.gps,
            label: 'Pickup',
            value: draft.pickup.label,
          ),
          _row(
            asset: AppAssets.location,
            label: 'Destination',
            value: draft.destination.label,
          ),
          if (draft.note != null && draft.note!.trim().isNotEmpty)
            _row(
              asset: AppAssets.note,
              label: 'Preferences',
              value: draft.note!.trim(),
            ),
        ],
      ),
    );
  }

  Widget _row({
    required String asset,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MoveraGlyph(asset: asset),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: reservationText(12, color: kReservationMuted),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: reservationText(15, weight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
