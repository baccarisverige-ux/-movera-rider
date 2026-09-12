import 'package:flutter/material.dart';
import 'package:movera_rider/app/router/routes.dart';
import 'package:movera_rider/shared/widgets/navigation_transition.dart';

abstract final class RideNavigator {
  static Future<T?> bottomToTop<T>(BuildContext context, Widget page, {String? name}) {
    return Navigator.push<T>(context, BottomToTopTransition(page));
  }

  static Future<T?> rightToLeft<T>(BuildContext context, Widget page) {
    return Navigator.push<T>(context, RightToLeftTransition(page));
  }

  static void home(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  static const names = AppRoutes;
}
