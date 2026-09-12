
import 'package:flutter/material.dart';
import 'package:movera_rider/shared/design_system/movera_text_field.dart';

class MoveraSearchBar extends StatelessWidget {
  const MoveraSearchBar({super.key, this.controller, this.onChanged, this.hint});
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return MoveraTextField(controller: controller, onChanged: onChanged, hint: hint ?? 'Search');
  }
}
