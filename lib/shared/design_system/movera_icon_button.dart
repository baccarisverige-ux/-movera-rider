
import 'package:flutter/material.dart';
import 'package:movera_rider/shared/design_system/tokens.dart';

class MoveraIconButton extends StatelessWidget {
  const MoveraIconButton({super.key, required this.icon, required this.onPressed, this.label});
  final IconData icon;
  final VoidCallback onPressed;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, color: MoveraTokens.ink),
      tooltip: label,
      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
    );
  }
}
