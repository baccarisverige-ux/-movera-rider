import 'package:flutter/animation.dart';

/// Shared springs and curves. Sheets open with a soft spring and close faster.
abstract final class MoveraCurves {
  static const open = Cubic(0.16, 1.0, 0.30, 1.0);
  static const close = Cubic(0.40, 0.0, 0.20, 1.0);
  static const micro = Cubic(0.25, 0.1, 0.25, 1.0);
  static const snap = Cubic(0.22, 1.0, 0.36, 1.0);

  static const SpringDescription sheetSpring = SpringDescription(
    mass: 0.6,
    stiffness: 140,
    damping: 18.4,
  );
}
