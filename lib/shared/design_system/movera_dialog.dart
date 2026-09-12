
import 'package:flutter/material.dart';

class MoveraDialog {
  static Future<void> show(BuildContext context, {required String title, required String body}) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
      ),
    );
  }
}
