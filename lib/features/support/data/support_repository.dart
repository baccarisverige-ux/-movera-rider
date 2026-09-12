import 'package:movera_rider/features/support/domain/support.dart';

class SupportRepository {
  List<SupportRide> rides() => [
        SupportRide(
          title: 'Alby Centrum',
          when: DateTime(2026, 9, 1, 15, 40),
          price: 211,
          image: 'assets/images/rides/comfort.png',
        ),
        SupportRide(
          title: 'Fotoautomat Arlanda Terminal 5',
          when: DateTime(2026, 8, 30, 21, 25),
          price: 0,
          image: 'assets/images/rides/electric.png',
          cancelled: true,
          extra: '2 drivers',
        ),
        SupportRide(
          title: 'Klockarvägen 37, Södertälje 15159',
          when: DateTime(2026, 8, 31, 17, 0),
          price: 229,
          image: 'assets/images/rides/movera.png',
        ),
        SupportRide(
          title: 'Fotoautomat Arlanda Terminal 5',
          when: DateTime(2026, 8, 30, 21, 21),
          price: 0,
          image: 'assets/images/rides/movera.png',
          cancelled: true,
        ),
        SupportRide(
          title: 'Bilia Länna Mercedes-Benz',
          when: DateTime(2026, 6, 3, 16, 29),
          price: 463,
          image: 'assets/images/rides/xl.png',
        ),
        SupportRide(
          title: 'Bilia Södertälje – Mercedes-Benz',
          when: DateTime(2025, 10, 29, 15, 32),
          price: 0,
          image: 'assets/images/rides/premium.png',
          failed: true,
        ),
      ];
}
