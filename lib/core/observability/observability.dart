enum TelemetryLevel { debug, info, warning, error, fatal }

abstract class LoggerSink {
  void log(
    TelemetryLevel level,
    String event, {
    Map<String, Object?> extra = const {},
    Object? error,
    StackTrace? stackTrace,
  });
}

abstract class AnalyticsSink {
  void track(String event, {Map<String, Object?> extra = const {}});
}

abstract class CrashSink {
  void record(
    Object error,
    StackTrace stackTrace, {
    Map<String, Object?> extra = const {},
  });
}

class NoopLoggerSink implements LoggerSink {
  const NoopLoggerSink();

  @override
  void log(
    TelemetryLevel level,
    String event, {
    Map<String, Object?> extra = const {},
    Object? error,
    StackTrace? stackTrace,
  }) {}
}

class NoopAnalyticsSink implements AnalyticsSink {
  const NoopAnalyticsSink();

  @override
  void track(String event, {Map<String, Object?> extra = const {}}) {}
}

class NoopCrashSink implements CrashSink {
  const NoopCrashSink();

  @override
  void record(
    Object error,
    StackTrace stackTrace, {
    Map<String, Object?> extra = const {},
  }) {}
}

abstract final class Observability {
  static LoggerSink logger = const NoopLoggerSink();
  static AnalyticsSink analytics = const NoopAnalyticsSink();
  static CrashSink crashes = const NoopCrashSink();

  static void configure({
    LoggerSink? loggerSink,
    AnalyticsSink? analyticsSink,
    CrashSink? crashSink,
  }) {
    if (loggerSink != null) logger = loggerSink;
    if (analyticsSink != null) analytics = analyticsSink;
    if (crashSink != null) crashes = crashSink;
  }

  static void reset() {
    logger = const NoopLoggerSink();
    analytics = const NoopAnalyticsSink();
    crashes = const NoopCrashSink();
  }

  static Map<String, Object?> sanitize(Map<String, Object?> extra) {
    const blocked = <String>{
      'password',
      'token',
      'accessToken',
      'refreshToken',
      'cardNumber',
      'cvc',
      'pin',
      'phone',
      'phoneE164',
      'localPath',
      'shareToken',
      'email',
    };
    return <String, Object?>{
      for (final entry in extra.entries)
        if (!blocked.contains(entry.key)) entry.key: entry.value,
    };
  }
}
