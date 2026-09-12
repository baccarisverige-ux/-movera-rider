import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:movera_rider/app/app.dart';
import 'package:movera_rider/app/di.dart';
import 'package:movera_rider/core/logging/app_log.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
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
  AppLog.info('app.start', extra: {'platform': kIsWeb ? 'web' : 'native'});

  runZonedGuarded(
    () {
      runApp(const MoveraApp());
    },
    (error, stack) {
      AppLog.fatal('zone.error', error: error, stackTrace: stack);
    },
  );
}
