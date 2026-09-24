import 'dart:async';

import 'package:flutter/material.dart';
import 'package:movera_rider/app/di.dart';
import 'package:movera_rider/app/router/home_history_observer.dart';
import 'package:movera_rider/core/constants/appassets.dart';
import 'package:movera_rider/features/reservations/application/reservation_controller.dart';
import 'package:movera_rider/features/reservations/domain/reservation.dart';
import 'package:movera_rider/features/reservations/presentation/plan_return_ride.dart';
import 'package:movera_rider/features/reservations/presentation/reservation_edit_sheets.dart';
import 'package:movera_rider/features/reservations/presentation/reservation_format.dart';
import 'package:movera_rider/features/reservations/presentation/reservation_live_ride.dart';
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
  bool _handedOff = false;

  @override
  void initState() {
    super.initState();
    _reservations = widget.controller ?? AppScope.instance.reservations;
    _reservations.addListener(_refresh);
    moveraNavigationEpoch.addListener(_onNavigationChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _handoffIfLive());
  }

  @override
  void dispose() {
    moveraNavigationEpoch.removeListener(_onNavigationChanged);
    _reservations.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
    _handoffIfLive();
  }

  bool get _routeIsCurrent => ModalRoute.of(context)?.isCurrent ?? true;

  void _onNavigationChanged() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_routeIsCurrent) return;
      _handoffIfLive();
    });
  }

  void _handoffIfLive() {
    final ride = _reservations.byId(widget.reservationId);
    if (ride == null ||
        !ride.revealsDriver ||
        _handedOff ||
        !mounted ||
        !_routeIsCurrent) {
      return;
    }
    _handedOff = true;
    unawaited(_openLiveRide(ride));
  }

  Future<void> _openLiveRide(Reservation ride) async {
    if (!mounted || !_routeIsCurrent) {
      _handedOff = false;
      return;
    }
    await ReservationLiveRide.open(
      context,
      ride,
      controller: _reservations,
    );
    if (!mounted) return;
    _handedOff = false;
    _handoffIfLive();
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
                tooltip: 'Back',
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
                const SizedBox(height: 18),
                ReservationHeroArt(asset: ride.categoryImage, height: 100),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ride.categoryName,
                            style: reservationText(20, weight: FontWeight.w700),
                          ),
                          Text(
                            '${ride.passengerCount} seats  ·  ${ride.paymentMethod}',
                            style: reservationText(
                              12.5,
                              color: kReservationMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      ReservationFormat.price(ride),
                      style: reservationText(18, weight: FontWeight.w700),
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
                if (ride.revealsDriver && ride.driver != null) ...[
                  const SizedBox(height: 14),
                  ReservationDriverCard(driver: ride.driver!),
                ] else if (ride.driverAssigned) ...[
                  const SizedBox(height: 14),
                  Text(
                    'Driver details appear when your driver is on the way.',
                    style: reservationText(
                      13,
                      color: kReservationMuted,
                      height: 1.4,
                    ),
                  ),
                ],
                const SizedBox(height: 22),
                ReservationFact(
                  asset: AppAssets.scheduleCalendar,
                  label: 'Scheduled for',
                  value:
                      '${ReservationFormat.longDate(ride.scheduledPickupAt)}, ${ReservationFormat.time(ride.scheduledPickupAt)}',
                ),
                ReservationFact(
                  asset: AppAssets.gps,
                  label: 'Pickup at',
                  value: ride.pickup.label,
                ),
                ReservationFact(
                  asset: AppAssets.location,
                  label: 'Drop-off at',
                  value: ride.destination.label,
                ),
                ReservationFact(
                  asset: AppAssets.payment,
                  label: 'Payment method',
                  value: ride.paymentMethod,
                  trailing: ReservationPaymentMark(method: ride.paymentMethod),
                ),
                if (ride.hasPreferences) ...[
                  const SizedBox(height: 12),
                  ReservationFact(
                    asset: AppAssets.note,
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
                            Image.asset(
                              AppAssets.calender,
                              width: 44,
                              height: 44,
                              fit: BoxFit.contain,
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
                  _KnowCard(
                    waiting: policy.waitingSummary,
                    cancellation: policy.cancellationSummary,
                    pricing: policy.pricingSummary,
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

class ReservationDriverCard extends StatelessWidget {
  const ReservationDriverCard({super.key, required this.driver});

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
                ? (driver.initial.isEmpty
                      ? const Icon(
                          Icons.person_outline_rounded,
                          size: 20,
                          color: kReservationMuted,
                        )
                      : Text(
                          driver.initial,
                          style: reservationText(
                            18,
                            weight: FontWeight.w700,
                          ),
                        ))
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  driver.displayFirstName,
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

class _KnowCard extends StatelessWidget {
  const _KnowCard({
    required this.waiting,
    required this.cancellation,
    required this.pricing,
  });

  final String waiting;
  final String cancellation;
  final String pricing;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: kReservationLine),
      ),
      child: Column(
        children: [
          _KnowItem(index: '01', title: 'Waiting time', body: waiting),
          const Divider(
            height: 1,
            indent: 20,
            endIndent: 20,
            color: kReservationLine,
          ),
          _KnowItem(index: '02', title: 'Cancellation', body: cancellation),
          const Divider(
            height: 1,
            indent: 20,
            endIndent: 20,
            color: kReservationLine,
          ),
          _KnowItem(index: '03', title: 'Pricing', body: pricing),
        ],
      ),
    );
  }
}

class _KnowItem extends StatelessWidget {
  const _KnowItem({
    required this.index,
    required this.title,
    required this.body,
  });

  final String index;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 28,
            child: Text(
              index,
              style: reservationText(
                12,
                weight: FontWeight.w600,
                color: kReservationAccent,
                letterSpacing: 0.4,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: reservationText(
                    11,
                    weight: FontWeight.w600,
                    color: kReservationInk,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  body,
                  style: reservationText(
                    13,
                    color: kReservationMuted,
                    height: 1.45,
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
