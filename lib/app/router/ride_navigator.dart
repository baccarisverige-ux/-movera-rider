
import 'package:flutter/material.dart';
import 'package:movera_rider/app/router/routes.dart';
import 'package:movera_rider/shared/widgets/navigation_transition.dart';

/// Single navigation API. Screens should not mix Get.to and raw pushes.
abstract final class RideNavigator {
  static Future<T?> open<T>(BuildContext context, Widget page, {String? name}) {
    return Navigator.push<T>(
      context,
      BottomToTopTransition(page),
    );
  }

  static void home(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  static const names = AppRoutes;
}
