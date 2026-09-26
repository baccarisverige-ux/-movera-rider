import 'package:flutter/material.dart';

Future<void> showDriverCallUnavailable(
  BuildContext context, {
  String? driverName,
}) {
  final name = driverName?.trim();
  final driverLabel = name == null || name.isEmpty ? 'your driver' : name;
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Driver calling unavailable'),
      content: Text(
        'Movera has not received a backend-issued masked calling number for '
        '$driverLabel yet. No phone call was placed.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}
