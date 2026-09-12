
import 'package:flutter/material.dart';
import 'package:movera_rider/shared/design_system/tokens.dart';

class MoveraRideCard extends StatelessWidget {
  const MoveraRideCard({super.key, required this.title, required this.price, this.selected = false, this.onTap});
  final String title;
  final String price;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: MoveraTokens.ink)),
      trailing: Text(price, style: const TextStyle(fontWeight: FontWeight.w700)),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: selected ? MoveraTokens.accent : MoveraTokens.line),
      ),
    );
  }
}
