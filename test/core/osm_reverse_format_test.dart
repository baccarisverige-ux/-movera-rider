import 'package:flutter_test/flutter_test.dart';
import 'package:movera_rider/core/location/web_reverse_geocode.dart';

void main() {
  test('street, number, area and city read like a Swedish address', () {
    expect(
      formatOpenStreetMapAddress({
        'road': 'Klockarvägen',
        'house_number': '37',
        'suburb': 'Geneta',
        'city': 'Södertälje',
        'country': 'Sverige',
      }),
      'Klockarvägen 37, Geneta, Södertälje',
    );
  });

  test('missing parts are skipped and a duplicated city is not repeated', () {
    expect(
      formatOpenStreetMapAddress({'road': 'Storgatan', 'town': 'Nyköping'}),
      'Storgatan, Nyköping',
    );
    expect(
      formatOpenStreetMapAddress({
        'suburb': 'Centrum',
        'city': 'Centrum',
      }),
      'Centrum',
    );
    expect(formatOpenStreetMapAddress({'country': 'Sverige'}), isNull);
  });
}
