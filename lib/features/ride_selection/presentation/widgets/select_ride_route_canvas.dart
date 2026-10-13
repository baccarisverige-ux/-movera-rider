import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:movera_rider/shared/styles/route_style.dart';

/// Painted stand-in for the Select Ride map while the live map is not
/// mounted yet or is parked behind a picker.
class SelectRideRouteCanvas extends StatelessWidget {
  const SelectRideRouteCanvas({super.key});

  @override
  Widget build(BuildContext context) {
    return const CustomPaint(
      painter: _RoutePainter(),
      child: SizedBox.expand(),
    );
  }
}

class _RoutePainter extends CustomPainter {
  const _RoutePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final sky = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFDCE8DE), Color(0xFFEEF3E8), Color(0xFFF6F5F1)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, sky);

    final water = Paint()
      ..color = const Color(0xFFC9D9D4).withValues(alpha: 0.7);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.08,
          size.height * 0.18,
          size.width * 0.38,
          28,
        ),
        const Radius.circular(20),
      ),
      water,
    );

    final land = Paint()..color = const Color(0xFFD7E3D4);
    canvas.drawCircle(Offset(size.width * 0.78, size.height * 0.42), 46, land);
    canvas.drawCircle(Offset(size.width * 0.22, size.height * 0.62), 34, land);

    final path = Path()
      ..moveTo(size.width * 0.16, size.height * 0.72)
      ..quadraticBezierTo(
        size.width * 0.42,
        size.height * 0.18,
        size.width * 0.84,
        size.height * 0.46,
      );
    final start = Offset(size.width * 0.16, size.height * 0.72);
    final end = Offset(size.width * 0.84, size.height * 0.46);
    canvas.drawPath(
      path,
      Paint()
        ..color = RiderRouteStyle.casing
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7.5
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(
      path,
      Paint()
        ..shader = ui.Gradient.linear(start, end, const [
          RiderRouteStyle.pickup,
          RiderRouteStyle.destination,
        ])
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round,
    );

    void pin(Offset c, Color color) {
      canvas.drawCircle(c, 9, Paint()..color = color);
      canvas.drawCircle(c, 4.2, Paint()..color = Colors.white);
    }

    pin(start, RiderRouteStyle.pickup);
    pin(end, RiderRouteStyle.destination);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
