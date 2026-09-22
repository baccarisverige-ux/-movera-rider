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

final Map<Route<dynamic>, AnimationStatusListener> _moveraEntryListeners = {};
final Expando<bool> _moveraDismissedEntryReady =
    Expando<bool>('moveraDismissedEntryReady');

void _notifyNavigationEpoch() {
  moveraNavigationEpoch.value += 1;
  WidgetsBinding.instance.ensureVisualUpdate();
}

void _signalWhenRouteEntryFinishes(
  TransitionRoute<dynamic> route,
  Animation<double> animation,
) {
  if (_moveraEntryListeners.containsKey(route)) return;

  late AnimationStatusListener listener;
  void finish({bool dismissedIsReady = false}) {
    animation.removeStatusListener(listener);
    _moveraEntryListeners.remove(route);
    if (dismissedIsReady) {
      _moveraDismissedEntryReady[route] = true;
    }
    _notifyNavigationEpoch();
  }

  listener = (status) {
    if (status == AnimationStatus.completed) {
      finish();
      return;
    }
    // A dismissed route can mean either "not started yet" or "this route has
    // no entrance animation". Never accept it synchronously. The post-frame
    // check below decides whether it stayed current/dismissed long enough to
    // be considered settled.
    if (status == AnimationStatus.dismissed && !route.isCurrent) {
      finish();
    }
  };

  _moveraEntryListeners[route] = listener;
  animation.addStatusListener(listener);

  if (animation.status == AnimationStatus.dismissed) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_moveraEntryListeners.containsKey(route)) return;
      final status = animation.status;
      if (status == AnimationStatus.completed) {
        finish();
      } else if (status == AnimationStatus.dismissed && route.isCurrent) {
        // Zero/no-animation current routes are safe after one complete frame.
        finish(dismissedIsReady: true);
      }
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }
}

/// A screen may navigate only when it is the visible current route, its own
/// entrance animation has completed, and no older route is still animating out
/// above/beside it.
///
/// Reading the incoming animation from the route itself is more reliable than
/// trying to infer its first frame globally from NavigatorObserver.didPush.
bool moveraRouteIsSettled(BuildContext context) {
  final route = ModalRoute.of(context);
  if (route == null) return moveraNavigationSettled;
  if (!route.isCurrent) return false;
  final animation = route.animation;
  if (animation == null) return moveraNavigationSettled;

  final status = animation.status;
  if (status == AnimationStatus.completed) {
    return moveraNavigationSettled;
  }
  if (status == AnimationStatus.dismissed &&
      _moveraDismissedEntryReady[route] == true) {
    return moveraNavigationSettled;
  }
  if (route is TransitionRoute<dynamic>) {
    _signalWhenRouteEntryFinishes(route, animation);
  }
  return false;
}

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
    // Incoming animation state is read directly through moveraRouteIsSettled.
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
    }
    if (newRoute != null) {
      _routeChanged(unlockFirst: true);
      return;
    }
    if (oldRoute == null) _routeChanged();
  }
}
