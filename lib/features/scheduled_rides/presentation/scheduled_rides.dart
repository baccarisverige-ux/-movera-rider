import 'package:flutter/material.dart';
import 'package:movera_rider/app/di.dart';
import 'package:movera_rider/features/reservations/application/reservation_controller.dart';
import 'package:movera_rider/features/reservations/presentation/reservation_widgets.dart';
import 'package:movera_rider/features/reservations/presentation/upcoming_reservation.dart';
import 'package:movera_rider/features/scheduled_rides/presentation/schedule_ride.dart';
import 'package:movera_rider/shared/design_system/movera_empty_state.dart';
import 'package:movera_rider/shared/widgets/navigation_transition.dart';

export 'package:movera_rider/features/scheduled_rides/presentation/schedule_ride.dart';

/// Rider-facing management surface for reservations that are still upcoming.
///
/// Completed and cancelled reservations remain in Ride History. This page only
/// shows the current reservations the Rider can still manage.
class ScheduledRides extends StatefulWidget {
  const ScheduledRides({super.key, this.controller});

  final ReservationController? controller;

  @override
  State<ScheduledRides> createState() => _ScheduledRidesState();
}

class _ScheduledRidesState extends State<ScheduledRides> {
  static const _ink = Color(0xFF1D252C);
  static const _muted = Color(0xFF5C656C);
  static const _line = Color(0xFFE7EBEE);
  static const _cta = Color(0xFF11181D);

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

  Future<void> _openSchedule() async {
    await Navigator.push(
      context,
      BottomToTopTransition(const ScheduleRide()),
    );
  }

  Future<void> _openReservation(String reservationId) async {
    await Navigator.push(
      context,
      RightToLeftTransition(
        UpcomingReservationPage(
          reservationId: reservationId,
          controller: _reservations,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final upcoming = _reservations.upcoming();
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 4),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    tooltip: 'Back',
                    icon: const Icon(Icons.arrow_back_rounded, color: _ink),
                  ),
                  const Spacer(),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 6, 20, 4),
              child: Text(
                'Scheduled rides',
                style: TextStyle(
                  color: _ink,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.7,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Text(
                'View and manage rides you booked for later.',
                style: TextStyle(
                  color: _muted,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
            ),
            const Divider(height: 1, color: _line),
            Expanded(
              child: upcoming.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: MoveraEmptyState(
                          icon: Icons.event_available_outlined,
                          title: 'No scheduled rides',
                          message:
                              'Rides you book for later will appear here until they are completed or cancelled.',
                          actionLabel: 'Schedule a ride',
                          onAction: _openSchedule,
                        ),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                      children: [
                        for (final ride in upcoming)
                          ReservationHistoryCard(
                            ride: ride,
                            onTap: () =>
                                _openReservation(ride.reservationId),
                          ),
                      ],
                    ),
            ),
            if (upcoming.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                child: SafeArea(
                  top: false,
                  child: SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton(
                      onPressed: _openSchedule,
                      style: FilledButton.styleFrom(
                        backgroundColor: _cta,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(27),
                        ),
                      ),
                      child: const Text(
                        'Schedule another ride',
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
