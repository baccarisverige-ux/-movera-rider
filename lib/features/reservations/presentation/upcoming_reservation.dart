import 'package:flutter/material.dart';
import 'package:movera_rider/app/di.dart';
import 'package:movera_rider/core/constants/appassets.dart';
import 'package:movera_rider/features/reservations/application/reservation_controller.dart';
import 'package:movera_rider/features/reservations/domain/reservation.dart';
import 'package:movera_rider/features/reservations/presentation/plan_return_ride.dart';
import 'package:movera_rider/features/reservations/presentation/reservation_edit_sheets.dart';
import 'package:movera_rider/features/reservations/presentation/reservation_format.dart';
import 'package:movera_rider/features/reservations/presentation/reservation_widgets.dart';
import 'package:movera_rider/features/reservations/presentation/ride_scheduled.dart';
import 'package:movera_rider/features/reservations/presentation/scheduled_ride_terms.dart';
import 'package:movera_rider/features/scheduled_rides/presentation/schedule_ride.dart';
import 'package:movera_rider/shared/widgets/navigation_transition.dart';

class UpcomingReservationPage extends StatefulWidget {
  const UpcomingReservationPage({
    super.key,
    required this.reservationId,
    this.controller,
  });

  final String reservationId;
  final ReservationController? controller;

  @override
  State<UpcomingReservationPage> createState() =>
      _UpcomingReservationPageState();
}

class _UpcomingReservationPageState extends State<UpcomingReservationPage> {
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

  Future<void> _editReservation(Reservation ride) async {
    if (!ride.status.canEdit) return;
    await Navigator.push(
      context,
      BottomToTopTransition(ScheduleRide(editing: ride)),
    );
  }

