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

  /// Removes personal data from telemetry `extra`.
  ///
  /// Keys are matched case-insensitively, by word (`riderPhone`,
  /// `pickup_lat`, `holderName`) and by substring for the long markers
  /// (`refreshToken`, `pickupAddress`), recursively through nested maps and
  /// lists. String values that are kept are passed through [scrubText].
  static Map<String, Object?> sanitize(Map<String, Object?> extra) {
    return <String, Object?>{
      for (final entry in extra.entries)
        if (!isSensitiveKey(entry.key)) entry.key: _sanitizeValue(entry.value),
    };
  }

  /// Markers matched anywhere in the lower-cased key with separators removed.
  static const _blockedFragments = <String>[
    'password',
    'passcode',
    'secret',
    'token',
    'authorization',
    'cookie',
    'credential',
    'phone',
    'email',
    'address',
    'latitude',
    'longitude',
    'coordinate',
    'card',
    'localpath',
  ];

  /// Markers matched only as a whole word of the key, because as substrings
  /// they would also hit unrelated keys (`pin` in `shipping`, `lat` in
  /// `platform`).
  static const _blockedWords = <String>{
    'pin',
    'otp',
    'cvc',
    'cvv',
    'pan',
    'iban',
    'lat',
    'lng',
    'lon',
    'name',
    'holder',
    'ip',
  };

  static bool isSensitiveKey(String key) {
    final words = key
        .replaceAllMapped(
          RegExp(r'([a-z0-9])([A-Z])'),
          (m) => '${m[1]} ${m[2]}',
        )
        .toLowerCase()
        .split(RegExp(r'[^a-z0-9]+'))
        .where((word) => word.isNotEmpty)
        .toList();
    if (words.any(_blockedWords.contains)) return true;
    final compact = words.join();
    return _blockedFragments.any(compact.contains);
  }

  static Object? _sanitizeValue(Object? value) {
    if (value is Map) {
      return sanitize(<String, Object?>{
        for (final entry in value.entries) '${entry.key}': entry.value,
      });
    }
    if (value is Iterable) {
      return [for (final item in value) _sanitizeValue(item)];
    }
    if (value is String) return scrubText(value);
    return value;
  }

  static final _email = RegExp(r'[\w.+-]+@[\w-]+(?:\.[\w-]+)+');
  static final _intlPhone = RegExp(r'\+\d[\d\s().-]{6,}\d');
  static final _nationalPhone = RegExp(
    r'(?<![\w.])0\d{1,3}[\s-]?\d{2,4}[\s-]?\d{2,4}(?:[\s-]?\d{2,4})?(?![\w.])',
  );
  static final _coordinate = RegExp(r'(?<![\w.])-?\d{1,3}\.\d{4,}(?![\w.])');

  /// Replaces e-mail addresses, phone numbers and precise coordinates in free
  /// text (error messages, stack traces) before it leaves the device.
  static String scrubText(String text) {
    String phone(Match m) {
      final digits = m[0]!.replaceAll(RegExp(r'\D'), '').length;
      return digits >= 8 && digits <= 15 ? '[phone]' : m[0]!;
    }

    return text
        .replaceAll(_email, '[email]')
        .replaceAllMapped(_intlPhone, phone)
        .replaceAllMapped(_nationalPhone, phone)
        .replaceAll(_coordinate, '[coord]');
  }
}
