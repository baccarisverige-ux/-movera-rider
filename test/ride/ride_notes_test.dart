import 'package:flutter_test/flutter_test.dart';
import 'package:movera_rider/features/finding_driver/application/finding_driver_controller.dart';
import 'package:movera_rider/features/finding_driver/data/finding_driver_repository.dart';
import 'package:movera_rider/core/realtime/mock_ride_realtime.dart';
import 'package:movera_rider/features/ride_booking/application/ride_session.dart';
import 'package:movera_rider/features/ride_booking/data/ride_snapshot_store.dart';
import 'package:movera_rider/features/ride_booking/domain/ride_notes.dart';
import 'package:movera_rider/features/ride_booking/domain/ride_status.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('notes persist on the ride snapshot', () {
    final notes = const RideNotes(bags: true, pet: true);
    final snap = RideSnapshot(
      status: RideStatus.findingDriver,
      savedAt: DateTime.now(),
      pickupAddress: 'A',
      destinationAddress: 'B',
      pickupLat: 59.3,
      pickupLng: 18.0,
      destinationLat: 59.4,
      destinationLng: 18.1,
      rideType: 'Movera',
      price: 259,
      paymentMethod: 'Apple Pay',
      rideId: 'r1',
      notes: notes,
    );
    final roundtrip = RideSnapshot.fromJson(snap.toJson());
    expect(roundtrip?.notes.bags, isTrue);
    expect(roundtrip?.notes.pet, isTrue);
    expect(roundtrip?.notes.baby, isFalse);
    expect(roundtrip?.notes.selected, ['Bags', 'Pet']);
  });

  test('skip keeps empty notes', () {
    expect(RideNotes.empty.isEmpty, isTrue);
    expect(RideNotes.empty.toggle('bags').bags, isTrue);
  });

  test('cancel confirmation path still blocks a later match', () async {
    SharedPreferences.setMockInitialValues({});
    final rt = MockRideRealtime(assignAfter: const Duration(days: 1));
    final ride = RideSession()..rideId = 'r1';
    var matches = 0;
    final controller = FindingDriverController(
      realtime: rt,
      ride: ride,
      store: FindingDriverRepository(),
    );
    controller.start(
      seconds: 12,
      snapshot: RideSnapshot(
        status: RideStatus.findingDriver,
        savedAt: DateTime.now(),
        pickupAddress: 'A',
        destinationAddress: 'B',
        pickupLat: 59.3,
        pickupLng: 18.0,
        destinationLat: 59.4,
        destinationLng: 18.1,
        rideType: 'Movera',
        price: 259,
        paymentMethod: 'Apple Pay',
        rideId: 'r1',
        notes: const RideNotes(child: true),
      ),
      onTick: (_) {},
      onMatched: () => matches += 1,
    );
    controller.cancelSearch();
    rt.emit(RideStatus.driverAssigned, sequence: 4);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(matches, 0);
    controller.dispose();
    rt.dispose();
  });
}
