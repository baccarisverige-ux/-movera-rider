import 'package:movera_rider/features/reservations/domain/reservation_policy.dart';

class ReservationPolicyCatalog {
  static const current = ReservationPolicy(
    version: 'placeholder.v1',
    pricingDisclaimer:
        'Reserved prices can differ from on-demand prices for the same route. The amount shown is your current reserved estimate for this category.',
    assignmentDisclaimer:
        'Driver details will appear here once a driver is assigned. Movera does not promise a specific assignment time in this prototype.',
    waitingSummary:
        'Waiting time included with a scheduled ride will be confirmed in Movera terms when they are published.',
    cancellationSummary:
        'You can cancel a reservation from this screen. Any fee is defined in Movera scheduled ride terms, which are not final yet.',
    pricingSummary:
        'The reserved price covers this category and route. It may change if pickup, destination, or timing changes.',
    sections: [
      ReservationPolicySection(
        title: 'Reservation pricing',
        body:
            'The reserved amount is an estimate for the selected Movera category and route. It can be updated if trip details change before pickup.',
      ),
      ReservationPolicySection(
        title: 'When a driver may be assigned',
        body:
            'A driver is assigned closer to pickup. Until then, your reservation stays confirmed without an active search on the map.',
      ),
      ReservationPolicySection(
        title: 'Included waiting time',
        body:
            'Included waiting time at pickup will be published with the final Movera scheduled ride terms.',
      ),
      ReservationPolicySection(
        title: 'Cancellation window',
        body:
            'You can cancel a reservation from Upcoming ride. Free-cancellation timing will be published with the final terms.',
      ),
      ReservationPolicySection(
        title: 'Possible cancellation fee',
        body:
            'A cancellation fee may apply in some cases. Final amounts are not set in this prototype and will appear here when approved.',
      ),
      ReservationPolicySection(
        title: 'Changes to pickup, time, or destination',
        body:
            'You can edit a reservation by going through pickup, time, and category again. The same reservation ID is kept.',
      ),
      ReservationPolicySection(
        title: 'If a driver cannot be assigned',
        body:
            'If no driver can be assigned, Movera will update this reservation. We do not invent a guaranteed assignment deadline here.',
      ),
      ReservationPolicySection(
        title: 'Promotions',
        body:
            'Eligible promotions, if any, are applied according to Movera rules at the time a driver is assigned.',
      ),
      ReservationPolicySection(
        title: 'Rider responsibilities',
        body:
            'Be ready at the pickup point at the reserved time, keep trip details accurate, and treat drivers with care.',
      ),
    ],
  );
}
