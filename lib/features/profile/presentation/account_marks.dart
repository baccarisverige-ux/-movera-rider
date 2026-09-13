import 'package:flutter/material.dart';
import 'package:movera_rider/core/constants/appcolors.dart';
import 'package:movera_rider/features/profile/presentation/account_widgets.dart';

class AccountMarks {
  static const person = 'assets/icons/safety_mark_contacts.png';
  static const shield = 'assets/icons/safety_mark_shield.png';
  static const lock = 'assets/icons/safety_mark_protect.png';
  static const pin = 'assets/icons/safety_mark_pin.png';
  static const share = 'assets/icons/safety_mark_share.png';
  static const check = 'assets/icons/safety_mark_ridecheck.png';
  static const tips = 'assets/icons/safety_mark_tips.png';
}

class AccountMarkWell extends StatelessWidget {
  const AccountMarkWell(this.asset, {super.key, this.size = 52});

  final String asset;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kAccountLine),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        asset,
        width: size - 10,
        height: size - 10,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      ),
    );
  }
}

enum AccountLine { phone, mail, globe, document, headset, key, device, bell }

class AccountLineWell extends StatelessWidget {
  const AccountLineWell(this.kind, {super.key, this.size = 52});

  final AccountLine kind;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kAccountLine),
      ),
      child: CustomPaint(painter: _AccountLinePainter(kind)),
    );
  }
}

class _AccountLinePainter extends CustomPainter {
  const _AccountLinePainter(this.kind);

  final AccountLine kind;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColor.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final c = Offset(size.width / 2, size.height / 2);
    switch (kind) {
      case AccountLine.phone:
        final rect = RRect.fromRectAndRadius(
          Rect.fromCenter(center: c, width: 16, height: 26),
          const Radius.circular(4),
        );
        canvas.drawRRect(rect, paint);
        canvas.drawLine(
          Offset(c.dx - 3, c.dy + 10),
          Offset(c.dx + 3, c.dy + 10),
          paint,
        );
      case AccountLine.mail:
        final rect = RRect.fromRectAndRadius(
          Rect.fromCenter(center: c, width: 24, height: 16),
          const Radius.circular(3),
        );
        canvas.drawRRect(rect, paint);
        final path = Path()
          ..moveTo(c.dx - 12, c.dy - 8)
          ..lineTo(c.dx, c.dy + 1)
          ..lineTo(c.dx + 12, c.dy - 8);
        canvas.drawPath(path, paint);
      case AccountLine.globe:
        canvas.drawCircle(c, 11, paint);
        canvas.drawOval(
          Rect.fromCenter(center: c, width: 10, height: 22),
          paint,
        );
        canvas.drawLine(
          Offset(c.dx - 11, c.dy),
          Offset(c.dx + 11, c.dy),
          paint,
        );
      case AccountLine.document:
        final rect = RRect.fromRectAndRadius(
          Rect.fromCenter(center: c.translate(0, 1), width: 18, height: 24),
          const Radius.circular(3),
        );
        canvas.drawRRect(rect, paint);
        canvas.drawLine(
          Offset(c.dx - 5, c.dy - 4),
          Offset(c.dx + 5, c.dy - 4),
          paint,
        );
        canvas.drawLine(
          Offset(c.dx - 5, c.dy + 1),
          Offset(c.dx + 5, c.dy + 1),
          paint,
        );
        canvas.drawLine(
          Offset(c.dx - 5, c.dy + 6),
          Offset(c.dx + 2, c.dy + 6),
          paint,
        );
      case AccountLine.headset:
        final arc = Path()
          ..addArc(
            Rect.fromCircle(center: c.translate(0, -2), radius: 10),
            3.4,
            5.6,
          );
        canvas.drawPath(arc, paint);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(c.dx - 10, c.dy + 4),
              width: 6,
              height: 10,
            ),
            const Radius.circular(2),
          ),
          paint,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(c.dx + 10, c.dy + 4),
              width: 6,
              height: 10,
            ),
            const Radius.circular(2),
          ),
          paint,
        );
      case AccountLine.key:
        canvas.drawCircle(Offset(c.dx - 5, c.dy), 6, paint);
        canvas.drawLine(Offset(c.dx + 1, c.dy), Offset(c.dx + 12, c.dy), paint);
        canvas.drawLine(
          Offset(c.dx + 8, c.dy),
          Offset(c.dx + 8, c.dy + 5),
          paint,
        );
        canvas.drawLine(
          Offset(c.dx + 11, c.dy),
          Offset(c.dx + 11, c.dy + 3),
          paint,
        );
      case AccountLine.device:
        final rect = RRect.fromRectAndRadius(
          Rect.fromCenter(center: c, width: 14, height: 24),
          const Radius.circular(3.5),
        );
        canvas.drawRRect(rect, paint);
        canvas.drawCircle(
          Offset(c.dx, c.dy + 9),
          1.2,
          paint..style = PaintingStyle.fill,
        );
      case AccountLine.bell:
        final path = Path()
          ..moveTo(c.dx - 8, c.dy + 2)
          ..quadraticBezierTo(c.dx - 8, c.dy - 10, c.dx, c.dy - 10)
          ..quadraticBezierTo(c.dx + 8, c.dy - 10, c.dx + 8, c.dy + 2)
          ..lineTo(c.dx + 10, c.dy + 6)
          ..lineTo(c.dx - 10, c.dy + 6)
          ..close();
        canvas.drawPath(path, paint);
        canvas.drawArc(
          Rect.fromCircle(center: Offset(c.dx, c.dy + 6), radius: 3),
          0,
          3.14,
          false,
          paint,
        );
    }
  }

  @override
  bool shouldRepaint(covariant _AccountLinePainter oldDelegate) =>
      oldDelegate.kind != kind;
}
