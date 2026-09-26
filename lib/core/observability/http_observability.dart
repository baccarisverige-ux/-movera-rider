import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:movera_rider/core/observability/observability.dart';

/// Privacy-safe remote observability sink. It intentionally uses raw HTTP
/// instead of ApiClient so logging an ApiClient request cannot recurse.
class HttpObservabilitySink
    implements LoggerSink, AnalyticsSink, CrashSink {
  HttpObservabilitySink({
    required this.baseUrl,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  void _post(String path, Map<String, Object?> body) {
    unawaited(
      _client
          .post(
            Uri.parse('$baseUrl$path'),
            headers: const {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 5))
          .catchError((_) => http.Response('', 599)),
    );
  }

  @override
  void log(
    TelemetryLevel level,
    String event, {
    Map<String, Object?> extra = const {},
    Object? error,
    StackTrace? stackTrace,
  }) {
    _post('/api/v1/telemetry/logs', {
      'level': level.name,
      'event': event,
      'extra': Observability.sanitize(extra),
      if (error != null) 'error': error.toString(),
    });
  }

  @override
  void track(String event, {Map<String, Object?> extra = const {}}) {
    _post('/api/v1/telemetry/analytics', {
      'event': event,
      'extra': Observability.sanitize(extra),
    });
  }

  @override
  void record(
    Object error,
    StackTrace stackTrace, {
    Map<String, Object?> extra = const {},
  }) {
    _post('/api/v1/telemetry/crashes', {
      'error': error.toString(),
      'stack': stackTrace.toString(),
      'extra': Observability.sanitize(extra),
    });
  }

  void dispose() => _client.close();
}
