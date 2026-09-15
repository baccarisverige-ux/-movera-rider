import 'package:flutter/material.dart';
import 'package:movera_rider/shared/design_system/movera_empty_state.dart';

class MoveraLoader extends StatelessWidget {
  const MoveraLoader({
    super.key,
    this.title = 'Loading',
    this.message = 'Just a moment.',
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return MoveraEmptyState(
      icon: Icons.hourglass_empty_rounded,
      title: title,
      message: message,
    );
  }
}
