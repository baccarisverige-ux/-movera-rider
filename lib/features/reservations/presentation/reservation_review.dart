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
    final minutes = draft.estimatedDropoffAt
        ?.difference(draft.scheduledPickupAt)
        .inMinutes;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          SizedBox(height: top + 4),
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: () => Navigator.pop(context, false),
              icon: const Icon(Icons.close_rounded, color: kReservationInk),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              children: [
                const ReservationHeroArt(
                  asset: AppAssets.scheduleTimeline,
                  height: 128,
                ),
                const SizedBox(height: 8),
                Text(
                  'Your scheduled ride',
                  textAlign: TextAlign.center,
                  style: reservationText(
                    28,
                    weight: FontWeight.w700,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Review the details before you schedule your ride.',
                  textAlign: TextAlign.center,
                  style: reservationText(
                    14.5,
                    color: kReservationMuted,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 22),
                ReservationHeroArt(asset: draft.categoryImage, height: 86),
                const SizedBox(height: 4),
                Text(
                  draft.categoryName,
                  textAlign: TextAlign.center,
                  style: reservationText(18, weight: FontWeight.w700),
                ),
                Text(
                  minutes == null
                      ? ReservationFormat.kr(draft.price)
                      : '${minutes} min  ·  ${ReservationFormat.kr(draft.price)}',
                  textAlign: TextAlign.center,
                  style: reservationText(14, color: kReservationMuted),
                ),
                const SizedBox(height: 18),
                ReservationFact(
                  asset: AppAssets.scheduleCalendar,
                  label: 'Pickup date',
                  value: ReservationFormat.longDate(draft.scheduledPickupAt),
                ),
                ReservationFact(
                  asset: AppAssets.time,
                  label: 'Pickup time',
                  value: ReservationFormat.time(draft.scheduledPickupAt),
                ),
                ReservationFact(
                  asset: AppAssets.gps,
                  label: 'Pickup',
                  value: draft.pickup.label,
                ),
                ReservationFact(
                  asset: AppAssets.location,
                  label: 'Destination',
                  value: draft.destination.label,
                ),
                ReservationFact(
                  asset: AppAssets.payment,
                  label: 'Payment',
                  value: draft.paymentMethod,
                  trailing: ReservationPaymentMark(method: draft.paymentMethod),
                ),
                if (draft.note != null && draft.note!.trim().isNotEmpty)
                  ReservationFact(
                    asset: AppAssets.note,
                    label: 'Preferences',
                    value: draft.note!.trim(),
                  ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => ScheduledRideTermsPage.open(context),
                  child: Text(
                    'View scheduled ride terms',
                    textAlign: TextAlign.center,
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
            padding: EdgeInsets.fromLTRB(24, 8, 24, 16 + bottom),
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
    return ReservationHeroArt(asset: draft.categoryImage, height: 80);
  }
}
