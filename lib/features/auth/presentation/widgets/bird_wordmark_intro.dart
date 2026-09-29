import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movera_rider/features/auth/presentation/widgets/auth_style.dart';
import 'package:movera_rider/features/auth/presentation/widgets/movera_wordmark.dart';

/// Five birds deliver the letters, then settle beside the finished wordmark
/// with gentle, continuous motion.
class BirdWordmarkIntro extends StatefulWidget {
  const BirdWordmarkIntro({super.key});

  @override
  State<BirdWordmarkIntro> createState() => _BirdWordmarkIntroState();
}

class _BirdWordmarkIntroState extends State<BirdWordmarkIntro>
    with TickerProviderStateMixin {
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3900),
  );
  late final AnimationController _hover = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1900),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      if (!MediaQuery.of(context).disableAnimations) {
        _intro.forward().then((_) {
          if (mounted && !MediaQuery.of(context).disableAnimations) {
            _hover.repeat(reverse: true);
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _intro.dispose();
    _hover.dispose();
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
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 350),
              child: LayoutBuilder(
                builder: (context, constraints) => AnimatedBuilder(
                  animation: Listenable.merge([_intro, _hover]),
                  builder: (context, _) {
                    final time = reducedMotion ? 1.0 : _intro.value;
                    final lockup = Curves.easeIn.transform(
                      _progress(time, 0.72, 0.18),
                    );
                    final tagline = Curves.easeIn.transform(
                      _progress(time, 0.83, 0.15),
                    );
                    final center = constraints.maxWidth / 2;
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
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
                                    fontSize: 25,
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
                        for (var i = 0; i < _letters.length; i++)
                          ..._flyingPair(
                            i: i,
                            time: time,
                            center: center,
                            width: constraints.maxWidth,
                            reducedMotion: reducedMotion,
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

  List<Widget> _flyingPair({
    required int i,
    required double time,
    required double center,
    required double width,
    required bool reducedMotion,
  }) {
    final fromRight = i.isOdd;
    final startX = fromRight ? width + 24 : -58.0;
    final landingX = center + _destinations[i] - 12;
    final arrival = 0.55 + i * 0.05;
    final flight = Curves.easeInOutCubic.transform(
      _progress(time, i * 0.05, 0.55),
    );
    final approachX = startX + (landingX - startX) * flight;
    final arc = math.sin(flight * math.pi) * (i.isEven ? 19 : -16);
    final startY = 18.0 + (i % 3) * 13;
    final approachY = startY + (38 - startY) * flight - arc;
    final depart = Curves.easeInOut.transform(
      _progress(time, arrival, 0.22),
    );
    // Stay close to the brand, including on narrow phone screens.
    final perches = [
      Offset(8, 55),
      Offset(width - 34, 28),
      const Offset(32, 8),
      Offset(width - 60, 74),
      Offset(width - 32, 8),
    ];
    final perch = perches[i];
    final bob = reducedMotion
        ? 0.0
        : math.sin((_hover.value * 2 * math.pi) + i * 0.9) * 3.0;
    final tilt = reducedMotion
        ? 0.0
        : math.sin((_hover.value * 2 * math.pi) + i * 0.9) * 0.09;
    final birdX = approachX + (perch.dx - approachX) * depart;
    final birdY = approachY + (perch.dy - approachY) * depart + bob * depart;
    final letterOpacity = 1.0 - _progress(time, arrival, 0.18);

    return [
      if (letterOpacity > 0)
        Positioned(
          left: approachX,
          top: approachY + 17,
          child: Opacity(
            opacity: letterOpacity,
            child: Text(
              _letters[i],
              style: GoogleFonts.poppins(
                fontSize: 21,
                height: 1,
                fontWeight: FontWeight.w700,
                color: i >= 3 ? AuthColors.green : AuthColors.ink,
              ),
            ),
          ),
        ),
      Positioned(
        left: birdX,
        top: birdY,
        child: Transform.rotate(
          angle: tilt * depart,
          child: Transform.flip(
            flipX: fromRight,
            child: CustomPaint(
              size: const Size(27, 17),
              painter: _BirdPainter(
                i.isOdd ? AuthColors.green : AuthColors.deepGreen,
              ),
            ),
          ),
        ),
      ),
    ];
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
