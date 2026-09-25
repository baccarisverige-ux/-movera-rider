import 'package:flutter_test/flutter_test.dart';
import 'package:movera_rider/core/location/geocoding_repository.dart';
import 'package:movera_rider/core/location/location_repository.dart';
import 'package:movera_rider/core/maps/geo_point.dart';
import 'package:movera_rider/core/motion/motion_engine.dart';
import 'package:movera_rider/features/home/application/home_controller.dart';

class _Geo implements GeocodingRepository {
  int calls = 0;

  @override
  Future<PlaceResult?> forward(String query) async {
    calls++;
    await Future<void>.delayed(const Duration(milliseconds: 5));
    return PlaceResult(
      address: 'Normalized $query',
      point: const GeoPoint(59.33, 18.06),
    );
  }

  @override
  Future<String?> reverse(GeoPoint point) async => 'reverse';
}

HomeLocationController _controller(_Geo geo) => HomeLocationController(
  location: const LocationRepository(),
  geocoding: geo,
  motion: MotionEngine(),
);

void main() {
  test('every address in one route batch is normalised', () async {
    final geo = _Geo();
    final controller = _controller(geo);
    addTearDown(controller.dispose);

    final batch = controller.beginNormalisationBatch();
    final result = await Future.wait<String>([
      controller.normaliseAddress('Pickup', generation: batch),
      controller.normaliseAddress('Destination', generation: batch),
      controller.normaliseAddress('Stop 1', generation: batch),
      controller.normaliseAddress('Stop 2', generation: batch),
    ]);

    expect(geo.calls, 4);
    expect(result, const [
      'Normalized Pickup',
      'Normalized Destination',
      'Normalized Stop 1',
      'Normalized Stop 2',
    ]);
  });

  test('a newer route confirmation invalidates an older batch', () async {
    final geo = _Geo();
    final controller = _controller(geo);
    addTearDown(controller.dispose);

    final oldBatch = controller.beginNormalisationBatch();
    final stale = controller.normaliseAddress(
      'Old pickup',
      generation: oldBatch,
    );
    controller.beginNormalisationBatch();

    expect(await stale, 'Old pickup');
  });
}
