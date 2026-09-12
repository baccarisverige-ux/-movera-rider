
import 'package:flutter/material.dart';
import 'package:movera_rider/shared/design_system/tokens.dart';

class MoveraLoader extends StatelessWidget {
  const MoveraLoader({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator(color: MoveraTokens.accent));
  }
}
