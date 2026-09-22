import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:movera_rider/core/web/web_overlay.dart';
import 'package:movera_rider/features/ride_booking/application/ride_restore_coordinator.dart';

/// Monotonic signal for route-stack changes.
final ValueNotifier<int> moveraNavigationEpoch = ValueNotifier<int>(0);

/// Keep Chrome from treating Home sheet overscroll as history.back.
class HomeHistoryObserver extends NavigatorObserver {
  void _sync({bool unlockFirst = false}) {
    if (unlockFirst) setWebHomeLock(false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final nav = navigator;
      final atRoot = nav == null || !nav.canPop();
      final home =
          RideRestoreCoordinator.instance.showing == RestoredSurface.home;
      setWebHomeLock(atRoot && home);
    });
  }

  void _routeChanged({bool unlockFirst = false}) {
    moveraNavigationEpoch.value += 1;
    _sync(unlockFirst: unlockFirst);
  }

  void _routeChangedAfterExit(
    Route<dynamic> route, {
    bool unlockFirst = false,
  }) {
    if (unlockFirst) setWebHomeLock(false);
    if (route is TransitionRoute<dynamic>) {
      unawaited(
        route.completed.whenComplete(
          () => _routeChanged(unlockFirst: unlockFirst),
        ),
      );
      return;
    }
    _routeChanged(unlockFirst: unlockFirst);
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _routeChanged(unlockFirst: true);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _routeChangedAfterExit(route);

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _routeChanged();

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (oldRoute != null) {
      _routeChangedAfterExit(oldRoute);
      return;
    }
    _routeChanged();
  }
}
