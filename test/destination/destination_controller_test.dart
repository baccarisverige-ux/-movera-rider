import 'package:flutter_test/flutter_test.dart';
import 'package:movera_rider/features/destination/application/destination_controller.dart';
import 'package:movera_rider/features/destination/data/destination_repository.dart';

/// Phase 141: the destination feature directory had zero test coverage.
/// DestinationController is a thin seam over DestinationRepository (used by
/// home.dart to remember the last confirmed destination for next time).
void main() {
  group('DestinationRepository', () {
    test('remember stores address/lat/lng', () {
      final store = DestinationRepository();
      store.remember(address: 'Arlanda Express', lat: 59.65, lng: 17.93);
      expect(store.lastAddress, 'Arlanda Express');
      expect(store.lastLat, 59.65);
      expect(store.lastLng, 17.93);
    });

    test('a null field leaves the previous value in place', () {
      final store = DestinationRepository();
      store.remember(address: 'First', lat: 1, lng: 2);
      store.remember(address: null, lat: null, lng: 3);
      expect(store.lastAddress, 'First');
      expect(store.lastLat, 1);
      expect(store.lastLng, 3);
    });
  });

  group('DestinationController', () {
    test('remember delegates to its repository', () {
      final store = DestinationRepository();
      final controller = DestinationController(store: store);
      controller.remember(address: 'Klockarvägen 37', lat: 59.19, lng: 17.62);
      expect(store.lastAddress, 'Klockarvägen 37');
      expect(store.lastLat, 59.19);
      expect(store.lastLng, 17.62);
    });

    test('defaults to the shared DestinationRepository.instance', () {
      DestinationRepository.instance.remember(address: 'reset');
      final controller = DestinationController();
      controller.remember(address: 'via default controller');
      expect(
        DestinationRepository.instance.lastAddress,
        'via default controller',
      );
    });
  });
}
