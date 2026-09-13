import 'package:flutter/material.dart';
import 'package:movera_rider/app/di.dart';
import 'package:movera_rider/core/constants/appassets.dart';
import 'package:movera_rider/features/reservations/application/reservation_controller.dart';
import 'package:movera_rider/features/reservations/domain/reservation.dart';
import 'package:movera_rider/features/reservations/presentation/plan_return_ride.dart';
import 'package:movera_rider/features/reservations/presentation/reservation_format.dart';
import 'package:movera_rider/features/reservations/presentation/reservation_widgets.dart';
import 'package:movera_rider/features/reservations/presentation/upcoming_reservation.dart';
import 'package:movera_rider/features/scheduled_rides/presentation/schedule_ride.dart';
import 'package:movera_rider/shared/widgets/navigation_transition.dart';

class RideScheduledPage extends StatefulWidget {
  const RideScheduledPage({
    super.key,
    required this.reservationId,
    this.controller,
  });

  final String reservationId;
  final ReservationController? controller;

  static Future<void> open(
    BuildContext context, {
    required String reservationId,
    ReservationController? controller,
    bool replace = false,
    bool untilHome = false,
  }) {
    final route = BottomToTopTransition(
      RideScheduledPage(reservationId: reservationId, controller: controller),
    );
    if (untilHome) {
      return Navigator.pushAndRemoveUntil(context, route, (r) => r.isFirst);
    }
    if (replace) {
      return Navigator.pushReplacement(context, route);
    }
    return Navigator.push(context, route);
  }

  @override
  State<RideScheduledPage> createState() => _RideScheduledPageState();
}

class _RideScheduledPageState extends State<RideScheduledPage> {
  late final ReservationController _reservations;

  @override
  void initState() {
    super.initState();
    _reservations = widget.controller ?? AppScope.instance.reservations;
    _reservations.addListener(_refresh);
  }

  @override
  void dispose() {
    _reservations.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  void _closeHome() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _editReservation(Reservation ride) async {
    if (!ride.status.canEdit) return;
    await Navigator.push(
      context,
      BottomToTopTransition(ScheduleRide(editing: ride)),
    );
  }

  Future<void> _openDetails(Reservation ride) async {
    await Navigator.push(
      context,
      RightToLeftTransition(
        UpcomingReservationPage(
          reservationId: ride.reservationId,
          controller: _reservations,
        ),
      ),
    );
  }

  Future<void> _planReturn(Reservation ride) async {
    await Navigator.push(
      context,
      RightToLeftTransition(
        PlanReturnRidePage(
          origin: ride,
          controller: _reservations,
          onScheduled: (context, id) => RideScheduledPage.open(
            context,
            reservationId: id,
            controller: _reservations,
            replace: true,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ride = _reservations.byId(widget.reservationId);
    final top = MediaQuery.paddingOf(context).top;
    if (ride == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Text('Reservation not found', style: reservationText(16)),
        ),
      );
    }
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          SizedBox(height: top + 4),
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: _closeHome,
              icon: const Icon(Icons.close_rounded, color: kReservationInk),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 28),
              children: [
                Text(
                  'Your ride is scheduled',
                  style: reservationText(
                    32,
                    weight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  ReservationFormat.scheduledReady(ride.scheduledPickupAt),
                  style: reservationText(
                    15,
                    color: kReservationMuted,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 22),
                _ReservationCard(
                  ride: ride,
                  onEdit: () => _editReservation(ride),
                ),
                const SizedBox(height: 28),
                Text(
                  'Need another ride?',
                  style: reservationText(18, weight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                _ReturnRow(onTap: () => _planReturn(ride)),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => _openDetails(ride),
                  child: Text(
                    'View reservation',
                    style: reservationText(
                      15,
                      weight: FontWeight.w600,
                      color: kReservationAccent,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReservationCard extends StatelessWidget {
  const _ReservationCard({required this.ride, required this.onEdit});

  final Reservation ride;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 72,
                height: 48,
                child: Image.asset(
                  ride.categoryImage,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.directions_car_filled_rounded,
                    size: 32,
                    color: kReservationAccent,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: ReservationDriverBadge(ride: ride),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  ReservationFormat.cardDate(ride.scheduledPickupAt),
                  style: reservationText(20, weight: FontWeight.w700),
                ),
              ),
              MoveraReserveBadge(when: ride.scheduledPickupAt),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            ReservationFormat.pickupAt(ride.scheduledPickupAt),
            style: reservationText(13.5, color: kReservationMuted),
          ),
          const SizedBox(height: 2),
          Text(
            '${ride.pickup.label}  →  ${ride.destination.label}',
            style: reservationText(14, weight: FontWeight.w600, height: 1.35),
          ),
          const SizedBox(height: 2),
          Text(
            '${ride.categoryName}  ·  ${ReservationFormat.price(ride)}  ·  ${ride.paymentMethod}',
            style: reservationText(13.5, color: kReservationMuted),
          ),
          if (ride.hasPreferences) ...[
            const SizedBox(height: 2),
            Text(
              ride.note!.trim(),
              style: reservationText(13.5, color: kReservationMuted),
            ),
          ],
          const SizedBox(height: 16),
          ReservationEditChip(onTap: onEdit),
        ],
      ),
    );
  }
}

class _ReturnRow extends StatelessWidget {
  const _ReturnRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: kReservationSoft,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
          child: Row(
            children: [
              const MoveraGlyph(asset: AppAssets.scheduleCalendar),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Plan a return ride',
                      style: reservationText(15, weight: FontWeight.w600),
                    ),
                    Text(
                      'Choose category, then confirm a new reservation',
                      style: reservationText(12.5, color: kReservationMuted),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: kReservationMuted),
            ],
          ),
        ),
      ),
    );
  }
}
