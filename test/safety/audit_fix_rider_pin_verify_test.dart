import 'package:flutter_test/flutter_test.dart';
import 'package:movera_rider/app/config/env.dart';
import 'package:movera_rider/core/api/api_client.dart';
import 'package:movera_rider/core/api/api_error.dart';
import 'package:movera_rider/core/api/in_process_mock_client.dart';

/// ARCH-22: verifying a ride PIN is the driver app's call
/// (docs/ride-pin-backend-contract.md section 3). The rider mock contract
/// no longer offers it, so nothing in the rider app can depend on it.
void main() {
  test('the rider mock has no PIN verify route', () async {
    final api = ApiClient(
      client: InProcessMockClient(),
      env: const AppEnv(
        flavor: AppFlavor.demo,
        apiBaseUrl: 'https://api.demo.movera.invalid',
      ),
    );
    await expectLater(
      api.post('/api/v1/rides/ride_1/pin/verify', body: {'pin': '1234'}),
      throwsA(isA<ApiError>().having((e) => e.statusCode, 'status', 404)),
    );
    // The rider still reads and rotates their PIN.
    final pin = await api.get('/api/v1/safety/pin');
    expect(pin['code'], 'OK');
  });
}
