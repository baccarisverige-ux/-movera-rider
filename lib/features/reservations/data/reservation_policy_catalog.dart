import 'package:movera_rider/features/reservations/domain/reservation_policy.dart';

class ReservationPolicyCatalog {
  static const current = ReservationPolicy(
    version: 'placeholder.v1',
    pricingDisclaimer:
        'Reserved prices can differ from on-demand prices for the same route. The amount shown is your current reserved estimate for this category.',
    assignmentDisclaimer:
        'Driver details will appear here when a driver is assigned.',
    waitingSummary:
        'Be ready at pickup. Included waiting follows Movera scheduled ride terms.',
    cancellationSummary:
        'Cancel from this screen. Any fee follows the scheduled ride terms.',
    pricingSummary:
        'The reserved amount is for this category and route, and updates if the trip changes.',
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
