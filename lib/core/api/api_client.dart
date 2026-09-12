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
  ApiClient({http.Client? client, AppEnv? env, TokenStore? tokens})
      : _client = client ?? InProcessMockClient(),
        _env = env ?? AppEnv.current,
        _tokens = tokens;

  final http.Client _client;
  final AppEnv _env;
  final TokenStore? _tokens;
  static const _timeout = Duration(seconds: 15);

  Future<Map<String, dynamic>> get(String path) => _send('GET', path);

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    String? idempotencyKey,
  }) {
    return _send('POST', path, body: body, idempotencyKey: idempotencyKey);
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
      late http.Response response;
      if (method == 'GET') {
        response = await _getWithRetry(uri, headers);
      } else {
        response = await _client
            .post(uri, headers: headers, body: jsonEncode(body ?? {}))
            .timeout(_timeout);
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
        throw ApiError(
          code: 'HTTP_${response.statusCode}',
          message: 'Request failed',
          requestId: requestId,
          statusCode: response.statusCode,
        );
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