  Future<void> _cancel(Reservation ride) async {
    final outcome = await showCancelReservationFlow(context, ride);
    if (!outcome.cancelled) return;
    await _reservations.cancel(ride.reservationId, reason: outcome.reasonId);
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
    final policy = _reservations.policy;
    final top = MediaQuery.paddingOf(context).top;
    if (ride == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Text('Reservation not found', style: reservationText(16)),
        ),
      );
    }
    final assigned = ride.driverAssigned;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          SizedBox(height: top + 4),
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  Icons.arrow_back_rounded,
                  color: kReservationInk,
                ),
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
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                Text(
                  ride.status.isCancelled
                      ? 'Cancelled reservation'
                      : 'Upcoming ride',
                  style: reservationText(
                    28,
                    weight: FontWeight.w700,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  ReservationFormat.reservedHeadline(ride.scheduledPickupAt),
                  style: reservationText(
                    13.5,
                    color: kReservationMuted,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 22),
                _HeroCard(ride: ride),
                const SizedBox(height: 16),
                ReservationStatusBanner(
                  title: ReservationFormat.statusTitle(ride),
                  body: ReservationFormat.statusBody(
                    ride,
                    assignmentDisclaimer: policy.assignmentDisclaimer,
                  ),
                  positive: !ride.status.isCancelled,
                ),
                if (assigned && ride.driver != null) ...[
                  const SizedBox(height: 14),
                  _DriverCard(driver: ride.driver!),
                ],
                const SizedBox(height: 22),
                _JourneyCard(ride: ride),
                if (ride.hasPreferences) ...[
                  const SizedBox(height: 12),
                  _DetailRow(
                    iconAsset: AppAssets.note,
                    label: 'Preferences',
                    value: ride.note!.trim(),
                  ),
                ],
                if (ride.status.canEdit) ...[
                  const SizedBox(height: 22),
                  ReservationEditButton(onTap: () => _editReservation(ride)),
                  const SizedBox(height: 22),
                  Text(
                    'Need another ride?',
                    style: reservationText(18, weight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  Material(
                    color: kReservationSoft,
                    borderRadius: BorderRadius.circular(18),
                    child: InkWell(
                      onTap: () => _planReturn(ride),
                      borderRadius: BorderRadius.circular(18),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
                        child: Row(
                          children: [
                            const MoveraGlyph(
                              asset: AppAssets.scheduleCalendar,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Plan a return ride',
                                    style: reservationText(
                                      15,
                                      weight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    'Choose category, then confirm a new reservation',
                                    style: reservationText(
                                      12.5,
                                      color: kReservationMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: kReservationMuted,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    'Things to know',
                    style: reservationText(18, weight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  _KnowRow(
                    asset: AppAssets.hourGlass,
                    title: 'Waiting time',
                    body: policy.waitingSummary,
                  ),
                  _KnowRow(
                    asset: AppAssets.cancelation,
                    title: 'Cancellation',
                    body: policy.cancellationSummary,
                  ),
                  _KnowRow(
                    asset: AppAssets.totalAmount,
                    title: 'Pricing',
                    body: policy.pricingSummary,
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => ScheduledRideTermsPage.open(
                      context,
                      controller: _reservations,
                    ),
                    child: Text(
                      'View scheduled ride terms',
                      style: reservationText(
                        14.5,
                        weight: FontWeight.w600,
                        color: kReservationAccent,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: TextButton(
                      onPressed: () => _cancel(ride),
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
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.ride});

  final Reservation ride;

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
      child: Row(
        children: [
          SizedBox(
            width: 88,
            height: 56,
            child: Image.asset(
              ride.categoryImage,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Image.asset(
                AppAssets.scheduleRideCar,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.directions_car_filled_rounded,
                  size: 36,
                  color: kReservationAccent,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ride.categoryName,
                  style: reservationText(18, weight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  '${ride.passengerCount} seats  ·  ${ride.paymentMethod}',
                  style: reservationText(12.5, color: kReservationMuted),
                ),
              ],
            ),
          ),
          Text(
            ReservationFormat.price(ride),
            style: reservationText(16, weight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _JourneyCard extends StatelessWidget {
  const _JourneyCard({required this.ride});

  final Reservation ride;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
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
          _DetailRow(
            iconAsset: AppAssets.dateTime,
            label: 'Scheduled for',
            value:
                '${ReservationFormat.longDate(ride.scheduledPickupAt)}, ${ReservationFormat.time(ride.scheduledPickupAt)}',
            caption: ride.estimatedDropoffAt == null
                ? null
                : ReservationFormat.dropoffAt(ride.estimatedDropoffAt!),
          ),
          const Divider(height: 1, indent: 52, color: kReservationLine),
          _DetailRow(
            iconAsset: AppAssets.gpsFill,
            label: 'Pickup at',
            value: ride.pickup.label,
            caption: ride.pickup.subtitle,
          ),
          const Divider(height: 1, indent: 52, color: kReservationLine),
          _DetailRow(
            iconAsset: AppAssets.locationFill,
            label: 'Dropoff at',
            value: ride.destination.label,
            caption: ride.destination.subtitle,
          ),
          const Divider(height: 1, indent: 52, color: kReservationLine),
          _DetailRow(
            paymentMethod: ride.paymentMethod,
            label: 'Payment method',
            value: ride.paymentMethod,
          ),
        ],
      ),
    );
  }
}

class _DriverCard extends StatelessWidget {
  const _DriverCard({required this.driver});

  final ReservationDriver driver;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: kReservationLine),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: kReservationSoft,
            backgroundImage: driver.photoAsset == null
                ? null
                : AssetImage(driver.photoAsset!),
            child: driver.photoAsset == null
                ? Text(
                    driver.firstName.substring(0, 1).toUpperCase(),
                    style: reservationText(18, weight: FontWeight.w700),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  driver.firstName,
                  style: reservationText(16, weight: FontWeight.w700),
                ),
                if (driver.vehicle != null)
                  Text(
                    driver.vehicle!,
                    style: reservationText(13, color: kReservationMuted),
                  ),
                if (driver.plate != null)
                  Text(
                    driver.plate!,
                    style: reservationText(13, color: kReservationMuted),
                  ),
              ],
            ),
          ),
          if (driver.rating != null)
            Text(
              driver.rating!.toStringAsFixed(2),
              style: reservationText(14, weight: FontWeight.w600),
            ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.iconAsset,
    this.paymentMethod,
    this.caption,
  });

  final String? iconAsset;
  final String? paymentMethod;
  final String label;
  final String value;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final mark = paymentMethod != null
        ? ReservationPaymentMark(method: paymentMethod!)
        : MoveraGlyph(asset: iconAsset ?? AppAssets.note);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          mark,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: reservationText(12.5, color: kReservationMuted),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: reservationText(16, weight: FontWeight.w600),
                ),
                if (caption != null && caption!.isNotEmpty)
                  Text(
                    caption!,
                    style: reservationText(13, color: kReservationMuted),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _KnowRow extends StatelessWidget {
  const _KnowRow({
    required this.asset,
    required this.title,
    required this.body,
  });

  final String asset;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
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
                  title,
                  style: reservationText(14.5, weight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: reservationText(
                    13,
                    color: kReservationMuted,
                    height: 1.4,
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
