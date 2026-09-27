import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:movera_rider/app/config/env.dart';
import 'package:movera_rider/core/api/api_error.dart';
import 'package:movera_rider/core/api/in_process_mock_client.dart';
import 'package:movera_rider/core/auth/token_store.dart';
import 'package:movera_rider/core/logging/app_log.dart';
import 'package:movera_rider/core/utils/request_id.dart';

class ApiClient {
  ApiClient({
    http.Client? client,
    AppEnv? env,
    TokenStore? tokens,
    Future<void> Function()? onSessionExpired,
  })
      : _env = env ?? AppEnv.current,
        _client = client ?? _defaultClient(env ?? AppEnv.current),
        _tokens = tokens,
        _onSessionExpired = onSessionExpired;

  static http.Client _defaultClient(AppEnv env) {
    return env.allowsMockTransport ? InProcessMockClient() : http.Client();
  }

  bool get usesMockTransport => _client is InProcessMockClient;

  final http.Client _client;
  final AppEnv _env;
  final TokenStore? _tokens;
  final Future<void> Function()? _onSessionExpired;
  Future<String?>? _refreshInFlight;
  static const _timeout = Duration(seconds: 15);

  Future<Map<String, dynamic>> get(String path) => _send('GET', path);

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    String? idempotencyKey,
  }) {
    return _send('POST', path, body: body, idempotencyKey: idempotencyKey);
  }

  Future<Map<String, dynamic>> patch(
    String path, {
    Map<String, dynamic>? body,
    String? idempotencyKey,
  }) {
    return _send('PATCH', path, body: body, idempotencyKey: idempotencyKey);
  }

  Future<Map<String, dynamic>> delete(
    String path, {
    Map<String, dynamic>? body,
    String? idempotencyKey,
  }) {
    return _send('DELETE', path, body: body, idempotencyKey: idempotencyKey);
  }

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    String? idempotencyKey,
  }) async {
    final requestId = newRequestId();
    final uri = Uri.parse('${_env.apiBaseUrl}$path');
    try {
      final access = await _tokens?.readAccess();
      final headers = <String, String>{
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'X-Request-Id': requestId,
        'X-Api-Version': 'v1',
        if (access != null) 'Authorization': 'Bearer $access',
        if (idempotencyKey != null) 'Idempotency-Key': idempotencyKey,
      };
      var response = await _request(method, uri, headers, body);
      if (response.statusCode == 401 && access?.isNotEmpty == true) {
        // An OTP rejection is not an expired session. Only requests that
        // carried an access token enter the refresh/retry path.
        final replacement = await _refreshAccess(access!);
        if (replacement != null) {
          response = await _request(method, uri, {
            ...headers,
            'Authorization': 'Bearer $replacement',
          }, body);
        }
        if (replacement == null || response.statusCode == 401) {
          await _expireSession();
        }
      }
      AppLog.info(
        'api.$method',
        extra: {
          'path': path,
          'requestId': requestId,
          'status': response.statusCode,
        },
      );
      if (response.statusCode >= 400) {
        throw _errorFromResponse(response, requestId);
      }
      if (response.body.isEmpty) return {'requestId': requestId};
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
      return {'data': decoded, 'requestId': requestId};
    } on TimeoutException {
      AppLog.error('api.timeout', extra: {'path': path, 'requestId': requestId});
      throw ApiError(
        code: 'TIMEOUT',
        message: 'Request timed out',
        requestId: requestId,
      );
    }
  }

  Future<http.Response> _request(
    String method,
    Uri uri,
    Map<String, String> headers,
    Map<String, dynamic>? body,
  ) async {
      if (method == 'GET') {
        return _getWithRetry(uri, headers);
      } else if (method == 'DELETE') {
        return _client
            .send(
              http.Request('DELETE', uri)..headers.addAll(headers),
            )
            .then(http.Response.fromStream)
            .timeout(_timeout);
      } else {
        final request = http.Request(method, uri)
          ..headers.addAll(headers)
          ..body = jsonEncode(body ?? {});
        return _client
            .send(request)
            .then(http.Response.fromStream)
            .timeout(_timeout);
      }
  }

  Future<String?> _refreshAccess(String failedAccess) async {
    final active = _refreshInFlight;
    if (active != null) return active;
    final pending = _performRefresh(failedAccess);
    _refreshInFlight = pending;
    try {
      return await pending;
    } finally {
      _refreshInFlight = null;
    }
  }

  Future<String?> _performRefresh(String failedAccess) async {
    final current = await _tokens?.readAccess();
    if (current != null && current != failedAccess) return current;
    final refresh = await _tokens?.readRefresh();
    if (refresh == null || refresh.isEmpty) return null;
    try {
      final response = await _client.post(
        Uri.parse('${_env.apiBaseUrl}/api/v1/auth/refresh'),
        headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refresh}),
      ).timeout(_timeout);
      if (response.statusCode != 200) return null;
      final payload = jsonDecode(response.body);
      if (payload is! Map<String, dynamic>) return null;
      final access = payload['accessToken'];
      final nextRefresh = payload['refreshToken'];
      if (access is! String || access.isEmpty ||
          nextRefresh is! String || nextRefresh.isEmpty) return null;
      await _tokens?.save(access: access, refresh: nextRefresh);
      return access;
    } catch (_) {
      return null;
    }
  }

  Future<void> _expireSession() async {
    await _tokens?.clear();
    await _onSessionExpired?.call();
  }

  ApiError _errorFromResponse(http.Response response, String requestId) {
    String code = 'HTTP_${response.statusCode}';
    String message = 'Request failed';
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        final rawCode = decoded['code'] ?? decoded['error'];
        final rawMessage = decoded['message'];
        if (rawCode is String && rawCode.trim().isNotEmpty) code = rawCode.trim();
        if (rawMessage is String && rawMessage.trim().isNotEmpty) {
          message = rawMessage.trim();
        }
      }
    } catch (_) {
      // Non-JSON error bodies still retain the HTTP status and request id.
    }
    final retrySeconds = int.tryParse(response.headers['retry-after'] ?? '');
    return ApiError(
      code: code,
      message: message,
      requestId: requestId,
      statusCode: response.statusCode,
      retryAfter: retrySeconds == null ? null : Duration(seconds: retrySeconds),
    );
  }

  Future<http.Response> _getWithRetry(
    Uri uri,
    Map<String, String> headers,
  ) async {
    Object? lastError;
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        return await _client.get(uri, headers: headers).timeout(_timeout);
      } on TimeoutException catch (error) {
        lastError = error;
      }
    }
    throw lastError ?? TimeoutException('GET retry failed');
  }
}
