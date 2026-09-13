import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movera_rider/features/reservations/domain/reservation.dart';
import 'package:movera_rider/features/reservations/presentation/reservation_format.dart';

const Color kReservationInk = Color(0xFF172127);
const Color kReservationMuted = Color(0xFF7B858B);
const Color kReservationLine = Color(0xFFE4E7E8);
const Color kReservationCta = Color(0xFF11181D);
const Color kReservationAccent = Color(0xFF356879);
const Color kReservationSoft = Color(0xFFF5F6F6);

TextStyle reservationText(
  double size, {
  FontWeight weight = FontWeight.w400,
  Color color = kReservationInk,
  double? height,
  double? letterSpacing,
}) {
  return GoogleFonts.poppins(
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
  );
}

class ReservationRoutePreview extends StatelessWidget {
  const ReservationRoutePreview({
    super.key,
    required this.pickup,
    required this.destination,
    this.height = 148,
  });

  final String pickup;
  final String destination;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Stack(
          children: [
            const Positioned.fill(child: CustomPaint(painter: _MapPainter())),
            Positioned(
              left: 14,
              top: 16,
              child: _pinLabel(destination, filled: true),
            ),
            Positioned(
              left: 18,
              bottom: 18,
              child: _pinLabel(pickup, filled: false),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pinLabel(String text, {required bool filled}) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 210),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            filled ? Icons.square_rounded : Icons.circle,
            size: filled ? 10 : 9,
            color: kReservationCta,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: reservationText(11.5, weight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapPainter extends CustomPainter {
  const _MapPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFE8EEF2),
    );
    final water = Paint()..color = const Color(0xFFD3E4EE);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-20, 8, size.width * 0.46, size.height * 0.7),
        const Radius.circular(80),
      ),
      water,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.55,
          size.height * 0.45,
          size.width * 0.6,
          90,
        ),
        const Radius.circular(40),
      ),
      water,
    );
    final land = Paint()..color = const Color(0xFFF4F1EA);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.18,
          20,
          size.width * 0.7,
          size.height * 0.78,
        ),
        const Radius.circular(28),
      ),
      land,
    );
    final road = Paint()
      ..color = kReservationCta
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.4
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(28, size.height - 28)
      ..cubicTo(
        size.width * 0.28,
        size.height * 0.72,
        size.width * 0.42,
        size.height * 0.28,
        size.width - 36,
        28,
      );
    canvas.drawPath(path, road);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class MoveraReserveBadge extends StatelessWidget {
  const MoveraReserveBadge({super.key, required this.when});

  final DateTime when;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 10, 8),
      decoration: BoxDecoration(
        color: kReservationCta,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.event_available_rounded,
            size: 16,
            color: Colors.white,
          ),
          const SizedBox(width: 6),
          Text(
            ReservationFormat.time(when),
            style: reservationText(
              13,
              weight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class ReservationStatusBanner extends StatelessWidget {
  const ReservationStatusBanner({
    super.key,
    required this.title,
    required this.body,
    this.positive = true,
  });

  final String title;
  final String body;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    final tone = positive ? const Color(0xFFEAF2F8) : const Color(0xFFF4F5F6);
    final dot = positive ? kReservationAccent : kReservationMuted;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: tone,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
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

class ReservationDriverBadge extends StatelessWidget {
  const ReservationDriverBadge({super.key, required this.ride});

  final Reservation ride;

  @override
  Widget build(BuildContext context) {
    final assigned = ride.driverAssigned;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: assigned ? const Color(0xFFEAF2F8) : const Color(0xFFEEF1F3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        ReservationFormat.driverBadge(ride),
        style: reservationText(
          11.5,
          weight: FontWeight.w600,
          color: assigned ? kReservationAccent : kReservationMuted,
        ),
      ),
    );
  }
}

class ReservationHistoryCard extends StatelessWidget {
  const ReservationHistoryCard({
    super.key,
    required this.ride,
    required this.onTap,
  });

  final Reservation ride;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: kReservationLine),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 54,
                      height: 36,
                      child: Image.asset(
                        ride.categoryImage,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.directions_car_filled_rounded,
                          color: kReservationMuted,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        ride.categoryName,
                        style: reservationText(15, weight: FontWeight.w700),
                      ),
                    ),
                    Text(
                      ReservationFormat.price(ride),
                      style: reservationText(14, weight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  ReservationFormat.historyWhen(ride),
                  style: reservationText(13, color: kReservationMuted),
                ),
                const SizedBox(height: 4),
                Text(
                  '${ride.pickup.label} → ${ride.destination.label}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: reservationText(
                    13.5,
                    weight: FontWeight.w500,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 10),
                ReservationDriverBadge(ride: ride),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ReservationEditChip extends StatelessWidget {
  const ReservationEditChip({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Material(
        color: kReservationSoft,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Text(
                'Edit reservation',
                style: reservationText(13, weight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ReservationEditButton extends StatelessWidget {
  const ReservationEditButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: kReservationInk,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Text(
          'Edit reservation',
          style: reservationText(
            14.5,
            weight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
