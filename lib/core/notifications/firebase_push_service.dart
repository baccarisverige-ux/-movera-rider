import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:movera_rider/app/config/env.dart';
import 'package:movera_rider/core/api/api_client.dart';
import 'package:movera_rider/core/logging/app_log.dart';
import 'package:movera_rider/core/notifications/push_service.dart';

enum PushAuthorizationStatus { authorized, provisional, denied }

abstract interface class FirebasePushGateway {
  Future<void> initialize(AppEnv environment);
  Future<PushAuthorizationStatus> requestPermission();
  Future<void> ensureAppleTransportReady();
  Future<String?> getToken({String? vapidKey});
  Stream<String> get onTokenRefresh;
  Future<void> deleteToken();
}

class FlutterFirebasePushGateway implements FirebasePushGateway {
  FlutterFirebasePushGateway({FirebaseMessaging? messaging})
      : _messagingOverride = messaging;

  final FirebaseMessaging? _messagingOverride;
  FirebaseMessaging get _messaging =>
      _messagingOverride ?? FirebaseMessaging.instance;

  @override
  Future<void> initialize(AppEnv environment) async {
    if (Firebase.apps.isNotEmpty) return;
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: environment.firebaseApiKey,
        appId: environment.firebaseAppId,
        messagingSenderId: environment.firebaseMessagingSenderId,
        projectId: environment.firebaseProjectId,
      ),
    );
  }

  @override
  Future<PushAuthorizationStatus> requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    switch (settings.authorizationStatus) {
      case AuthorizationStatus.authorized:
        return PushAuthorizationStatus.authorized;
      case AuthorizationStatus.provisional:
        return PushAuthorizationStatus.provisional;
      case AuthorizationStatus.denied:
      case AuthorizationStatus.notDetermined:
        return PushAuthorizationStatus.denied;
    }
  }

  @override
  Future<void> ensureAppleTransportReady() async {
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.iOS &&
            defaultTargetPlatform != TargetPlatform.macOS)) {
      return;
    }
    for (var attempt = 0; attempt < 10; attempt += 1) {
      final token = await _messaging.getAPNSToken();
      if (token != null && token.trim().isNotEmpty) return;
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
    throw const PushRegistrationException(
      'APNs token is not available yet.',
    );
  }

  @override
  Future<String?> getToken({String? vapidKey}) =>
      _messaging.getToken(vapidKey: vapidKey);

  @override
  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;

  @override
  Future<void> deleteToken() => _messaging.deleteToken();
}

class FirebasePushService implements PushService {
  FirebasePushService({
    required ApiClient api,
    required AppEnv environment,
    FirebasePushGateway? gateway,
  })  : _api = api,
        _environment = environment,
        _gateway = gateway ?? FlutterFirebasePushGateway();

  final ApiClient _api;
  final AppEnv _environment;
  final FirebasePushGateway _gateway;
  StreamSubscription<String>? _tokenSub;
  String? _registeredToken;

  @override
  Future<void> register() async {
    if (!_environment.hasFirebaseConfig) {
      throw const PushConfigurationException(
        'Firebase push configuration is missing.',
      );
    }
    if (kIsWeb && _environment.firebaseVapidKey.trim().isEmpty) {
      throw const PushConfigurationException(
        'Firebase web push VAPID key is missing.',
      );
    }

    await _gateway.initialize(_environment);
    final permission = await _gateway.requestPermission();
    if (permission == PushAuthorizationStatus.denied) {
      throw const PushPermissionDeniedException();
    }

    await _gateway.ensureAppleTransportReady();
    final token = await _gateway.getToken(
      vapidKey: kIsWeb ? _environment.firebaseVapidKey : null,
    );
    if (token == null || token.trim().isEmpty) {
      throw const PushRegistrationException(
        'Firebase did not return a device token.',
      );
    }

    await _replaceToken(token.trim());
    await _tokenSub?.cancel();
    _tokenSub = _gateway.onTokenRefresh.listen((next) {
      final normalized = next.trim();
      if (normalized.isEmpty || normalized == _registeredToken) return;
      unawaited(
        _replaceToken(normalized).catchError((Object error, StackTrace stack) {
          AppLog.error(
            'push.token_refresh_failed',
            error: error,
            stackTrace: stack,
          );
        }),
      );
    });
  }

  Future<void> _replaceToken(String token) async {
    final previous = _registeredToken;
    if (previous != null && previous != token) {
      await _unregisterToken(previous);
    }

    final response = await _api.post(
      '/api/v1/push/devices',
      body: {
        'token': token,
        'provider': 'fcm',
        'platform': _platformName,
      },
    );
    if (response['code'] != 'OK' || response['status'] != 'registered') {
      throw const PushRegistrationException(
        'Push token registration was not acknowledged.',
      );
    }
    _registeredToken = token;
  }

  Future<void> _unregisterToken(String token) async {
    final response = await _api.post(
      '/api/v1/push/devices/unregister',
      body: {'token': token},
    );
    if (response['code'] != 'OK' || response['status'] != 'unregistered') {
      throw const PushRegistrationException(
        'Push token removal was not acknowledged.',
      );
    }
    if (_registeredToken == token) _registeredToken = null;
  }

  @override
  Future<void> unregister() async {
    await _tokenSub?.cancel();
    _tokenSub = null;
    final token = _registeredToken;
    if (token != null) {
      await _unregisterToken(token);
    }
    await _gateway.deleteToken();
  }

  Future<void> dispose() async {
    await _tokenSub?.cancel();
    _tokenSub = null;
  }

  String get _platformName {
    if (kIsWeb) return 'web';
    return defaultTargetPlatform.name;
  }
}

class PushConfigurationException implements Exception {
  const PushConfigurationException(this.message);
  final String message;

  @override
  String toString() => 'PushConfigurationException($message)';
}

class PushPermissionDeniedException implements Exception {
  const PushPermissionDeniedException();

  @override
  String toString() => 'PushPermissionDeniedException';
}

class PushRegistrationException implements Exception {
  const PushRegistrationException(this.message);
  final String message;

  @override
  String toString() => 'PushRegistrationException($message)';
}
