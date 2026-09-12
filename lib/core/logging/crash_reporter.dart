import 'package:flutter/foundation.dart';
import 'package:movera_rider/core/logging/app_log.dart';

/// Sentry/Crashlytics adapter. No DSN is stored in the app.
class CrashReporter {
  const CrashReporter();

  void record(
    Object error,
    StackTrace stack, {
    String? rideId,
    String? screen,
    String? operation,
    String? requestId,
  }) {
    AppLog.fatal(
      'crash',
      error: error,
      stackTrace: stack,
      extra: {
        'rideId': rideId,
        'screen': screen,
        'operation': operation,
        'requestId': requestId,
        'platform': kIsWeb ? 'web' : defaultTargetPlatform.name,
        'appVersion': '1.0.0',
      },
    );
  }
}
