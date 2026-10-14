import 'package:flutter_test/flutter_test.dart';
import 'package:movera_rider/features/destination_search/application/compact_address.dart';

void main() {
  test('keeps street and town, drops region, postcode and country', () {
    expect(
      compactAddress(
        'Klockarvägen, Bårsta, Geneta, Södertälje, Södertälje kommun, Stockholms län, 151 62, Sverige',
      ),
      'Klockarvägen, Södertälje',
    );
  });

  test('short addresses stay as they are', () {
    expect(
      compactAddress('Stockholm Arlanda Airport, Arlanda'),
      'Stockholm Arlanda Airport, Arlanda',
    );
    expect(compactAddress('Munkbroleden'), 'Munkbroleden');
    expect(compactAddress('  '), '');
  });

  test('removes repeated parts', () {
    expect(
      compactAddress('Drottninggatan, Stockholm, Stockholm, Sweden'),
      'Drottninggatan, Stockholm',
    );
  });
}
