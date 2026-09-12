
import 'package:flutter/material.dart';

abstract final class MoveraToast {
  static void show(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
