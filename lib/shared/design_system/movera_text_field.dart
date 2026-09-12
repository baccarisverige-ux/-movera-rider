
import 'package:flutter/material.dart';
import 'package:movera_rider/shared/design_system/tokens.dart';

class MoveraTextField extends StatelessWidget {
  const MoveraTextField({super.key, this.controller, this.hint, this.onChanged});
  final TextEditingController? controller;
  final String? hint;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: MoveraTokens.bg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: MoveraTokens.line),
        ),
      ),
    );
  }
}
