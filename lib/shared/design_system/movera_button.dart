import 'package:flutter/material.dart';
import 'package:movera_rider/shared/design_system/tokens.dart';

class MoveraButton extends StatelessWidget {
  const MoveraButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.filled = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final child = Text(
      label,
      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
    );
    if (filled) {
      return SizedBox(
        width: double.infinity,
        height: MoveraTokens.buttonHeight,
        child: FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: MoveraTokens.cta,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
          ),
          child: child,
        ),
      );
    }
    return SizedBox(
      width: double.infinity,
      height: MoveraTokens.buttonHeight,
      child: OutlinedButton(onPressed: onPressed, child: child),
    );
  }
}
