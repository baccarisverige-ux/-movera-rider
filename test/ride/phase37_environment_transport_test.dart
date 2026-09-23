import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
void main() {
  test('production composition rejects mock transports', () {
    final env=File('lib/app/config/env.dart').readAsStringSync();
    final comp=File('lib/app/config/transport_composition.dart').readAsStringSync();
    final api=File('lib/core/api/api_client.dart').readAsStringSync();
    expect(env, contains('bool get allowsMockTransport'));
    expect(api, contains('_defaultClient(env ?? AppEnv.current)'));
    expect(comp, contains("if (api.usesMockTransport) 'api'"));
    expect(comp, contains("if (realtime is MockRideRealtime) 'realtime'"));
    expect(comp, contains("if (paymentGateway is MockPaymentGateway) 'payments'"));
    expect(comp, contains("if (push is NoopPushService) 'push'"));
  });
}
