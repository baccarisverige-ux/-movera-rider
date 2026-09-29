import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movera_rider/features/auth/presentation/widgets/auth_style.dart';

/// The first-screen balloon becomes the multicolor "o" of Movera.
/// No second wordmark replaces it during the reveal.
class BalloonBrandIntro extends StatelessWidget {
  const BalloonBrandIntro({super.key, required this.progress});

  final Animation<double> progress;

  static double _phase(double value, double start, double end) =>
      ((value - start) / (end - start)).clamp(0.0, 1.0).toDouble();

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.of(context).disableAnimations;
    final brandStyle = GoogleFonts.poppins(
      fontSize: 37,
      height: 1,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.8,
      color: const Color(0xFF438D6A),
    );
    return Semantics(
      label: 'Movera. Moving to a new era.',
      child: ExcludeSemantics(
        child: SizedBox(
          height: 142,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 350),
              child: LayoutBuilder(
                builder: (context, constraints) => AnimatedBuilder(
                  animation: progress,
                  builder: (context, _) {
                    final time = reducedMotion ? 1.0 : progress.value;
                    final width = constraints.maxWidth;
                    final center = width / 2;
                    final rise = Curves.easeInOutCubic.transform(
                      _phase(time, 0.54, 0.78),
                    );
                    final originX = width * 0.72 - 16;
                    final targetX = center - 43;
                    final balloonX = originX + (targetX - originX) * rise;
                    final balloonY = 119 + (47 - 119) * rise;
                    final balloonOpacity = _phase(time, 0.51, 0.56);
                    final opening = Curves.easeOut.transform(
                      _phase(time, 0.77, 0.12),
                    );
                    final letters = Curves.easeIn.transform(
                      _phase(time, 0.79, 0.11),
                    );
                    final tagline = Curves.easeIn.transform(
                      _phase(time, 0.88, 0.10),
                    );
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned(
                          left: center - 80,
                          top: 43,
                          child: Opacity(
                            opacity: letters,
                            child: Text('M', style: brandStyle),
                          ),
                        ),
                        Positioned(
                          left: center - 10,
                          top: 43,
                          child: Opacity(
                            opacity: letters,
                            child: Text('vera', style: brandStyle),
                          ),
                        ),
                        Positioned(
                          left: balloonX,
                          top: balloonY,
                          child: Opacity(
                            opacity: balloonOpacity,
                            child: CustomPaint(
                              size: const Size(32, 42),
                              painter: _BalloonLetterPainter(opening),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          top: 98,
                          child: Opacity(
                            opacity: tagline,
                            child: Text(
                              'Moving to a new era.',
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              style: GoogleFonts.poppins(
                                fontSize: 24,
                                height: 1.2,
                                fontWeight: FontWeight.w500,
                                letterSpacing: -0.5,
                                color: AuthColors.deepGreen,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BalloonLetterPainter extends CustomPainter {
  const _BalloonLetterPainter(this.opening);

  final double opening;

  static const _colors = [
    Color(0xFF4285F4),
    Color(0xFFEA4335),
    Color(0xFFFBBC05),
    Color(0xFF34A853),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    const center = Offset(16, 16);
    const radius = 15.0;
    final rect = Rect.fromCircle(center: center, radius: radius);
    for (var i = 0; i < 4; i++) {
      canvas.drawArc(
        rect,
        -1.57079632679 + i * 1.57079632679,
        1.57079632679 + 0.015,
        true,
        Paint()..color = _colors[i],
      );
    }
    if (opening > 0) {
      canvas.drawCircle(
        center,
        7.6 * opening,
        Paint()..color = AuthColors.ground,
      );
    }
    if (opening < 1) {
      final string = Paint()
        ..color = AuthColors.muted.withValues(alpha: 1 - opening)
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke;
      canvas.drawPath(
        Path()
          ..moveTo(16, 31)
          ..quadraticBezierTo(19, 36, 16, 42),
        string,
      );
    }
  }

  @override
  bool shouldRepaint(_BalloonLetterPainter oldDelegate) =>
      oldDelegate.opening != opening;
}
