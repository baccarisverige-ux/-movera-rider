import 'package:flutter/foundation.dart';

abstract final class AppLog {
  static void info(String event, {Map<String, Object?> extra = const {}}) {
    debugPrint('[movera] $event $extra');
  }

  static void error(
    String event, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?> extra = const {},
  }) {
    debugPrint('[movera:error] $event $extra $error');
    if (stackTrace != null) debugPrint('$stackTrace');
  }
}
