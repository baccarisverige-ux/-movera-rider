import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
void main() {
  test('auth obtains tokens from API instead of fabricating them', () {
    final s=File('lib/features/auth/data/auth_repository.dart').readAsStringSync();
    expect(s, contains("'/api/v1/auth/provider'"));
    expect(s, contains("'/api/v1/auth/otp/request'"));
    expect(s, contains("'/api/v1/auth/sign-out'"));
    expect(s, isNot(contains("'movera-mock-")));
  });
  test('controller routes OTP through repository', () {
    final s=File('lib/features/auth/application/auth_controller.dart').readAsStringSync();
    expect(s, contains('_auth.requestOtp(phone: normalized)'));
  });
}
