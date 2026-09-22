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

    // Epoch listeners defer their work to a post-frame callback because normal
    // NavigatorObserver callbacks can run while Navigator is locked. Route
    // completion futures can resolve after the last animation frame, though,
    // so explicitly request one frame to guarantee that deferred work drains.
    WidgetsBinding.instance.ensureVisualUpdate();
  }


  void _routeChangedAfterEnter(
    Route<dynamic> route, {
    bool unlockFirst = false,
  }) {
    if (unlockFirst) setWebHomeLock(false);
    if (route is! TransitionRoute<dynamic>) {
      _routeChanged(unlockFirst: unlockFirst);
      return;
    }

    // didPush can fire before TransitionRoute exposes a live animation. Count
    // the route as unsettled immediately, then attach to its animation on the
    // next frame. This closes the first-frame window where realtime/timer work
    // could otherwise push another route while the incoming page is still
    // entering.
    moveraNavigationTransitions.value += 1;
    var finished = false;
    Animation<double>? watchedAnimation;
    AnimationStatusListener? listener;
    var hasStarted = false;

    void finish() {
      if (finished) return;
      finished = true;
      if (watchedAnimation != null && listener != null) {
        watchedAnimation!.removeStatusListener(listener!);
      }
      final next = moveraNavigationTransitions.value - 1;
      moveraNavigationTransitions.value = next < 0 ? 0 : next;
      _routeChanged(unlockFirst: unlockFirst);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (finished) return;
      final animation = route.animation;
      if (animation == null) {
        finish();
        return;
      }
      watchedAnimation = animation;
      hasStarted = animation.status != AnimationStatus.dismissed;

      listener = (status) {
        if (status == AnimationStatus.forward ||
            status == AnimationStatus.reverse) {
          hasStarted = true;
        }
        if (status == AnimationStatus.completed ||
            (status == AnimationStatus.dismissed &&
                (hasStarted || !route.isActive))) {
          finish();
        }
      };
      animation.addStatusListener(listener!);

      final status = animation.status;
      if (status == AnimationStatus.forward ||
          status == AnimationStatus.reverse) {
        hasStarted = true;
      }
      if (status == AnimationStatus.completed ||
          (status == AnimationStatus.dismissed &&
              (hasStarted || !route.isActive))) {
        finish();
      }
    });
    WidgetsBinding.instance.ensureVisualUpdate();
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
