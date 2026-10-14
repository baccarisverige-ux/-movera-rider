import 'package:flutter/material.dart';
import 'package:movera_rider/shared/accessibility/a11y.dart';

/// UI-4: gives a small control a tap area (and a semantics rect) of at least
/// [minWidth] x [minHeight] without changing how it looks.
///
/// The [child] is laid out at its own size, placed by [alignment] inside the
/// larger box, and keeps its own InkWell for the ripple (pass
/// `excludeFromSemantics: true` to that InkWell so this widget owns the
/// button node). Taps on the transparent margin around it call the same
/// [onTap].
class MoveraHitArea extends StatelessWidget {
  const MoveraHitArea({
    super.key,
    required this.label,
    required this.onTap,
    required this.child,
    this.selected,
    this.minWidth = A11y.minTapIOS,
    this.minHeight = A11y.minTapIOS,
    this.alignment = Alignment.center,
  });

  final String label;
  final VoidCallback onTap;
  final Widget child;
  final bool? selected;
  final double minWidth;
  final double minHeight;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: minWidth, minHeight: minHeight),
          child: Align(
            alignment: alignment,
            widthFactor: 1,
            heightFactor: 1,
            child: child,
          ),
        ),
      ),
    );
  }
}
