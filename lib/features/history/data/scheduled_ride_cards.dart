class ScheduledRideCard {
  const ScheduledRideCard({
    required this.car,
    required this.when,
    required this.status,
  });

  final String car;
  final String when;
  final String status;
}

class ScheduledRideCatalog {
  List<ScheduledRideCard> confirmed() => const [
        ScheduledRideCard(
          car: 'BMW X7',
          when: '10 Jun 25, 10:30 am',
          status: 'Confirmed',
        ),
        ScheduledRideCard(
          car: 'BMW X7',
          when: '10 Jun 25, 10:30 am',
          status: 'Confirmed',
        ),
      ];

  ScheduledRideCard pending() => const ScheduledRideCard(
        car: 'BMW X7',
        when: '10 Jun 25, 10:30 am',
        status: 'Pending',
      );
}
