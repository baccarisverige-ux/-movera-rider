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

  static void home(
    BuildContext? context, {
    RideStatus status = RideStatus.cancelledByRider,
  }) {
    AppScope.instance.ride.restoreFromBackend(status);
    SheetCoordinator.instance.current = RideSheet.none;
    setWebOverlayOpen(false);

    final nav =
        moveraNavigatorKey.currentState ??
        (context != null && context.mounted
            ? Navigator.maybeOf(context, rootNavigator: true)
            : null);

    void finish() {
      unawaited(RideSnapshotStore.clear());
      RideRestoreCoordinator.instance.goHome();
      final atRoot = nav == null || !nav.canPop();
      setWebHomeLock(atRoot);
    }

    if (nav == null) {
      finish();
      return;
    }

    // Finding/Waiting set PopScope.canPop via `_leaving` before this.
    // Pop now if unlocked; otherwise wait one frame. Never removeRoute:
    // on Flutter web that leaves the old ride in history, so Home bounces back.
    void popToRoot() {
      if (nav.canPop()) {
        nav.popUntil((route) => route.isFirst);
      }
      finish();
    }

    if (nav.canPop()) {
      popToRoot();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => popToRoot());
    }
  }

  static const names = AppRoutes;
}
