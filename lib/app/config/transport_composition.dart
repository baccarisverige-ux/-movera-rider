import 'package:movera_rider/app/config/env.dart';
import 'package:movera_rider/core/api/api_client.dart';
import 'package:movera_rider/core/notifications/push_service.dart';
import 'package:movera_rider/core/payments/mock_payment_gateway.dart';
import 'package:movera_rider/core/payments/payment_gateway.dart';
import 'package:movera_rider/core/realtime/mock_ride_realtime.dart';
import 'package:movera_rider/core/realtime/ride_realtime.dart';
import 'package:movera_rider/core/observability/observability.dart';
import 'package:movera_rider/features/safety/application/emergency_call_service.dart';

abstract final class TransportComposition {
  static void validate({
    required AppEnv environment,
    required ApiClient api,
    required RideRealtime realtime,
    required PaymentGateway paymentGateway,
    required PushService push,
    required EmergencyDialer emergencyDialer,
    required LoggerSink logger,
    required AnalyticsSink analytics,
    required CrashSink crashes,
    required bool usesMockDriverAssignment,
  }) {
    if (environment.allowsMockTransport) return;

    final mockSurfaces = <String>[
      if (api.usesMockTransport) 'api',
      if (realtime is MockRideRealtime) 'realtime',
      if (paymentGateway is MockPaymentGateway) 'payments',
      if (push is NoopPushService || push is UnavailablePushService) 'push',
      if (emergencyDialer is RecordingEmergencyDialer) 'emergencyDialer',
      if (logger is NoopLoggerSink) 'logger',
      if (analytics is NoopAnalyticsSink) 'analytics',
      if (crashes is NoopCrashSink) 'crashes',
      if (usesMockDriverAssignment) 'driverAssignment',
    ];

    if (mockSurfaces.isNotEmpty) {
      throw StateError(
        'Mock/no-op transport is forbidden for '
        '${environment.flavor.name}: ${mockSurfaces.join(', ')}',
      );
    }
  }
}
