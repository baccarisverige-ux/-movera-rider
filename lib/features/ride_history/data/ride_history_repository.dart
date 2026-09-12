import 'package:movera_rider/features/ride_history/domain/ride_history.dart';

class RideHistoryRepository {
  List<RideHistoryItem> past() => const [
        RideHistoryItem(
          title: 'Alby Centrum',
          when: DateTime(2026, 9, 1, 15, 40),
          price: 211,
          image: 'assets/images/rides/movera.png',
          featured: true,
        ),
        RideHistoryItem(
          title: 'Klockarvägen 37, Södertälje',
          when: DateTime(2026, 8, 31, 17, 0),
          price: 229,
          image: 'assets/images/rides/comfort.png',
        ),
        RideHistoryItem(
          title: 'Alby Centrum',
          when: DateTime(2026, 8, 24, 17, 31),
          price: 157,
          image: 'assets/images/rides/movera.png',
        ),
        RideHistoryItem(
          title: 'Alby Centrum',
          when: DateTime(2026, 8, 24, 17, 22),
          price: 0,
          image: 'assets/images/rides/electric.png',
          cancelled: true,
        ),
        RideHistoryItem(
          title: 'Klockarvägen 37, Södertälje',
          when: DateTime(2026, 8, 17, 17, 10),
          price: 199,
          image: 'assets/images/rides/premium.png',
        ),
        RideHistoryItem(
          title: 'Bilia Länna Mercedes-Benz',
          when: DateTime(2026, 6, 3, 16, 29),
          price: 463,
          image: 'assets/images/rides/xl.png',
        ),
        RideHistoryItem(
          title: 'Bilia Södertälje – Mercedes-Benz',
          when: DateTime(2025, 10, 29, 14, 10),
          price: 0,
          image: 'assets/images/rides/movera.png',
          cancelled: true,
        ),
      ];
}
