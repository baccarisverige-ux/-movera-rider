import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Compact Rider location puck matching the Home map visual language.
class MoveraRiderPuckMarker {
  const MoveraRiderPuckMarker._();

  static Future<({BitmapDescriptor icon, ui.Image image})> createVisual({
    bool expanded = false,
  }) async {
    const width = 65.9;
    const height = 75.3;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..scale(0.588, 0.588);
    const center = Offset(56, 84);

    final beam = Path()
      ..moveTo(56, 80)
      ..lineTo(23, 18)
      ..quadraticBezierTo(56, 1, 89, 18)
      ..close();
    final beamPaint = Paint()
      ..shader = ui.Gradient.linear(const Offset(56, 4), center, [
        const Color(0x08747B80),
        const Color(0x35747B80),
      ]);
    canvas.drawPath(beam, beamPaint);
    canvas.drawCircle(
      center,
      expanded ? 31 : 25,
      Paint()..color = const Color(0x18747B80),
    );
    canvas.drawCircle(center, 20, Paint()..color = Colors.white);
    canvas.drawCircle(center, 15, Paint()..color = const Color(0xFF747B80));

    final image = await recorder.endRecording().toImage(
      width.toInt(),
      height.toInt(),
    );
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    // Never fall back to Google's default pin for the Rider location.
    // In the unlikely event PNG encoding fails, use an invisible descriptor
    // rather than flashing a red pin underneath the Movera puck.
    final icon = data == null
        ? BitmapDescriptor.bytes(
            base64Decode(
              'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
            ),
          )
        : BitmapDescriptor.bytes(data.buffer.asUint8List());
    return (icon: icon, image: image);
  }

  static Future<BitmapDescriptor> createIcon({bool expanded = false}) async {
    final visual = await createVisual(expanded: expanded);
    visual.image.dispose();
    return visual.icon;
  }
}

/// Same top-down Movera vehicle marker used by the Driver app.
///
/// Rider nearby-driver pins intentionally render at 65% of Driver's 48 px
/// marker, i.e. 35% smaller as requested.
class MoveraVehicleMarker {
  const MoveraVehicleMarker._();

  static Future<BitmapDescriptor> createIcon({double scale = 0.65}) async {
    const designSize = 96.0;
    final outputSize = 48.0 * scale;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.scale(outputSize / designSize);

    final shadowPaint = Paint()
      ..color = const Color(0x26000000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawOval(const Rect.fromLTWH(27, 68, 42, 10), shadowPaint);

    final bodyRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(31, 13, 34, 66),
      const Radius.circular(14),
    );
    final bodyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFFFFFFF),
          Color(0xFFF1F4F2),
          Color(0xFFC9D0CD),
        ],
        stops: [0.0, 0.55, 1.0],
      ).createShader(bodyRect.outerRect);
    canvas.drawRRect(bodyRect, bodyPaint);

    canvas.drawRRect(
      bodyRect,
      Paint()
        ..color = const Color(0xFF19865C)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(35, 23, 26, 18),
        const Radius.circular(6),
      ),
      Paint()..color = const Color(0xFF34464E),
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(36, 51, 24, 14),
        const Radius.circular(5),
      ),
      Paint()..color = const Color(0xFF536168),
    );

    final highlight = Paint()
      ..color = const Color(0xCCFFFFFF)
      ..strokeWidth = 1.7
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(35, 20), const Offset(35, 61), highlight);

    final wheelPaint = Paint()..color = const Color(0xFF222B2F);
    for (final rect in const [
      Rect.fromLTWH(27, 28, 5, 13),
      Rect.fromLTWH(64, 28, 5, 13),
      Rect.fromLTWH(27, 53, 5, 13),
      Rect.fromLTWH(64, 53, 5, 13),
    ]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(3)),
        wheelPaint,
      );
    }

    canvas.drawCircle(
      const Offset(48, 10),
      3.2,
      Paint()..color = const Color(0xFF19865C),
    );

    final image = await recorder.endRecording().toImage(
      outputSize.round(),
      outputSize.round(),
    );
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (data == null) {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
    }
    return BitmapDescriptor.fromBytes(data.buffer.asUint8List());
  }
}
