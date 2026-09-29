import 'package:flutter_test/flutter_test.dart';
import 'package:movera_rider/features/ride_selection/presentation/select_ride_filter.dart';

typedef _Ride = ({String id, int eta, double price});

void main() {
  const rides = <_Ride>[
    (id: 'standard', eta: 8, price: 259),
    (id: 'comfort', eta: 11, price: 339),
    (id: 'premium', eta: 11, price: 369),
    (id: 'priority', eta: 6, price: 289),
    (id: 'electric', eta: 9, price: 259),
  ];

  List<String> order(SelectRideFilter filter, [List<_Ride> input = rides]) =>
      orderRidesForFilter<_Ride>(
        input,
        filter,
        etaMin: (r) => r.eta,
        price: (r) => r.price,
      ).map((r) => r.id).toList();

  test('recommended keeps catalog order', () {
    expect(order(SelectRideFilter.recommended), [
      'standard',
      'comfort',
      'premium',
      'priority',
      'electric',
    ]);
  });

  test('faster orders by ETA; equal ETAs keep catalog order', () {
    expect(order(SelectRideFilter.faster), [
      'priority',
      'standard',
      'electric',
      'comfort',
      'premium',
    ]);
  });

  test('cheaper orders by price; equal prices keep catalog order', () {
    expect(order(SelectRideFilter.cheaper), [
      'standard',
      'electric',
      'priority',
      'comfort',
      'premium',
    ]);
  });

  test('never mutates the input and always returns a new list', () {
    final input = [...rides];
    for (final filter in SelectRideFilter.values) {
      final result = orderRidesForFilter<_Ride>(
        input,
        filter,
        etaMin: (r) => r.eta,
        price: (r) => r.price,
      );
      expect(identical(result, input), isFalse, reason: filter.name);
      expect(input, rides, reason: filter.name);
    }
  });
}
