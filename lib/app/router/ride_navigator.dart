import 'package:flutter/material.dart';
import 'package:movera_rider/app/router/routes.dart';
import 'package:movera_rider/shared/widgets/navigation_transition.dart';

abstract final class RideNavigator {
  static Future<dynamic> bottomToTop(BuildContext context, Widget page) {
    return Navigator.push(context, BottomToTopTransition(page));
  }

  static Future<dynamic> rightToLeft(BuildContext context, Widget page) {
    return Navigator.push(context, RightToLeftTransition(page));
  }

  static void home(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  static const names = AppRoutes;
}
