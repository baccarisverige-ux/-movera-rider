
import 'package:flutter/material.dart';
import 'package:movera_rider/shared/design_system/tokens.dart';

class MoveraSheet extends StatelessWidget {
  const MoveraSheet({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(MoveraTokens.radiusSheet)),
      ),
      child: child,
    );
  }
}
