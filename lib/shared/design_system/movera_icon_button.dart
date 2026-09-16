import 'package:flutter/material.dart';
import 'package:movera_rider/shared/accessibility/a11y.dart';
import 'package:movera_rider/shared/design_system/tokens.dart';

class MoveraIconButton extends StatelessWidget {
  const MoveraIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.label,
    this.color,
    this.elevated = false,
    this.iconSize = 22,
  });

  factory MoveraIconButton.round({
    Key? key,
    required IconData icon,
    required VoidCallback onPressed,
    required String label,
    Color? color,
    double iconSize = 22,
  }) {
    return MoveraIconButton(
      key: key,
      icon: icon,
      onPressed: onPressed,
      label: label,
      color: color,
      elevated: true,
      iconSize: iconSize,
    );
  }

  /// WCAG 2.5.5 / Android accessibility minimum tap target.
  static const double minTap = A11y.minTap;

  final IconData icon;
  final VoidCallback onPressed;
  final String label;
  final Color? color;
  final bool elevated;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final ink = color ?? MoveraTokens.ink;
    if (elevated) {
      return Semantics(
        button: true,
        label: label,
        child: Material(
          color: Colors.white,
          shape: const CircleBorder(),
          elevation: 2,
          shadowColor: const Color(0x33000000),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: SizedBox(
              width: minTap,
              height: minTap,
              child: ExcludeSemantics(
                child: Icon(icon, size: iconSize, color: ink),
              ),
            ),
          ),
        ),
      );
    }
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, color: ink),
      tooltip: label,
      constraints: const BoxConstraints(minWidth: minTap, minHeight: minTap),
    );
  }
}
