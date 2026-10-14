import 'package:flutter/material.dart';

/// Reports a quick horizontal swipe over [child] without stealing taps or
/// vertical drags (sheets, lists and buttons underneath keep working).
class HorizontalSwipe extends StatelessWidget {
  const HorizontalSwipe({
    super.key,
    required this.child,
    this.onSwipeLeft,
    this.onSwipeRight,
  });

  final Widget child;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;

  static const double _minVelocity = 320;
  static const double _minDistance = 56;

  @override
  Widget build(BuildContext context) {
    double start = 0;
    double last = 0;
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragStart: (d) => start = last = d.globalPosition.dx,
      onHorizontalDragUpdate: (d) => last = d.globalPosition.dx,
      onHorizontalDragEnd: (d) {
        final velocity = d.primaryVelocity ?? 0;
        final distance = last - start;
        final left = velocity < -_minVelocity || distance < -_minDistance;
        final right = velocity > _minVelocity || distance > _minDistance;
        if (left && !right) onSwipeLeft?.call();
        if (right && !left) onSwipeRight?.call();
      },
      child: child,
    );
  }
}
