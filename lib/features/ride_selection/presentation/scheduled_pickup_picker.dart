import 'package:flutter/material.dart';

/// Production date + time dialogs used by Book for later.
Future<DateTime?> chooseScheduledPickup(BuildContext context) async {
  final now = DateTime.now();
  final date = await showDatePicker(
    context: context,
    initialDate: now.add(const Duration(days: 1)),
    firstDate: now,
    lastDate: now.add(const Duration(days: 180)),
    helpText: 'Choose ride date',
  );
  if (date == null || !context.mounted) return null;
  final time = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.fromDateTime(now.add(const Duration(hours: 1))),
    helpText: 'Choose pickup time',
  );
  if (time == null || !context.mounted) return null;
  return DateTime(date.year, date.month, date.day, time.hour, time.minute);
}
