import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
void main() {
  test('observability exposes logger analytics crash seams and secret scrubbing', () {
    final s=File('lib/core/observability/observability.dart').readAsStringSync();
    expect(s, contains('abstract class LoggerSink'));
    expect(s, contains('abstract class AnalyticsSink'));
    expect(s, contains('abstract class CrashSink'));
    expect(s, contains("'accessToken'"));
    expect(s, contains("'refreshToken'"));
    expect(s, contains("'cardNumber'"));
  });
  test('push remains replaceable and live provider is not fabricated', () {
    final s=File('lib/core/notifications/push_service.dart').readAsStringSync();
    expect(s, contains('abstract class PushService'));
    expect(s, contains('Live FCM/APNs is not connected yet'));
    expect(s, contains('class NoopPushService'));
  });
}
