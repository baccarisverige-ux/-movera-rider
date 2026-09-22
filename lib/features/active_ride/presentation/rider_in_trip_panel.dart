import 'package:flutter/material.dart';
import 'package:movera_rider/features/ride_booking/domain/entities/matched_driver.dart';
import 'package:movera_rider/features/ride_booking/domain/ride_status.dart';
import 'package:movera_rider/features/safety/presentation/ride_safety_kit.dart';
import 'package:movera_rider/shared/design_system/tokens.dart';
import 'package:movera_rider/features/active_ride/presentation/waiting_sheet_bits.dart';

class RiderInTripPanel extends StatelessWidget {
  const RiderInTripPanel({
    super.key,
    required this.destinationAddress,
    required this.rideType,
    required this.paymentMethod,
    required this.price,
    required this.driver,
    required this.rideId,
    required this.status,
    required this.onOpenProfile,
    required this.onCall,
    required this.onMore,
  });

  final String destinationAddress;
  final String rideType;
  final String paymentMethod;
  final double price;
  final MatchedDriver? driver;
  final String? rideId;
  final RideStatus status;
  final VoidCallback onOpenProfile;
  final VoidCallback onCall;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final approaching = status == RideStatus.approachingDropoff;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F7),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.navigation_rounded,
                            size: 14,
                            color: MoveraTokens.accent,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            approaching ? 'NEAR DESTINATION' : 'ON TRIP',
                            style: waitingText(
                              11,
                              weight: FontWeight.w700,
                              color: MoveraTokens.accent,
                            ).copyWith(letterSpacing: 0.7),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      approaching ? 'Approaching destination' : 'Ride in progress',
                      style: waitingText(23, weight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      shortPickupPlace(destinationAddress),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: waitingText(
                        14,
                        weight: FontWeight.w500,
                        color: MoveraTokens.muted,
                      ).copyWith(height: 1.35),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              WaitingShareButton(rideId: rideId),
            ],
          ),
          const SizedBox(height: 18),
          _TripDestinationCard(
            destinationAddress: destinationAddress,
            rideType: rideType,
            paymentMethod: paymentMethod,
            price: price,
          ),
          const SizedBox(height: 14),
          WaitingDriverCard(
            driver: driver,
            rideId: rideId,
            onOpenProfile: onOpenProfile,
            onCall: onCall,
            onMore: onMore,
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFB),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: MoveraTokens.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.shield_outlined,
                      size: 18,
                      color: MoveraTokens.ink,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Trip safety',
                      style: waitingText(14, weight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SafetyKitSheetRow(rideId: rideId),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TripDestinationCard extends StatelessWidget {
  const _TripDestinationCard({
    required this.destinationAddress,
    required this.rideType,
    required this.paymentMethod,
    required this.price,
  });

  final String destinationAddress;
  final String rideType;
  final String paymentMethod;
  final double price;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: MoveraTokens.line),
        boxShadow: [
          BoxShadow(
            color: MoveraTokens.ink.withValues(alpha: 0.05),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F7),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.flag_rounded,
                  size: 19,
                  color: MoveraTokens.accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Destination',
                      style: waitingText(
                        12,
                        weight: FontWeight.w600,
                        color: MoveraTokens.muted,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      shortPickupPlace(destinationAddress),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: waitingText(
                        16,
                        weight: FontWeight.w700,
                      ).copyWith(height: 1.3),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: MoveraTokens.line),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _TripMeta(label: 'Ride', value: rideType)),
              const _VerticalRule(),
              Expanded(
                child: _TripMeta(
                  label: 'Payment',
                  value: paymentMethod,
                  center: true,
                ),
              ),
              const _VerticalRule(),
              Expanded(
                child: _TripMeta(
                  label: 'Booked',
                  value: '${price.round()} kr',
                  end: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TripMeta extends StatelessWidget {
  const _TripMeta({
    required this.label,
    required this.value,
    this.center = false,
    this.end = false,
  });

  final String label;
  final String value;
  final bool center;
  final bool end;

  @override
  Widget build(BuildContext context) {
    final alignment = end
        ? CrossAxisAlignment.end
        : center
        ? CrossAxisAlignment.center
        : CrossAxisAlignment.start;
    final textAlign = end
        ? TextAlign.right
        : center
        ? TextAlign.center
        : TextAlign.left;

    return Column(
      crossAxisAlignment: alignment,
      children: [
        Text(
          label,
          textAlign: textAlign,
          style: waitingText(
            11,
            weight: FontWeight.w500,
            color: MoveraTokens.muted,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: textAlign,
          style: waitingText(13, weight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _VerticalRule extends StatelessWidget {
  const _VerticalRule();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 30,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: MoveraTokens.line,
    );
  }
}
