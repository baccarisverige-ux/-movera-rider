import 'package:movera_rider/app/config/env.dart';
import 'package:movera_rider/core/api/api_client.dart';
import 'package:movera_rider/core/notifications/push_service.dart';
import 'package:movera_rider/core/payments/mock_payment_gateway.dart';
import 'package:movera_rider/core/payments/payment_gateway.dart';
import 'package:movera_rider/core/realtime/mock_ride_realtime.dart';
import 'package:movera_rider/core/realtime/ride_realtime.dart';

abstract final class TransportComposition {
  static void validate({
    required AppEnv environment,
    required ApiClient api,
    required RideRealtime realtime,
    required PaymentGateway paymentGateway,
    required PushService push,
  }) {
    if (!environment.isProduction) return;

    final mockSurfaces = <String>[
      if (api.usesMockTransport) 'api',
      if (realtime is MockRideRealtime) 'realtime',
      if (paymentGateway is MockPaymentGateway) 'payments',
      if (push is NoopPushService) 'push',
    ];

    if (mockSurfaces.isNotEmpty) {
      throw StateError(
        'Production transport composition is incomplete: '
        '${mockSurfaces.join(', ')}',
      );
    }
  }
}
