import 'package:movera_rider/features/reservations/domain/reservation_policy.dart';

class ReservationPolicyCatalog {
  static const current = ReservationPolicy(
    version: 'unpublished.v1',
    pricingDisclaimer:
        'Reserved prices can differ from on-demand prices for the same route. The amount shown is your current reserved estimate for this category.',
    assignmentDisclaimer:
        'Driver details will appear here if an assignment is confirmed.',
    waitingSummary:
        'No included waiting period is currently published.',
    cancellationSummary:
        'No cancellation window or fee is currently published.',
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
            'Assignment timing is not published yet. Driver details appear when an assignment is confirmed.',
      ),
      ReservationPolicySection(
        title: 'Included waiting time',
        body:
            'No included waiting period is currently published. Confirmed terms will be shown before a scheduled ride is booked.',
      ),
      ReservationPolicySection(
        title: 'Cancellation terms',
        body:
            'You can cancel a reservation from Upcoming ride. No free-cancellation window is currently published.',
      ),
      ReservationPolicySection(
        title: 'Cancellation fees',
        body:
            'No cancellation fee is currently published. A fee must not be assumed unless it is shown in confirmed booking terms.',
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
            'No scheduled-ride promotion rule is published here. Only a promotion explicitly shown in confirmed booking details should be treated as applied.',
      ),
      ReservationPolicySection(
        title: 'Rider responsibilities',
        body:
            'Be ready at the pickup point at the reserved time, keep trip details accurate, and treat drivers with care.',
      ),
    ],
  );
}
