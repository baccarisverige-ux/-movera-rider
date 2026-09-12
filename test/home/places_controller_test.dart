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
}
