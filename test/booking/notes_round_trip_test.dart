import 'package:flutter_test/flutter_test.dart';
import 'package:movera_rider/app/di.dart';
import 'package:movera_rider/core/api/api_client.dart';
import 'package:movera_rider/core/api/in_process_mock_client.dart';
import 'package:movera_rider/features/booking/application/booking_coordinator.dart';
import 'package:movera_rider/features/finding_driver/application/finding_driver_controller.dart';
import 'package:movera_rider/features/ride_booking/data/ride_snapshot_store.dart';
import 'package:movera_rider/features/ride_booking/domain/ride_notes.dart';
import 'package:movera_rider/features/ride_booking/domain/ride_status.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Bags, pet, baby and child are accessibility and safety options. They were
/// collected from the rider, shown back to them, and then dropped: the booking
/// POST carried nine fields and none of them was notes, and the first saved
/// snapshot omitted them too.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FindingDriverController.active = null;
    AppScope.instance.ride.restoreFromBackend(RideStatus.idle);
    AppScope.instance.ride.rideId = null;
  });

  const notes = RideNotes(bags: true, pet: true, baby: false, child: true);

  test('the booking request carries the rider notes', () async {
    final mock = InProcessMockClient();
    final booking = BookingCoordinator(api: ApiClient(client: mock));

    final rideId = await booking.submitFinding(
      pickupAddress: 'Sveavägen 1',
      destinationAddress: 'Hornsgatan 2',
      pickupLat: 59.34,
      pickupLng: 18.05,
      destinationLat: 59.31,
      destinationLng: 18.04,
      rideType: 'Movera',
      price: 259,
      paymentMethod: 'Apple Pay',
      notes: notes,
    );

    // Read the ride back out of the stand-in backend: the notes must have
    // survived the request, not just the widget that collected them.
    final stored = await ApiClient(client: mock).get('/api/v1/rides/$rideId');
    final ride = Map<String, dynamic>.from(stored['ride'] as Map);
    expect(
      ride['notes'],
      isNotNull,
      reason: 'the ride was stored without notes',
    );
    final sent = Map<String, dynamic>.from(ride['notes'] as Map);
    expect(sent['bags'], isTrue);
    expect(sent['pet'], isTrue);
    expect(sent['child'], isTrue);
    expect(sent['baby'], isFalse);
  });

  test('the first saved snapshot already has the notes', () async {
    final booking = BookingCoordinator();

    await booking.submitFinding(
      pickupAddress: 'Sveavägen 1',
      destinationAddress: 'Hornsgatan 2',
      pickupLat: 59.34,
      pickupLng: 18.05,
      destinationLat: 59.31,
      destinationLng: 18.04,
      rideType: 'Movera',
      price: 259,
      paymentMethod: 'Apple Pay',
      notes: notes,
    );

    // Not after a later tick — immediately, so a reload in the first minute
    // does not lose them.
    final saved = await RideSnapshotStore.read();
    expect(saved, isNotNull);
    expect(saved!.notes.bags, isTrue);
    expect(saved.notes.pet, isTrue);
    expect(saved.notes.child, isTrue);
    expect(saved.notes.baby, isFalse);
  });

  test('a booking with no notes still works', () async {
    final booking = BookingCoordinator();
    final id = await booking.submitFinding(
      pickupAddress: 'A',
      destinationAddress: 'B',
      pickupLat: 59.34,
      pickupLng: 18.05,
      destinationLat: 59.31,
      destinationLng: 18.04,
      rideType: 'Movera',
      price: 259,
      paymentMethod: 'Cash',
    );
    expect(id, isNotEmpty);
    expect((await RideSnapshotStore.read())?.notes.selected, isEmpty);
  });
}
