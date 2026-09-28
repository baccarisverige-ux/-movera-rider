import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:movera_rider/core/api/api_error.dart';

/// What the rider was doing when sign-in failed.
enum AuthAction { sendCode, verifyCode, providerSignIn }

/// A specific, honest message for a sign-in failure.
///
/// The old screens said "That verification code is not valid" for every
/// failure, including no connection. Riders now learn whether the code was
/// wrong, expired, rate limited, or never reached the server.
String authErrorMessage(Object error, AuthAction action, {String? provider}) {
  if (_isOffline(error)) {
    return 'No connection. Check your internet and try again.';
  }
  if (error is ApiError) {
    if (error.statusCode == 429 ||
        error.code == 'RATE_LIMITED' ||
        error.code == 'TOO_MANY_REQUESTS') {
      final wait = error.retryAfter;
      return wait == null || wait <= Duration.zero
          ? 'Too many tries. Wait a moment and try again.'
          : 'Too many tries. Try again in ${_seconds(wait)}.';
    }
    switch (error.code) {
      case 'INVALID_OTP':
        return "That code isn't right. Check it and try again.";
      case 'OTP_EXPIRED':
      case 'INVALID_OTP_SESSION':
        return 'This code has expired. Tap Resend code for a new one.';
      case 'INVALID_PHONE':
        return 'Enter a valid Swedish mobile number.';
    }
    if ((error.statusCode ?? 0) >= 500) {
      return 'Movera is having trouble right now. Try again in a moment.';
    }
  }
  return switch (action) {
    AuthAction.sendCode => "Couldn't send the code. Try again.",
    AuthAction.verifyCode => "Couldn't check the code. Try again.",
    AuthAction.providerSignIn =>
      "Couldn't sign in with ${provider ?? 'that account'}. Try again.",
  };
}

bool _isOffline(Object error) {
  if (error is http.ClientException || error is TimeoutException) return true;
  return error is ApiError && (error.code == 'NETWORK' || error.code == 'TIMEOUT');
}

String _seconds(Duration wait) {
  final s = wait.inSeconds + (wait.inMilliseconds % 1000 == 0 ? 0 : 1);
  return s == 1 ? '1 second' : '$s seconds';
}
