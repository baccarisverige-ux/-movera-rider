import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movera_rider/app/di.dart';
import 'package:movera_rider/features/reservations/application/reservation_controller.dart';
import 'package:movera_rider/features/reservations/domain/reservation.dart';
import 'package:movera_rider/features/reservations/presentation/upcoming_reservation.dart';
import 'package:movera_rider/shared/widgets/navigation_transition.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

/// Home chrono badge. White button, status lives on the ring only.
class HomeReservationChrono extends StatelessWidget {
  const HomeReservationChrono({super.key, this.controller});

  final ReservationController? controller;

  static const _ink = Color(0xFF172127);
  static const _confirmed = Color(0xFF1F9D5B);
  static const _searching = Color(0xFFE08A2A);

  Reservation? _nextRide(ReservationController reservations) {
    final upcoming = [...reservations.upcoming()]
      ..sort((a, b) => a.scheduledPickupAt.compareTo(b.scheduledPickupAt));
    if (upcoming.isEmpty) return null;
    return upcoming.first;
  }

  @override
  Widget build(BuildContext context) {
    final reservations = controller ?? AppScope.instance.reservations;
    return ListenableBuilder(
      listenable: reservations,
      builder: (context, _) {
        final ride = _nextRide(reservations);
        if (ride == null) return const SizedBox.shrink();
        final ring = ride.isSearchingDriver ? _searching : _confirmed;
        return PointerInterceptor(
          child: Semantics(
            button: true,
            label: 'Chrono',
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  RightToLeftTransition(
                    UpcomingReservationPage(
                      reservationId: ride.reservationId,
                      controller: reservations,
                    ),
                  ),
                );
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: ring, width: 2),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x22000000),
                          blurRadius: 16,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.schedule_rounded,
                      size: 22,
                      color: _ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Chrono',
                    style: GoogleFonts.poppins(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: _ink,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
