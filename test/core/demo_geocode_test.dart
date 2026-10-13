import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:movera_rider/core/api/in_process_mock_client.dart';

/// The demo transport geocodes its known places to where they really are, so
/// a typed "Arlanda" is not placed next to Stockholm Central.
void main() {
  Future<Map<String, dynamic>> geocode(String query) async {
    final client = InProcessMockClient();
    final response = await client.post(
      Uri.parse('https://demo.movera/api/v1/locations/geocode'),
      headers: {'content-type': 'application/json'},
      body: jsonEncode({'query': query}),
    );
    return (jsonDecode(response.body) as Map<String, dynamic>)['data']
        as Map<String, dynamic>;
  }

  test('a known demo place geocodes to its real point', () async {
    final data = await geocode('Arlanda');
    expect(data['latitude'], closeTo(59.65, 0.01));
    expect(data['longitude'], closeTo(17.92, 0.01));
    expect(data['address'], 'Arlanda');
  });

  test('unknown text still gets a stable demo point near Stockholm', () async {
    final a = await geocode('Somewhere unknown 12');
    final b = await geocode('Somewhere unknown 12');
    expect(a['latitude'], b['latitude']);
    expect(a['latitude'], closeTo(59.33, 0.01));
    expect(a['address'], 'Somewhere unknown 12');
  });
}
