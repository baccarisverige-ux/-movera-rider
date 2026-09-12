import 'package:movera_rider/features/support/domain/support.dart';

class SupportChatScript {
  const SupportChatScript({
    required this.welcome,
    this.issueAck =
        'Thanks, I looked at this trip. Tell me a bit more and a Movera agent will take it from here.',
    this.followUp =
        'Got it. A Movera agent can follow up on this. You’ll also find the case under Messages.',
  });

  final String welcome;
  final String issueAck;
  final String followUp;
}

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

  SupportChatScript chat({SupportRide? ride}) {
    if (ride == null) {
      return const SupportChatScript(
        welcome: 'Hi, welcome to Movera support.\n\nHow can we help today?',
      );
    }
    if (ride.cancelled) {
      return const SupportChatScript(
        welcome:
            'Hi, welcome to Movera support.\n\nI checked this ride and you were not charged for it. If you’d like to share feedback about the driver or vehicle, choose an option below.',
      );
    }
    return SupportChatScript(
      welcome: 'Hey! How can we help with your ride to ${ride.title}?',
    );
  }
}
