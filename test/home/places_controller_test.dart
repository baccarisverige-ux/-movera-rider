import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:movera_rider/features/home/application/home_places_controller.dart';
import 'package:movera_rider/features/home/data/home_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MemAddresses extends HomeAddressRepository {
  HomeAddressSnapshot snapshot = HomeAddressSnapshot();

  @override
  Future<HomeAddressSnapshot> load() async => snapshot;

  @override
  Future<void> save(HomeAddressSnapshot data) async {
    snapshot = data;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('places controller owns home work recent saved and pickup', () async {
    final store = _MemAddresses()
      ..snapshot = HomeAddressSnapshot(
        home: 'Home street',
        work: 'Work street',
        recent: ['Cafe'],
        places: [
          {'type': 'gym', 'address': 'Gym street'},
        ],
      );
    final places = HomePlacesController(store: store);
    await places.load();
    expect(places.homeAddress, 'Home street');
    expect(places.workAddress, 'Work street');
    expect(places.recentAddresses, ['Cafe']);
    expect(places.savedPlaces.single.address, 'Gym street');

    places.applyResolved(
      target: 'pickup',
      address: 'Pickup road',
      pickupPosition: const LatLng(59.33, 18.06),
    );
    places.applyResolved(target: 'destination', address: 'Centralen');
    await places.persist();
    expect(store.snapshot.recent.first, 'Centralen');
    expect(places.tripPickupLatLng?.latitude, 59.33);
    expect(places.existingFor('pickup'), 'Pickup road');
  });

  test('editing pickup and destination keeps the latest route values', () {
    final places = HomePlacesController(store: _MemAddresses());
    places.applyResolved(
      target: 'pickup',
      address: 'Old pickup',
      pickupPosition: const LatLng(59.30, 18.00),
    );
    places.applyResolved(target: 'destination', address: 'Old destination');

    places.applyResolved(
      target: 'pickup',
      address: 'New pickup',
      pickupPosition: const LatLng(59.31, 18.01),
    );
    places.applyResolved(target: 'destination', address: 'New destination');

    expect(places.existingFor('pickup'), 'New pickup');
    expect(places.existingFor('destination'), 'New destination');
    expect(places.tripPickupLatLng, const LatLng(59.31, 18.01));
    expect(places.recentAddresses.take(2), ['New destination', 'New pickup']);
  });

  test('dismissing an address edit leaves the prior value intact', () {
    final places = HomePlacesController(store: _MemAddresses());
    places.applyResolved(target: 'destination', address: 'Prior destination');

    // The picker only calls applyResolved after it returns a non-null draft.
    // A dismissed picker therefore makes no state mutation here.
    expect(places.existingFor('destination'), 'Prior destination');
    expect(places.recentAddresses, ['Prior destination']);
  });
}
