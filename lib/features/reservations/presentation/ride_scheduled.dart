import 'package:flutter/material.dart';
import 'package:movera_rider/app/di.dart';
import 'package:movera_rider/features/reservations/application/reservation_controller.dart';
import 'package:movera_rider/features/reservations/domain/reservation.dart';
import 'package:movera_rider/features/reservations/presentation/plan_return_ride.dart';
import 'package:movera_rider/features/reservations/presentation/reservation_format.dart';
import 'package:movera_rider/features/reservations/presentation/reservation_widgets.dart';
import 'package:movera_rider/features/reservations/presentation/upcoming_reservation.dart';
import 'package:movera_rider/shared/widgets/navigation_transition.dart';

class RideScheduledPage extends StatefulWidget {
  const RideScheduledPage({
    super.key,
    required this.reservationId,
    this.controller,
  });

  final String reservationId;
  final ReservationController? controller;

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
    final created = await Navigator.push<Reservation>(
      context,
      RightToLeftTransition(
        PlanReturnRidePage(origin: ride, controller: _reservations),
      ),
    );
    if (created == null || !mounted) return;
    await Navigator.push(
      context,
      BottomToTopTransition(
        RideScheduledPage(
          reservationId: created.reservationId,
          controller: _reservations,
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
                  'Ride scheduled',
                  style: reservationText(
                    32,
                    weight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  ReservationFormat.reservedHeadline(ride.scheduledPickupAt),
                  style: reservationText(
                    15,
                    color: kReservationMuted,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 22),
                _ReservationCard(ride: ride, onEdit: () => _openDetails(ride)),
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
                    'View details',
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: kReservationLine),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ReservationRoutePreview(
            pickup: ride.pickup.label,
            destination: ride.destination.label,
            height: 132,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 16, 8, 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ReservationFormat.cardDate(ride.scheduledPickupAt),
                        style: reservationText(18, weight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        ReservationFormat.pickupAt(ride.scheduledPickupAt),
                        style: reservationText(13.5, color: kReservationMuted),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${ride.categoryName} · ${ReservationFormat.price(ride)}',
                        style: reservationText(13.5, color: kReservationMuted),
                      ),
                      const SizedBox(height: 8),
                      ReservationDriverBadge(ride: ride),
                    ],
                  ),
                ),
                Column(
                  children: [
                    SizedBox(
                      width: 72,
                      height: 44,
                      child: Image.asset(
                        ride.categoryImage,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.directions_car_filled_rounded),
                      ),
                    ),
                    const SizedBox(height: 10),
                    MoveraReserveBadge(when: ride.scheduledPickupAt),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
            child: Row(
              children: [
                ReservationEditChip(onTap: onEdit),
                const Spacer(),
                Text(
                  ride.paymentMethod,
                  style: reservationText(12.5, color: kReservationMuted),
                ),
              ],
            ),
          ),
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
              const Icon(Icons.event_repeat_rounded, color: kReservationAccent),
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
                      'Prefill the reverse route, then confirm',
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
