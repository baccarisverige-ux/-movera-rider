import 'package:flutter_test/flutter_test.dart';
import 'package:movera_rider/app/config/env.dart';
import 'package:movera_rider/core/api/api_client.dart';
import 'package:movera_rider/core/api/api_error.dart';
import 'package:movera_rider/core/api/in_process_mock_client.dart';
import 'package:movera_rider/core/auth/token_store.dart';
import 'package:movera_rider/features/auth/data/auth_repository.dart';
import 'package:movera_rider/features/auth/domain/otp_challenge.dart';
import 'package:movera_rider/features/auth/presentation/sign_in.dart';
import 'package:movera_rider/features/finding_driver/presentation/finding_drivers.dart';
import 'package:movera_rider/features/ride_booking/application/ride_restore_coordinator.dart';
import 'package:movera_rider/features/ride_booking/data/ride_snapshot_store.dart';
import 'package:movera_rider/features/ride_booking/domain/ride_status.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const testEnv = AppEnv(
    flavor: AppFlavor.test,
    apiBaseUrl: 'https://api.test.movera.invalid',
    mapsEnabled: true,
  );

  test('OTP request returns session, expiry, retry window and saves no tokens', () async {
    final tokens = MemoryTokenStore();
    final auth = AuthRepository(
      api: ApiClient(
        env: testEnv,
        client: InProcessMockClient(),
        tokens: tokens,
      ),
      tokens: tokens,
    );

    final challenge = await auth.requestOtp(phone: '+46701234567');

    expect(challenge.phone, '+46701234567');
    expect(challenge.requestId, isNotEmpty);
    expect(challenge.sessionId, isNotEmpty);
    expect(challenge.expiresAt.isAfter(DateTime.now().toUtc()), isTrue);
    expect(challenge.retryAfter, greaterThan(Duration.zero));
    expect(await tokens.readAccess(), isNull);
    expect(await tokens.readRefresh(), isNull);
  });

  test('wrong OTP never authenticates or persists tokens', () async {
    final tokens = MemoryTokenStore();
    final auth = AuthRepository(
      api: ApiClient(
        env: testEnv,
        client: InProcessMockClient(),
        tokens: tokens,
      ),
      tokens: tokens,
    );
    final challenge = await auth.requestOtp(phone: '+46701234567');

    await expectLater(
      auth.verifyOtp(challenge: challenge, code: '9999'),
      throwsA(
        isA<ApiError>().having(
          (error) => error.code,
          'code',
          'INVALID_OTP',
        ),
      ),
    );

    expect(await tokens.readAccess(), isNull);
    expect(await tokens.readRefresh(), isNull);
  });

  test('verified OTP persists tokens only after backend success', () async {
    final tokens = MemoryTokenStore();
    final auth = AuthRepository(
      api: ApiClient(
        env: testEnv,
        client: InProcessMockClient(),
        tokens: tokens,
      ),
      tokens: tokens,
    );
    final challenge = await auth.requestOtp(phone: '+46701234567');

    await auth.verifyOtp(challenge: challenge, code: '1234');

    expect(await tokens.readAccess(), startsWith('mock-access-phone-'));
    expect(await tokens.readRefresh(), startsWith('mock-refresh-phone-'));
  });

  test('auth gate blocks Home when enabled and session is missing', () async {
    final coordinator = RideRestoreCoordinator(
      reader: () async => null,
      authRequired: () => true,
      hasSession: () async => false,
    );

    final root = await coordinator.root();

    expect(root, isA<SignIn>());
  });

  test('active ride restore wins over auth gate', () async {
    final snapshot = RideSnapshot(
      status: RideStatus.findingDriver,
      savedAt: DateTime.now(),
      pickupAddress: 'Pickup',
      destinationAddress: 'Destination',
      pickupLat: 59.33,
      pickupLng: 18.06,
      destinationLat: 59.34,
      destinationLng: 18.08,
      rideType: 'Movera',
      price: 180,
      paymentMethod: 'card',
      rideId: 'ride_phase73',
    );
    final coordinator = RideRestoreCoordinator(
      reader: () async => snapshot,
      authRequired: () => true,
      hasSession: () async => false,
      resync: (_) async {},
    );

    final root = await coordinator.root();

    expect(root, isA<FindingDrivers>());
  });

  test('expired OTP challenge is rejected before verify transport', () {
    final challenge = OtpChallenge(
      phone: '+46701234567',
      requestId: 'req_expired',
      sessionId: 'otp_expired',
      expiresAt: DateTime.now().toUtc().subtract(const Duration(seconds: 1)),
      retryAfter: const Duration(seconds: 30),
    );

    expect(challenge.isExpired, isTrue);
  });
}
