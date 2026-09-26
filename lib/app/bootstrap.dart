import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:movera_rider/app/app.dart';
import 'package:movera_rider/app/di.dart';
import 'package:movera_rider/app/navigator_key.dart';
import 'package:movera_rider/app/router/routes.dart';
import 'package:movera_rider/core/debug/movera_qa.dart';
import 'package:movera_rider/core/debug/web_qa_hooks.dart';
import 'package:movera_rider/core/logging/app_log.dart';
import 'package:movera_rider/core/web/web_ride_pagehide.dart';
import 'package:movera_rider/features/notifications/application/push_coordinator.dart';
import 'package:movera_rider/features/notifications/presentation/notifications.dart';
import 'package:movera_rider/features/ride_booking/application/ride_restore_coordinator.dart';
import 'package:movera_rider/features/ride_booking/data/ride_snapshot_store.dart';
import 'package:movera_rider/features/ride_booking/data/web_ride_seed.dart';
import 'package:movera_rider/features/safety/presentation/safety_hub.dart';
import 'package:movera_rider/shared/widgets/navigation_transition.dart';


PushCoordinator? _pushCoordinator;

Future<void> _registerExistingPushSession() async {
  if (AppScope.instance.environment.allowsMockTransport) return;
  final access = await AppScope.instance.tokens.readAccess();
  final refresh = await AppScope.instance.tokens.readRefresh();
  if (access?.isNotEmpty != true || refresh?.isNotEmpty != true) return;
  try {
    await AppScope.instance.push.register();
  } catch (error) {
    AppLog.warning(
      'push.session_restore_deferred',
      extra: {'error': error.toString()},
    );
  }
}

Future<bool> _openRideFromPush(String rideId) async {
  await AppScope.instance.rideRealtime.reconnectAndResync(rideId);

  final snapshot = await RideSnapshotStore.read();
  if (snapshot == null || snapshot.rideId?.trim() != rideId.trim()) {
    return false;
  }

  final surface = RideRestoreCoordinator.instance.surfaceFor(snapshot);
  if (surface == RestoredSurface.home) return false;

  final nav = moveraNavigatorKey.currentState;
  if (nav != null && nav.canPop()) {
    nav.popUntil((route) => route.isFirst);
    await WidgetsBinding.instance.endOfFrame;
  }

  await RideRestoreCoordinator.instance.resumeIfNeeded();
  return true;
}

void _openNotificationsFromPush() {
  final nav = moveraNavigatorKey.currentState;
  if (nav == null) return;
  unawaited(
    nav.push<void>(
      RightToLeftTransition(
        const NotificationScreen(),
        settings: const RouteSettings(name: AppRoutes.notifications),
      ),
    ),
  );
}

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  installWebRidePagehide(RideRestoreCoordinator.instance.onPageHide);
  // Public web gets one navigation-only bridge for Safety. It exposes no
  // ride seeding, matching controls, or Safety mutations.
  installSafetyNavigationBridge(() {
    final nav = moveraNavigatorKey.currentState;
    if (nav == null) return false;
    unawaited(nav.push<void>(RightToLeftTransition(const SafetyHub())));
    return true;
  });

  // Debug / MOVERA_QA keeps the broader mutation-capable QA hooks gated off
  // from public release builds.
  if (moveraQaHooksEnabled) {
    registerWebQaHooks();
  }
  AppScope.instance.maps.onOwnerDebug = reportMapOwner;

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    AppScope.instance.crashes.record(
      details.exception,
      details.stack ?? StackTrace.empty,
      screen: details.library,
    );
    AppLog.fatal(
      'flutter.error',
      error: details.exception,
      stackTrace: details.stack,
      extra: {'library': details.library ?? ''},
    );
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    AppLog.fatal('platform.error', error: error, stackTrace: stack);
    return true;
  };

  AppScope.instance.lifecycle.attach();
  await AppScope.instance.reservations.hydrate();
  await AppScope.instance.profile.hydrate();
  await _registerExistingPushSession();
  AppLog.info('app.start', extra: {'platform': kIsWeb ? 'web' : 'native'});

  runZonedGuarded(
    () {
      runApp(const MoveraApp());
      _pushCoordinator ??= PushCoordinator(
        push: AppScope.instance.push,
        openRide: _openRideFromPush,
        openNotifications: _openNotificationsFromPush,
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        unawaited(_pushCoordinator!.start());
      });
    },
    (error, stack) {
      AppScope.instance.crashes.record(error, stack);
      AppLog.fatal('zone.error', error: error, stackTrace: stack);
    },
  );
}
