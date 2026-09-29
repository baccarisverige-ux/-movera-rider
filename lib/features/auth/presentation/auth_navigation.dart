import 'package:flutter/material.dart';
import 'package:movera_rider/app/router/routes.dart';
import 'package:movera_rider/features/home/presentation/home.dart';
import 'package:movera_rider/features/safety/domain/phone_e164.dart';

/// Leaves the sign-in flow for the map, clearing it from the back stack.
void enterMoveraApp(BuildContext context) {
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute<void>(
      settings: const RouteSettings(name: AppRoutes.home),
      builder: (_) => const Home(),
    ),
    (_) => false,
  );
}

/// The +46 number a rider typed into the national-number field, or null.
///
/// Accepts both "70 123 45 67" and the everyday "070 123 45 67". The old
/// screens prefixed +46 to whatever was typed, turning "070..." into the
/// invalid "+46070...".
String? swedishNumberFromField(String typed) {
  final digits = typed.replaceAll(RegExp(r'\s+'), '').trim();
  if (digits.isEmpty) return null;
  return SwedishPhone.toE164(digits.startsWith('0') ? digits : '+46$digits');
}
