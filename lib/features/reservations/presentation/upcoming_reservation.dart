import 'package:flutter/material.dart';
import 'package:movera_rider/app/di.dart';
import 'package:movera_rider/features/reservations/application/reservation_controller.dart';
import 'package:movera_rider/features/reservations/domain/reservation.dart';
import 'package:movera_rider/features/reservations/presentation/plan_return_ride.dart';
import 'package:movera_rider/features/reservations/presentation/reservation_edit_sheets.dart';
import 'package:movera_rider/features/reservations/presentation/reservation_format.dart';
import 'package:movera_rider/features/reservations/presentation/reservation_widgets.dart';
import 'package:movera_rider/features/reservations/presentation/ride_scheduled.dart';
import 'package:movera_rider/features/reservations/presentation/scheduled_ride_terms.dart';
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

  Future<void> _editTime(Reservation ride) async {
    if (!ride.status.canEdit) return;
    final next = await showReservationTimeSheet(
      context,
      initial: ride.scheduledPickupAt,
    );
    if (next == null) return;
    final dropoff = ride.estimatedDropoffAt == null
        ? null
        : next.add(ride.estimatedDropoffAt!.difference(ride.scheduledPickupAt));
    await _reservations.update(
      ride.reservationId,
      ReservationPatch(scheduledPickupAt: next, estimatedDropoffAt: dropoff),
    );
  }

  Future<void> _editPickup(Reservation ride) async {
    if (!ride.status.canEdit) return;
    final next = await showReservationPlaceSheet(
      context,
      title: 'Pickup',
      current: ride.pickup,
    );
    if (next == null) return;
    await _reservations.update(
      ride.reservationId,
      ReservationPatch(pickup: next),
    );
  }

  Future<void> _editDestination(Reservation ride) async {
    if (!ride.status.canEdit) return;
    final next = await showReservationPlaceSheet(
      context,
      title: 'Destination',
      current: ride.destination,
    );
    if (next == null) return;
    await _reservations.update(
      ride.reservationId,
      ReservationPatch(destination: next),
    );
  }

  Future<void> _editPayment(Reservation ride) async {
    if (!ride.status.canEdit) return;
    final next = await showReservationPaymentSheet(
      context,
      current: ride.paymentMethod,
    );
    if (next == null) return;
    await _reservations.update(
      ride.reservationId,
      ReservationPatch(paymentMethod: next),
    );
  }

  Future<void> _cancel(Reservation ride) async {
    final outcome = await showCancelReservationFlow(context, ride);
    if (!outcome.cancelled) return;
    await _reservations.cancel(ride.reservationId, reason: outcome.reasonId);
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
                  ride.status.isCancelled
                      ? 'Cancelled reservation'
                      : 'Upcoming ride',
                  textAlign: TextAlign.center,
                  style: reservationText(16.5, weight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                ReservationRoutePreview(
                  pickup: ride.pickup.label,
                  destination: ride.destination.label,
                  height: 168,
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    SizedBox(
                      width: 64,
                      height: 40,
                      child: Image.asset(
                        ride.categoryImage,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.directions_car_filled_rounded),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${ride.categoryName}  ·  ${ride.passengerCount}',
                        style: reservationText(16, weight: FontWeight.w700),
                      ),
                    ),
                    Text(
                      ReservationFormat.price(ride),
                      style: reservationText(16, weight: FontWeight.w600),
                    ),
                  ],
                ),
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
                const SizedBox(height: 26),
                Text(
                  'Reservation details',
                  style: reservationText(20, weight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                _DetailRow(
                  icon: Icons.calendar_today_rounded,
                  label: 'Scheduled for',
                  value:
                      '${ReservationFormat.longDate(ride.scheduledPickupAt)}, ${ReservationFormat.time(ride.scheduledPickupAt)}',
                  caption: ride.estimatedDropoffAt == null
                      ? null
                      : ReservationFormat.dropoffAt(ride.estimatedDropoffAt!),
                  onEdit: ride.status.canEdit ? () => _editTime(ride) : null,
                ),
                _DetailRow(
                  icon: Icons.radio_button_checked,
                  label: 'Pickup at',
                  value: ride.pickup.label,
                  caption: ride.pickup.subtitle,
                  onEdit: ride.status.canEdit ? () => _editPickup(ride) : null,
                  connector: true,
                ),
                _DetailRow(
                  icon: Icons.crop_square_rounded,
                  label: 'Dropoff at',
                  value: ride.destination.label,
                  caption: ride.destination.subtitle,
                  onEdit: ride.status.canEdit
                      ? () => _editDestination(ride)
                      : null,
                ),
                _DetailRow(
                  icon: Icons.account_balance_wallet_outlined,
                  label: 'Payment method',
                  value: ride.paymentMethod,
                  onEdit: ride.status.canEdit ? () => _editPayment(ride) : null,
                ),
                if (ride.status.canEdit) ...[
                  const SizedBox(height: 18),
                  const Divider(color: kReservationLine),
                  const SizedBox(height: 8),
                  Text(
                    'Need another ride?',
                    style: reservationText(18, weight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.event_repeat_rounded,
                      color: kReservationAccent,
                    ),
                    title: Text(
                      'Plan a return ride',
                      style: reservationText(15, weight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      'Prefill the reverse route, then confirm',
                      style: reservationText(12.5, color: kReservationMuted),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _planReturn(ride),
                  ),
                  const Divider(color: kReservationLine),
                  const SizedBox(height: 16),
                  Text(
                    'Things to know',
                    style: reservationText(18, weight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  _KnowRow(
                    icon: Icons.hourglass_bottom_rounded,
                    title: 'Waiting time',
                    body: policy.waitingSummary,
                  ),
                  _KnowRow(
                    icon: Icons.event_busy_rounded,
                    title: 'Cancellation',
                    body: policy.cancellationSummary,
                  ),
                  _KnowRow(
                    icon: Icons.payments_outlined,
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
    required this.icon,
    required this.label,
    required this.value,
    this.caption,
    this.onEdit,
    this.connector = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? caption;
  final VoidCallback? onEdit;
  final bool connector;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 28,
            child: Column(
              children: [
                Icon(icon, size: 18, color: kReservationInk),
                if (connector)
                  Container(
                    width: 2,
                    height: 28,
                    margin: const EdgeInsets.only(top: 4),
                    color: kReservationLine,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
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
          if (onEdit != null) ReservationEditChip(onTap: onEdit!),
        ],
      ),
    );
  }
}

class _KnowRow extends StatelessWidget {
  const _KnowRow({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: kReservationInk),
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
