import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// The stylized location pin used on the "Plan your ride" route picker.
class PremiumRouteLocationBadge extends StatelessWidget {
  const PremiumRouteLocationBadge({
    super.key,
    required this.color,
    required this.size,
  });

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final corner = size * 0.25;
    final road = size * 0.105;
    final pinOutline = size * 0.65;
    final pinSize = size * 0.57;

    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(corner),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFFFFF), Color(0xFFF1F0EC)],
          ),
          border: Border.all(color: const Color(0xFFD2D6D8), width: 0.8),
          boxShadow: const [
            BoxShadow(
              color: Color(0x190D1A20),
              blurRadius: 7,
              offset: Offset(0, 3),
            ),
            BoxShadow(
              color: Color(0xA6FFFFFF),
              blurRadius: 1,
              offset: Offset(0, -1),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(corner - 1),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                left: -size * 0.06,
                top: size * 0.23,
                child: Container(
                  width: size * 0.74,
                  height: road,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.98),
                    borderRadius: BorderRadius.circular(road),
                  ),
                ),
              ),
              Positioned(
                right: size * 0.17,
                top: -size * 0.04,
                child: Container(
                  width: road,
                  height: size * 0.65,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.97),
                    borderRadius: BorderRadius.circular(road),
                  ),
                ),
              ),
              Positioned(
                right: -size * 0.08,
                bottom: size * 0.10,
                child: Transform.rotate(
                  angle: -0.52,
                  child: Container(
                    width: size * 0.70,
                    height: road,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFFFF),
                      borderRadius: BorderRadius.circular(road),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: size * 0.11,
                bottom: -size * 0.04,
                child: Container(
                  width: size * 0.10,
                  height: size * 0.50,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0E3E5),
                    borderRadius: BorderRadius.circular(size),
                  ),
                ),
              ),
              Transform.translate(
                offset: Offset(0, size * 0.035),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      color: const Color(0xFFFDFDFD),
                      size: pinOutline,
                      shadows: const [
                        Shadow(
                          color: Color(0x30000000),
                          blurRadius: 5,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    ShaderMask(
                      blendMode: BlendMode.srcIn,
                      shaderCallback: (bounds) => LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color.lerp(color, Colors.white, 0.22)!,
                          color,
                          Color.lerp(color, Colors.black, 0.24)!,
                        ],
                        stops: const [0.0, 0.48, 1.0],
                      ).createShader(bounds),
                      child: Icon(
                        Icons.location_on_rounded,
                        color: Colors.white,
                        size: pinSize,
                      ),
                    ),
                    Positioned(
                      top: size * 0.17,
                      left: size * 0.43,
                      child: Container(
                        width: size * 0.075,
                        height: size * 0.075,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.55),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Result of the map-based pickup/destination picker opened from Home.
class PickupMapResult {
  const PickupMapResult({required this.address, required this.position});
  final String address;
  final LatLng position;
}
