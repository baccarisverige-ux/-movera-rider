import 'package:flutter_test/flutter_test.dart';
import 'package:movera_rider/features/booking/application/booking_coordinator.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('in-flight finding submit is reused', () async {
    final booking = BookingCoordinator();
    final first = booking.submitFinding(
      pickupAddress: 'A',
      destinationAddress: 'B',
      pickupLat: 59.3,
      pickupLng: 18.0,
      destinationLat: 59.4,
      destinationLng: 18.1,
      rideType: 'Movera',
      price: 259,
      paymentMethod: 'Apple Pay',
    );
    final second = booking.submitFinding(
      pickupAddress: 'A',
      destinationAddress: 'B',
      pickupLat: 59.3,
      pickupLng: 18.0,
      destinationLat: 59.4,
      destinationLng: 18.1,
      rideType: 'Movera',
      price: 259,
      paymentMethod: 'Apple Pay',
    );
    expect(identical(first, second), isTrue);
    expect(await first, await second);
  });

  test('in-flight scheduled booking is reused', () async {
    final booking = BookingCoordinator();
    final first = booking.requestBooking(
      rideType: 'movera',
      paymentMethod: 'Wallet',
      scheduledAt: '2026-09-13T10:00:00Z',
    );
    final second = booking.requestBooking(
      rideType: 'movera',
      paymentMethod: 'Wallet',
      scheduledAt: '2026-09-13T10:00:00Z',
    );
    expect(identical(first, second), isTrue);
    expect(await first, await second);
  });
}
