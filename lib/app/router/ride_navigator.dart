import 'package:flutter/material.dart';
import 'package:movera_rider/app/di.dart';
import 'package:movera_rider/app/navigator_key.dart';
import 'package:movera_rider/app/router/routes.dart';
import 'package:movera_rider/features/ride_booking/application/ride_restore_coordinator.dart';
import 'package:movera_rider/features/ride_booking/domain/ride_status.dart';
import 'package:movera_rider/shared/widgets/navigation_transition.dart';

abstract final class RideNavigator {
  static Future<dynamic> bottomToTop(BuildContext context, Widget page) {
    return Navigator.push(context, BottomToTopTransition(page));
  }

  static Future<dynamic> rightToLeft(BuildContext context, Widget page) {
    return Navigator.push(context, RightToLeftTransition(page));
  }

  static void home(BuildContext? context) {
    AppScope.instance.ride.restoreFromBackend(RideStatus.cancelledByRider);
    RideRestoreCoordinator.instance.goHome();
    _popToRoot(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _popToRoot(context);
    });
  }

  static void _popToRoot(BuildContext? context) {
    final nav =
        moveraNavigatorKey.currentState ??
        (context != null && context.mounted
            ? Navigator.maybeOf(context, rootNavigator: true)
            : null);
    if (nav != null && nav.canPop()) {
      nav.popUntil((route) => route.isFirst);
    }
  }

  static const names = AppRoutes;
}
