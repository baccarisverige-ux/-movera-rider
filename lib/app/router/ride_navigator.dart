import 'dart:async';

import 'package:flutter/material.dart';
import 'package:movera_rider/app/di.dart';
import 'package:movera_rider/app/navigator_key.dart';
import 'package:movera_rider/app/router/routes.dart';
import 'package:movera_rider/core/web/web_overlay.dart';
import 'package:movera_rider/features/ride_booking/application/ride_restore_coordinator.dart';
import 'package:movera_rider/features/ride_booking/application/sheet_coordinator.dart';
import 'package:movera_rider/features/ride_booking/data/ride_snapshot_store.dart';
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
    SheetCoordinator.instance.current = RideSheet.none;
    setWebOverlayOpen(false);
    unawaited(RideSnapshotStore.clear());

    final nav =
        moveraNavigatorKey.currentState ??
        (context != null && context.mounted
            ? Navigator.maybeOf(context, rootNavigator: true)
            : null);

    // PopScope(canPop: false) blocks popUntil. removeRoute does not.
    if (context != null && context.mounted && nav != null) {
      final route = ModalRoute.of(context);
      if (route != null && route.isActive) {
        nav.removeRoute(route);
      }
    }

    if (nav != null && nav.canPop()) {
      nav.popUntil((route) => route.isFirst);
    }
    RideRestoreCoordinator.instance.goHome();
  }

  static const names = AppRoutes;
}
