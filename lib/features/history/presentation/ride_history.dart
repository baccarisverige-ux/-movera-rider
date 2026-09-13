import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movera_rider/app/di.dart';
import 'package:movera_rider/features/reservations/application/reservation_controller.dart';
import 'package:movera_rider/features/reservations/domain/reservation.dart';
import 'package:movera_rider/features/reservations/presentation/reservation_widgets.dart';
import 'package:movera_rider/features/reservations/presentation/upcoming_reservation.dart';
import 'package:movera_rider/features/ride_history/application/ride_history_controller.dart';
import 'package:movera_rider/features/ride_history/domain/ride_history.dart';
import 'package:movera_rider/features/scheduled_rides/presentation/schedule_ride.dart';
import 'package:movera_rider/shared/widgets/navigation_transition.dart';
import 'package:movera_rider/shared/design_system/movera_sheet.dart';

class RideHistory extends StatefulWidget {
  const RideHistory({super.key, this.reservations});

  final ReservationController? reservations;

  @override
  State<RideHistory> createState() => _RideHistoryState();
}

class _RideHistoryState extends State<RideHistory> {
  static const Color _ink = Color(0xFF1D252C);
  static const Color _muted = Color(0xFF778189);
  static const Color _line = Color(0xFFE7EBEE);
  static const Color _accent = Color(0xFF2D5878);
  static const Color _cta = Color(0xFF11181D);
  final List<RideHistoryItem> _past = RideHistoryController().past();
  late final ReservationController _reservations;

  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _reservations = widget.reservations ?? AppScope.instance.reservations;
    _reservations.addListener(_onReservations);
  }

  @override
  void dispose() {
    _reservations.removeListener(_onReservations);
    super.dispose();
  }

  void _onReservations() {
    if (mounted) setState(() {});
  }

  TextStyle _text(
    double size, {
    FontWeight weight = FontWeight.w400,
    Color color = _ink,
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

  String _priceLabel(RideHistoryItem ride) {
    if (ride.cancelled) return 'kr 0 · Cancelled';
    return 'kr ${ride.price.toStringAsFixed(0)}';
  }

  String _whenLabel(DateTime when) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final hour = when.hour % 12 == 0 ? 12 : when.hour % 12;
    final minute = when.minute.toString().padLeft(2, '0');
    final ampm = when.hour >= 12 ? 'PM' : 'AM';
    return '${months[when.month - 1]} ${when.day} · $hour:$minute $ampm';
  }

  String _monthTitle(DateTime when) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[when.month - 1]} ${when.year}';
  }

  void _openSchedule() {
    Navigator.push(context, BottomToTopTransition(const ScheduleRide()));
  }

  void _showHowItWorks() {
    MoveraSheet.show<void>(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _line,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Scheduled rides',
                style: _text(20, weight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              Text(
                'Pick a time in advance, lock in your fare, and a driver will meet you when you need to leave.',
                style: _text(14, color: _muted, height: 1.45),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _openSchedule();
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: _cta,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                  ),
                  child: Text(
                    'Schedule a ride',
                    style: _text(
                      16,
                      weight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: top + 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_rounded, color: _ink),
                ),
                const Spacer(),
                IconButton(
                  onPressed: _showHowItWorks,
                  icon: const Icon(Icons.info_outline_rounded, color: _ink),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Text(
              'Rides',
              style: _text(34, weight: FontWeight.w700, letterSpacing: -0.8),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                _tabLabel('Upcoming', 0),
                _tabLabel('Completed', 1),
                _tabLabel('Cancelled', 2),
              ],
            ),
          ),
          const Divider(height: 1, color: _line),
          Expanded(
            child: _tab == 0
                ? _upcoming()
                : _tab == 1
                ? _completedList()
                : _cancelledList(),
          ),
        ],
      ),
    );
  }

  Widget _tabLabel(String label, int index) {
    final selected = _tab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tab = index),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 10, top: 6),
              child: Text(
                label,
                style: _text(
                  15,
                  weight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected ? _ink : _muted,
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 3,
              width: selected ? 36 : 0,
              decoration: BoxDecoration(
                color: _accent,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _upcoming() {
    final upcoming = _reservations.upcoming();
    if (upcoming.isEmpty) return _emptyUpcoming();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
      children: [
        for (final ride in upcoming)
          ReservationHistoryCard(
            ride: ride,
            onTap: () {
              Navigator.push(
                context,
                RightToLeftTransition(
                  UpcomingReservationPage(
                    reservationId: ride.reservationId,
                    controller: _reservations,
                  ),
                ),
              );
            },
          ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: OutlinedButton(
            onPressed: _openSchedule,
            style: OutlinedButton.styleFrom(
              foregroundColor: _ink,
              side: const BorderSide(color: _line),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            child: Text(
              'Schedule a ride',
              style: _text(16, weight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  Widget _emptyUpcoming() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        children: [
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 140,
            child: Image.asset(
              'assets/images/schedule_timeline_exact_v3.png',
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 28),
          Text('No upcoming rides', style: _text(22, weight: FontWeight.w700)),
          const SizedBox(height: 10),
          Text(
            'Whatever is on your schedule, a Scheduled Ride can get you there on time',
            textAlign: TextAlign.center,
            style: _text(14.5, color: _muted, height: 1.45),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _showHowItWorks,
            child: Text(
              'Learn how it works',
              style: _text(15, weight: FontWeight.w600, color: _accent),
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton(
              onPressed: _openSchedule,
              style: FilledButton.styleFrom(
                backgroundColor: _cta,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: Text(
                'Schedule a ride',
                style: _text(
                  16.5,
                  weight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _completedList() {
    return _mixedHistory(
      reservations: _reservations.completed(),
      past: _past.where((ride) => !ride.cancelled).toList(),
    );
  }

  Widget _cancelledList() {
    return _mixedHistory(
      reservations: _reservations.cancelled(),
      past: _past.where((ride) => ride.cancelled).toList(),
    );
  }

  Widget _mixedHistory({
    required List<Reservation> reservations,
    required List<RideHistoryItem> past,
  }) {
    if (reservations.isEmpty && past.isEmpty) {
      return Center(
        child: Text('Nothing here yet', style: _text(15, color: _muted)),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
      children: [
        for (final ride in reservations)
          ReservationHistoryCard(
            ride: ride,
            onTap: () {
              Navigator.push(
                context,
                RightToLeftTransition(
                  UpcomingReservationPage(
                    reservationId: ride.reservationId,
                    controller: _reservations,
                  ),
                ),
              );
            },
          ),
        if (past.isNotEmpty) ...[
          if (reservations.isNotEmpty) const SizedBox(height: 12),
          ..._pastListChildren(past),
        ],
      ],
    );
  }

  List<Widget> _pastListChildren(List<RideHistoryItem> past) {
    final featured = past.where((ride) => ride.featured).toList();
    final rest = past.where((ride) => !ride.featured).toList();
    final grouped = <String, List<RideHistoryItem>>{};
    for (final ride in rest) {
      grouped.putIfAbsent(_monthTitle(ride.when), () => []).add(ride);
    }
    return [
      if (featured.isNotEmpty) ...[
        _featuredCard(featured.first),
        const SizedBox(height: 28),
      ],
      for (final entry in grouped.entries) ...[
        Text(entry.key, style: _text(18, weight: FontWeight.w700)),
        const SizedBox(height: 8),
        for (final ride in entry.value) _rideRow(ride),
        const SizedBox(height: 18),
      ],
    ];
  }

  Widget _featuredCard(RideHistoryItem ride) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 148,
            width: double.infinity,
            child: CustomPaint(painter: _MiniRoutePainter()),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ride.title, style: _text(18, weight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(_whenLabel(ride.when), style: _text(13.5, color: _muted)),
                const SizedBox(height: 2),
                Text(_priceLabel(ride), style: _text(13.5, color: _muted)),
                const SizedBox(height: 14),
                _rebookChip(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _rideRow(RideHistoryItem ride) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F5),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(6),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.asset(
                    ride.image,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Icon(
                      ride.cancelled
                          ? Icons.no_crash_outlined
                          : Icons.directions_car_filled_rounded,
                      color: _muted,
                    ),
                  ),
                ),
                if (ride.cancelled)
                  const Align(
                    alignment: Alignment.topRight,
                    child: Icon(Icons.schedule, size: 14, color: _ink),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ride.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: _text(15, weight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  ride.cancelled
                      ? '${_whenLabel(ride.when)} · Cancelled'
                      : _whenLabel(ride.when),
                  style: _text(12.5, color: _muted),
                ),
                Text(_priceLabel(ride), style: _text(12.5, color: _muted)),
              ],
            ),
          ),
          _rebookChip(),
        ],
      ),
    );
  }

  Widget _rebookChip() {
    return Material(
      color: const Color(0xFFF3F4F5),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: () => Navigator.pop(context),
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.replay_rounded, size: 16, color: _ink),
              const SizedBox(width: 6),
              Text('Rebook', style: _text(13, weight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniRoutePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final sky = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFDCE8DE), Color(0xFFEEF3E8)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, sky);

    final water = Paint()..color = const Color(0xFFC5D7E6);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.12,
          size.height * 0.18,
          size.width * 0.5,
          26,
        ),
        const Radius.circular(16),
      ),
      water,
    );

    final path = Path()
      ..moveTo(size.width * 0.16, size.height * 0.72)
      ..quadraticBezierTo(
        size.width * 0.46,
        size.height * 0.2,
        size.width * 0.86,
        size.height * 0.42,
      );
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF1D252C)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(
      Offset(size.width * 0.16, size.height * 0.72),
      7,
      Paint()..color = const Color(0xFF1D252C),
    );
    canvas.drawCircle(
      Offset(size.width * 0.16, size.height * 0.72),
      3.2,
      Paint()..color = Colors.white,
    );
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(size.width * 0.86, size.height * 0.42),
        width: 11,
        height: 11,
      ),
      Paint()..color = const Color(0xFF1D252C),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
