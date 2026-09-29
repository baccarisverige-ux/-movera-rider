import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movera_rider/features/auth/presentation/widgets/auth_style.dart';
import 'package:movera_rider/features/auth/presentation/widgets/movera_wordmark.dart';

/// A one-time welcome on the first sign-in step. Five small birds bring the
/// six letters of Movera together, then the brand lockup remains still.
class BirdWordmarkIntro extends StatefulWidget {
  const BirdWordmarkIntro({super.key});

  @override
  State<BirdWordmarkIntro> createState() => _BirdWordmarkIntroState();
}

class _BirdWordmarkIntroState extends State<BirdWordmarkIntro>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2800),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      if (!MediaQuery.of(context).disableAnimations) _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  static const _letters = ['M', 'o', 'v', 'e', 'ra'];
  static const _destinations = [-93.0, -54.0, -26.0, 7.0, 51.0];

  double _progress(double time, double start, double duration) =>
      ((time - start) / duration).clamp(0.0, 1.0).toDouble();

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.of(context).disableAnimations;
    return Semantics(
      label: 'Movera. Moving to a new era.',
      child: ExcludeSemantics(
        child: SizedBox(
          height: 142,
          child: LayoutBuilder(
            builder: (context, constraints) => AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final time = reducedMotion ? 1.0 : _controller.value;
                final lockup = Curves.easeIn.transform(
                  _progress(time, 0.79, 0.12),
                );
                final tagline = Curves.easeIn.transform(
                  _progress(time, 0.86, 0.12),
                );
                final flightOpacity = 1.0 - _progress(time, 0.77, 0.13);
                final center = constraints.maxWidth / 2;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    for (var i = 0; i < _letters.length; i++)
                      _flyingLetter(
                        i: i,
                        time: time,
                        center: center,
                        opacity: flightOpacity,
                        width: constraints.maxWidth,
                      ),
                    Positioned.fill(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Opacity(
                            opacity: lockup,
                            child: const MoveraWordmark(size: 37),
                          ),
                          const SizedBox(height: 8),
                          Opacity(
                            opacity: tagline,
                            child: Text(
                              'Moving to a new era.',
                              maxLines: 1,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 27,
                                height: 1.15,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.8,
                                color: AuthColors.deepGreen,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _flyingLetter({
    required int i,
    required double time,
    required double center,
    required double opacity,
    required double width,
  }) {
    final rightToLeft = i.isOdd;
    final startX = rightToLeft ? width + 24 : -58.0;
    final targetX = center + _destinations[i] - 12;
    final flight = Curves.easeInOutCubic.transform(
      _progress(time, i * 0.065, 0.66),
    );
    final x = startX + (targetX - startX) * flight;
    final arc = math.sin(flight * math.pi) * (i.isEven ? 19 : -16);
    final startY = 18.0 + (i % 3) * 13;
    final y = startY + (38 - startY) * flight - arc;
    return Positioned(
      left: x,
      top: y,
      child: Opacity(
        opacity: opacity,
        child: Column(
          children: [
            Transform.flip(
              flipX: rightToLeft,
              child: CustomPaint(
                size: const Size(27, 17),
                painter: _BirdPainter(
                  i.isOdd ? AuthColors.green : AuthColors.deepGreen,
                ),
              ),
            ),
            Text(
              _letters[i],
              style: GoogleFonts.poppins(
                fontSize: 21,
                height: 1,
                fontWeight: FontWeight.w700,
                color: i >= 3 ? AuthColors.green : AuthColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Minimal, drawn bird silhouette with no image asset or platform emoji.
class _BirdPainter extends CustomPainter {
  const _BirdPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final bird = Path()
      ..moveTo(0, 6)
      ..quadraticBezierTo(7, 2, 12, 10)
      ..quadraticBezierTo(17, 1, 27, 4)
      ..quadraticBezierTo(20, 7, 16, 15)
      ..quadraticBezierTo(12, 11, 10, 14)
      ..quadraticBezierTo(7, 9, 0, 6)
      ..close();
    canvas.drawPath(bird, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_BirdPainter oldDelegate) => oldDelegate.color != color;
}
