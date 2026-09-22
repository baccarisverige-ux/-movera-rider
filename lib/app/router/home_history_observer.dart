import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:movera_rider/core/web/web_overlay.dart';
import 'package:movera_rider/features/ride_booking/application/ride_restore_coordinator.dart';

/// Monotonic signal for settled route-stack changes.
final ValueNotifier<int> moveraNavigationEpoch = ValueNotifier<int>(0);

/// Number of outgoing animated routes that have been popped/replaced but have
/// not yet finished leaving the Navigator overlay.
final ValueNotifier<int> moveraNavigationTransitions = ValueNotifier<int>(0);

bool get moveraNavigationSettled => moveraNavigationTransitions.value == 0;

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


  void _routeChangedAfterEnter(
    Route<dynamic> route, {
    bool unlockFirst = false,
  }) {
    if (unlockFirst) setWebHomeLock(false);
    if (route is TransitionRoute<dynamic>) {
      final animation = route.animation;
      if (animation != null && animation.status != AnimationStatus.completed) {
        moveraNavigationTransitions.value += 1;
        var finished = false;
        late AnimationStatusListener listener;

        void finish() {
          if (finished) return;
          finished = true;
          animation.removeStatusListener(listener);
          final next = moveraNavigationTransitions.value - 1;
          moveraNavigationTransitions.value = next < 0 ? 0 : next;
          _routeChanged(unlockFirst: unlockFirst);
        }

        listener = (status) {
          if (status == AnimationStatus.completed ||
              status == AnimationStatus.dismissed) {
            finish();
          }
        };
        animation.addStatusListener(listener);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (animation.status == AnimationStatus.completed ||
              animation.status == AnimationStatus.dismissed) {
            finish();
          }
        });
        return;
      }
    }
    _routeChanged(unlockFirst: unlockFirst);
  }

  void _routeChangedAfterExit(
    Route<dynamic> route, {
    bool unlockFirst = false,
  }) {
    if (unlockFirst) setWebHomeLock(false);
    if (route is TransitionRoute<dynamic>) {
      moveraNavigationTransitions.value += 1;
      unawaited(
        route.completed.whenComplete(() {
          final next = moveraNavigationTransitions.value - 1;
          moveraNavigationTransitions.value = next < 0 ? 0 : next;
          _routeChanged(unlockFirst: unlockFirst);
        }),
      );
      return;
    }
    _routeChanged(unlockFirst: unlockFirst);
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _routeChangedAfterEnter(route, unlockFirst: true);
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
    }
    if (newRoute != null) {
      _routeChangedAfterEnter(newRoute, unlockFirst: true);
      return;
    }
    if (oldRoute == null) _routeChanged();
  }
}
