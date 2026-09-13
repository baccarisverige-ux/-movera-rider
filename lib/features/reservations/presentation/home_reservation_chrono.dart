import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movera_rider/app/di.dart';
import 'package:movera_rider/core/constants/appassets.dart';
import 'package:movera_rider/features/reservations/application/reservation_controller.dart';
import 'package:movera_rider/features/reservations/domain/reservation.dart';
import 'package:movera_rider/features/reservations/presentation/reservation_format.dart';
import 'package:movera_rider/features/reservations/presentation/upcoming_reservation.dart';
import 'package:movera_rider/shared/widgets/navigation_transition.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

/// Home reservation timer. White face, status on the ring only.
class HomeReservationChrono extends StatefulWidget {
  const HomeReservationChrono({super.key, this.controller, this.now});

  final ReservationController? controller;
  final DateTime Function()? now;

  static const ink = Color(0xFF172127);
  static const confirmed = Color(0xFF1F9D5B);
  static const searching = Color(0xFFE08A2A);

  @override
  State<HomeReservationChrono> createState() => _HomeReservationChronoState();
}

class _HomeReservationChronoState extends State<HomeReservationChrono> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  ReservationController get _reservations =>
      widget.controller ?? AppScope.instance.reservations;

  Reservation? _nextRide() {
    final upcoming = [..._reservations.upcoming()]
      ..sort((a, b) => a.scheduledPickupAt.compareTo(b.scheduledPickupAt));
    if (upcoming.isEmpty) return null;
    return upcoming.first;
  }

  DateTime get _now => widget.now?.call() ?? DateTime.now();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _reservations,
      builder: (context, _) {
        final ride = _nextRide();
        if (ride == null) return const SizedBox.shrink();
        final ring = ride.isSearchingDriver
            ? HomeReservationChrono.searching
            : HomeReservationChrono.confirmed;
        final parts = ReservationFormat.remainingParts(
          ride.scheduledPickupAt,
          now: _now,
        );
        final compact = ReservationFormat.remainingCompact(
          ride.scheduledPickupAt,
          now: _now,
        );
        return PointerInterceptor(
          child: Semantics(
            button: true,
            label: 'Reservation in $compact',
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  RightToLeftTransition(
                    UpcomingReservationPage(
                      reservationId: ride.reservationId,
                      controller: _reservations,
                    ),
                  ),
                );
              },
              child: SizedBox(
                width: 54,
                height: 54,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x24000000),
                        blurRadius: 18,
                        offset: Offset(0, 7),
                      ),
                    ],
                  ),
                  child: CustomPaint(
                    painter: _ChronoFace(ring: ring),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 7, 8, 6),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            AppAssets.scheduleRideCar,
                            height: 11,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) =>
                                const SizedBox(height: 11),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            parts.primary,
                            style: GoogleFonts.poppins(
                              fontSize: parts.secondary == null ? 13 : 11,
                              fontWeight: FontWeight.w700,
                              color: HomeReservationChrono.ink,
                              height: 1,
                            ),
                          ),
                          if (parts.secondary != null)
                            Text(
                              parts.secondary!,
                              style: GoogleFonts.poppins(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF6B757B),
                                height: 1.1,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ChronoFace extends CustomPainter {
  const _ChronoFace({required this.ring});

  final Color ring;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 1.2;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = ring
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    final tick = Paint()
      ..color = const Color(0x33172127)
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 12; i++) {
      final angle = (i / 12) * math.pi * 2 - math.pi / 2;
      final outer = radius - 3.2;
      final inner = radius - (i % 3 == 0 ? 6.4 : 4.6);
      canvas.drawLine(
        center + Offset(math.cos(angle), math.sin(angle)) * inner,
        center + Offset(math.cos(angle), math.sin(angle)) * outer,
        tick,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ChronoFace oldDelegate) =>
      oldDelegate.ring != ring;
}
