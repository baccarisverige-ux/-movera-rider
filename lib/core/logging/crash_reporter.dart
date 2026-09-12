import 'package:movera_rider/core/logging/app_log.dart';

/// Sentry/Crashlytics adapter. No DSN is stored in the app.
class CrashReporter {
  const CrashReporter();

  void record(Object error, StackTrace stack, {String? rideId, String? screen}) {
    AppLog.fatal(
      'crash',
      error: error,
      stackTrace: stack,
      extra: {'rideId': rideId, 'screen': screen},
    );
  }
}
