import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:movera_rider/app/app.dart';
import 'package:movera_rider/app/di.dart';
import 'package:movera_rider/app/navigator_key.dart';
import 'package:movera_rider/core/debug/movera_qa.dart';
import 'package:movera_rider/core/debug/web_qa_hooks.dart';
import 'package:movera_rider/core/logging/app_log.dart';
import 'package:movera_rider/features/ride_booking/data/web_ride_seed.dart';
import 'package:movera_rider/features/safety/presentation/safety_hub.dart';
import 'package:movera_rider/shared/widgets/navigation_transition.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  // window.movera* hooks stay OFF on public web release unless debug / MOVERA_QA.
  if (moveraQaHooksEnabled) {
    registerWebQaHooks();
    installSafetyQaOpener(() {
      final nav = moveraNavigatorKey.currentState;
      if (nav == null) return;
      nav.push(RightToLeftTransition(const SafetyHub()));
    });
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
  AppLog.info('app.start', extra: {'platform': kIsWeb ? 'web' : 'native'});

  runZonedGuarded(
    () {
      runApp(const MoveraApp());
    },
    (error, stack) {
      AppScope.instance.crashes.record(error, stack);
      AppLog.fatal('zone.error', error: error, stackTrace: stack);
    },
  );
}
