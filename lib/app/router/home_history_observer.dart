import 'package:flutter/widgets.dart';
import 'package:movera_rider/core/web/web_overlay.dart';
import 'package:movera_rider/features/ride_booking/application/ride_restore_coordinator.dart';

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

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _sync(unlockFirst: true);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) => _sync();

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _sync();

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      _sync();
}
