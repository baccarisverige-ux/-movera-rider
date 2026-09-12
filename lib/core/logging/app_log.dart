import 'package:flutter/foundation.dart';

enum LogLevel { debug, info, warning, error, fatal }

abstract final class AppLog {
  static void debug(String event, {Map<String, Object?> extra = const {}}) {
    _write(LogLevel.debug, event, extra: extra);
  }

  static void info(String event, {Map<String, Object?> extra = const {}}) {
    _write(LogLevel.info, event, extra: extra);
  }

  static void warning(String event, {Map<String, Object?> extra = const {}}) {
    _write(LogLevel.warning, event, extra: extra);
  }

  static void error(
    String event, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?> extra = const {},
  }) {
    _write(LogLevel.error, event, extra: extra, error: error, stackTrace: stackTrace);
  }

  static void fatal(
    String event, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?> extra = const {},
  }) {
    _write(LogLevel.fatal, event, extra: extra, error: error, stackTrace: stackTrace);
  }

  static void _write(
    LogLevel level,
    String event, {
    Map<String, Object?> extra = const {},
    Object? error,
    StackTrace? stackTrace,
  }) {
    final safe = Map<String, Object?>.from(extra)
      ..remove('password')
      ..remove('token')
      ..remove('accessToken')
      ..remove('refreshToken')
      ..remove('cardNumber')
      ..remove('cvc');
    debugPrint('[movera:${level.name}] $event $safe');
    if (error != null) debugPrint('  error=$error');
    if (stackTrace != null) debugPrint('$stackTrace');
  }
}
