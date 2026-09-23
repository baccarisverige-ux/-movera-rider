import 'package:movera_rider/app/config/env.dart';
import 'package:movera_rider/core/api/api_client.dart';
import 'package:movera_rider/core/notifications/push_service.dart';
import 'package:movera_rider/core/payments/mock_payment_gateway.dart';
import 'package:movera_rider/core/payments/payment_gateway.dart';
import 'package:movera_rider/core/realtime/mock_ride_realtime.dart';
import 'package:movera_rider/core/realtime/ride_realtime.dart';

abstract final class AppTransportGuard {
  static void validate({
    required AppEnv env,
    required ApiClient api,
    required RideRealtime realtime,
    required PaymentGateway payments,
    required PushService push,
  }) {
    if (env.allowsMockTransport) return;

    final violations = <String>[
      if (api.usesMockTransport) 'api',
      if (realtime is MockRideRealtime) 'realtime',
      if (payments is MockPaymentGateway) 'payments',
      if (push is NoopPushService) 'push',
    ];

    if (violations.isNotEmpty) {
      throw StateError(
        'Mock/no-op transports are forbidden for ${env.flavor.name}: '
        '${violations.join(', ')}',
      );
    }
  }
}
