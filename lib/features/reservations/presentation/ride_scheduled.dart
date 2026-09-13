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
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
              children: [
                const ReservationHeroArt(asset: AppAssets.sucess, height: 78),
                const SizedBox(height: 8),
                Text(
                  'Your ride is scheduled',
                  textAlign: TextAlign.center,
                  style: reservationText(
                    28,
                    weight: FontWeight.w700,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  ReservationFormat.scheduledReady(ride.scheduledPickupAt),
                  textAlign: TextAlign.center,
                  style: reservationText(
                    14.5,
                    color: kReservationMuted,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 10),
                Center(child: ReservationDriverBadge(ride: ride)),
                const SizedBox(height: 22),
                ReservationHeroArt(asset: ride.categoryImage, height: 80),
                const SizedBox(height: 6),
                Text(
                  ride.categoryName,
                  textAlign: TextAlign.center,
                  style: reservationText(20, weight: FontWeight.w700),
                ),
                Text(
                  ReservationFormat.price(ride),
                  textAlign: TextAlign.center,
                  style: reservationText(16, weight: FontWeight.w600),
                ),
                const SizedBox(height: 18),
                ReservationFact(
                  asset: AppAssets.scheduleCalendar,
                  label: 'Pickup',
                  value:
                      '${ReservationFormat.longDate(ride.scheduledPickupAt)}  ·  ${ReservationFormat.time(ride.scheduledPickupAt)}',
                ),
                ReservationFact(
                  asset: AppAssets.gps,
                  label: 'From',
                  value: ride.pickup.label,
                ),
                ReservationFact(
                  asset: AppAssets.location,
                  label: 'To',
                  value: ride.destination.label,
                ),
                ReservationFact(
                  asset: AppAssets.payment,
                  label: 'Payment',
                  value: ride.paymentMethod,
                  trailing: ReservationPaymentMark(method: ride.paymentMethod),
                ),
                if (ride.hasPreferences)
                  ReservationFact(
                    asset: AppAssets.note,
                    label: 'Preferences',
                    value: ride.note!.trim(),
                  ),
                const SizedBox(height: 18),
                _ReturnRow(onTap: () => _planReturn(ride)),
                const SizedBox(height: 8),
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
                if (ride.status.canEdit)
                  TextButton(
                    onPressed: () => _editReservation(ride),
                    child: Text(
                      'Edit',
                      style: reservationText(15, weight: FontWeight.w600),
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

class _ReturnRow extends StatelessWidget {
  const _ReturnRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: kReservationSoft,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          child: Row(
            children: [
              Image.asset(
                AppAssets.calender,
                width: 46,
                height: 46,
                fit: BoxFit.contain,
              ),
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
