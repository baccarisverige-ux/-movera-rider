import 'package:flutter/material.dart';
import 'package:movera_rider/app/router/routes.dart';

abstract final class RideNavigator {
  static Future<T?> open<T>(BuildContext context, Widget page, {String? name}) {
    return Navigator.push<T>(
      context,
      MaterialPageRoute<T>(
        settings: RouteSettings(name: name),
        builder: (_) => page,
      ),
    );
  }

  static void home(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  static const names = AppRoutes;
}
