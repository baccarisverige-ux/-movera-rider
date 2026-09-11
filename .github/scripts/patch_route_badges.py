from pathlib import Path

path = Path('lib/features/rider/home/home.dart')
source = path.read_text(encoding='utf-8')


def replace_once(old: str, new: str, label: str) -> None:
    global source
    count = source.count(old)
    if count != 1:
        raise SystemExit(f'{label}: expected exactly 1 match, found {count}')
    source = source.replace(old, new, 1)


replace_once(
    """                bool removable = false,
                VoidCallback? onMapTap,
              }) {""",
    """                bool removable = false,
                VoidCallback? onMapTap,
                Color? badgeColor,
              }) {""",
    'routeField signature',
)

replace_once(
    """                    if (onMapTap != null)
                      Padding(
                        padding: EdgeInsets.only(right: ResSize.w * 4),
                        child: Material(
                          color: _premiumAccentSoft,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            onTap: onMapTap,
                            borderRadius: BorderRadius.circular(12),
                            child: SizedBox(
                              width: ResSize.w * 38,
                              height: ResSize.h * 38,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Icon(Icons.map_outlined, color: _premiumAccent, size: ResSize.h * 21),
                                  Positioned(right: ResSize.w * 5, top: ResSize.h * 5, child: Icon(Icons.location_on_rounded, color: _premiumInk, size: ResSize.h * 11)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),""",
    """                    if (badgeColor != null)
                      Semantics(
                        button: true,
                        label: field == 'pickup'
                            ? 'Set pickup on map'
                            : 'Select final destination',
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: onMapTap ??
                              () => activateField(
                                    field,
                                    controller,
                                    stopIndex: stopIndex,
                                  ),
                          child: Padding(
                            padding: EdgeInsets.only(left: ResSize.w * 3),
                            child: _PremiumRouteLocationBadge(
                              color: badgeColor,
                              size: ResSize.h * 44,
                            ),
                          ),
                        ),
                      ),""",
    'old pickup map button',
)

replace_once(
    """                  controller: pickupController,
                  focusNode: pickupFocus,
                  onMapTap: () async {""",
    """                  controller: pickupController,
                  focusNode: pickupFocus,
                  badgeColor: const Color(0xFF079A60),
                  onMapTap: () async {""",
    'pickup badge color',
)

replace_once(
    """                  controller: destinationController,
                  focusNode: destinationFocus,
                ),""",
    """                  controller: destinationController,
                  focusNode: destinationFocus,
                  badgeColor: const Color(0xFF1769E8),
                ),""",
    'destination badge color',
)

badge_widget = r'''
class _PremiumRouteLocationBadge extends StatelessWidget {
  const _PremiumRouteLocationBadge({
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
          border: Border.all(
            color: const Color(0xFFD2D6D8),
            width: 0.8,
          ),
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
                    color: Colors.white.withOpacity(0.98),
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
                    color: Colors.white.withOpacity(0.97),
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
                          color: Colors.white.withOpacity(0.55),
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

'''

marker = 'class _PickupMapResult {'
if source.count(marker) != 1:
    raise SystemExit('badge widget insertion marker was not unique')
source = source.replace(marker, badge_widget + marker, 1)

path.write_text(source, encoding='utf-8')
