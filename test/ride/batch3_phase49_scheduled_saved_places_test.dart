import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:movera_rider/features/reservations/domain/reservation.dart';
import 'package:movera_rider/features/reservations/domain/reservation_status.dart';
import 'package:movera_rider/features/saved_places/data/saved_places_repository.dart';
import 'package:movera_rider/features/saved_places/domain/saved_place.dart';

void main() {
  test('unknown persisted scheduled lifecycle is rejected, not resurrected as scheduled', () {
    final raw = <String, dynamic>{
      'reservationId': 'rsv-49',
      'createdAt': '2026-09-24T00:00:00Z',
      'scheduledPickupAt': '2026-09-25T10:00:00Z',
      'pickup': {'label': 'Pickup'},
      'destination': {'label': 'Destination'},
      'categoryId': 'movera',
      'categoryName': 'Movera',
      'categoryImage': 'ride.webp',
      'price': 200,
      'paymentMethod': 'Card',
      'status': 'future_backend_status',
    };

    expect(ReservationStatus.tryParse('future_backend_status'), isNull);
    expect(Reservation.tryParse(raw), isNull);
  });

  test('saved place shortcuts survive repository restart without seeded demo data', () async {
    final storage = MemorySavedPlacesStorage();
    final first = SavedPlacesRepository(storage: storage);
    await first.save(
      const PlaceShortcut(
        title: 'Home',
        subtitle: 'Klockarvägen 37',
        kind: 'home',
      ),
    );

    final second = SavedPlacesRepository(storage: storage);
    await second.hydrate();

    expect(second.shortcuts(), hasLength(1));
    expect(second.shortcuts().single.title, 'Home');
    expect(second.shortcuts().single.subtitle, 'Klockarvägen 37');
    expect(second.shortcuts().single.kind, 'home');
    final persisted = jsonDecode(storage.value!) as List<dynamic>;
    expect(persisted, hasLength(1));
  });

  test('saving same saved-place kind updates instead of duplicating it', () async {
    final storage = MemorySavedPlacesStorage();
    final repository = SavedPlacesRepository(storage: storage);
    await repository.save(
      const PlaceShortcut(title: 'Home', subtitle: 'Old', kind: 'home'),
    );
    await repository.save(
      const PlaceShortcut(title: 'Home', subtitle: 'New', kind: 'HOME'),
    );

    expect(repository.shortcuts(), hasLength(1));
    expect(repository.shortcuts().single.subtitle, 'New');
  });
}
