import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movera_rider/app/di.dart';
import 'package:movera_rider/features/ride_booking/domain/entities/matched_driver.dart';
import 'package:movera_rider/features/ride_booking/domain/ride_notes.dart';
import 'package:movera_rider/features/safety/application/safety_controller.dart';
import 'package:movera_rider/features/safety/presentation/ride_safety_kit.dart';
import 'package:movera_rider/features/safety/presentation/trip_share_page.dart';
import 'package:movera_rider/features/messages/presentation/chat.dart';
import 'package:movera_rider/shared/design_system/movera_empty_state.dart';
import 'package:movera_rider/shared/design_system/tokens.dart';
import 'package:movera_rider/shared/widgets/navigation_transition.dart';

String shortPickupPlace(String value) {
  final noisy = RegExp(
    r'^(sweden|sverige|stockholms?\s*län|stockholm\s*county|'
    r'kommun|municipality|county|län|europe)$',
    caseSensitive: false,
  );
  final parts = value
      .split(RegExp(r'[,|]'))
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .where((part) => !RegExp(r'^\d{3,}(\s?\d{2})?$').hasMatch(part))
      .where((part) => !noisy.hasMatch(part))
      .toList();
  if (parts.isEmpty) {
    final fallback = value.trim();
    return fallback.length <= 42 ? fallback : '${fallback.substring(0, 40)}…';
  }
  if (parts.length == 1) {
    final only = parts.first;
    return only.length <= 42 ? only : '${only.substring(0, 40)}…';
  }
  final short = '${parts[0]}, ${parts[1]}';
  return short.length <= 48 ? short : '${short.substring(0, 46)}…';
}

TextStyle waitingText(
  double size, {
  FontWeight weight = FontWeight.w400,
  Color? color,
}) {
  return GoogleFonts.poppins(
    fontSize: size,
    fontWeight: weight,
    color: color ?? MoveraTokens.ink,
  );
}

class WaitingShareButton extends StatelessWidget {
  const WaitingShareButton({super.key, this.rideId});

  final String? rideId;

  void _share(BuildContext context) {
    final safety = SafetyController.shared;
    if (safety.preferences.tripShareEnabled) {
      safety.shareTrip(rideId: rideId);
      showRideSafetyKit(context, rideId: rideId);
      return;
    }
    Navigator.push(
      context,
      RightToLeftTransition(TripSharePage(controller: safety)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Share trip',
      child: Material(
        color: const Color(0xFFF6F8FA),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => _share(context),
          child: const Padding(
            padding: EdgeInsets.all(10),
            child: Icon(
              Icons.ios_share_rounded,
              size: 20,
              color: MoveraTokens.ink,
            ),
          ),
        ),
      ),
    );
  }
}

class WaitingRideDetailsCard extends StatelessWidget {
  const WaitingRideDetailsCard({
    super.key,
    required this.rideType,
    required this.pickupAddress,
    this.destinationAddress,
    this.inTrip = false,
    required this.paymentMethod,
    required this.price,
    required this.onMore,
  });

  final String rideType;
  final String pickupAddress;
  final String? destinationAddress;
  final bool inTrip;
  final String paymentMethod;
  final double price;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: MoveraTokens.line),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rideType,
                  style: waitingText(
                    12,
                    weight: FontWeight.w500,
                    color: const Color(0xFF5C656C),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  inTrip && destinationAddress?.trim().isNotEmpty == true
                      ? 'To ${shortPickupPlace(destinationAddress!)}'
                      : 'Meet at ${shortPickupPlace(pickupAddress)}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: waitingText(
                    15,
                    weight: FontWeight.w600,
                  ).copyWith(height: 1.3),
                ),
                const SizedBox(height: 8),
                Text(
                  '$paymentMethod · ${price.round()} kr',
                  style: waitingText(
                    12,
                    weight: FontWeight.w500,
                    color: MoveraTokens.accent,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onMore,
            icon: const Icon(Icons.more_horiz_rounded),
            tooltip: 'Ride details',
          ),
        ],
      ),
    );
  }
}

class WaitingDriverCard extends StatelessWidget {
  const WaitingDriverCard({
    super.key,
    required this.driver,
    required this.onOpenProfile,
    required this.onCall,
    required this.onMore,
  });

  final MatchedDriver? driver;
  final VoidCallback onOpenProfile;
  final VoidCallback onCall;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    if (driver == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: MoveraTokens.line),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const MoveraEmptyState(
          icon: Icons.person_search_outlined,
          title: 'Driver details unavailable',
          message:
              'Verified driver and vehicle information will appear here when matching confirms them.',
          compact: true,
        ),
      );
    }
    final d = driver!;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
      decoration: BoxDecoration(
        border: Border.all(color: MoveraTokens.line),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onOpenProfile,
            borderRadius: BorderRadius.circular(12),
            child: Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundImage: d.photoAsset != null
                          ? AssetImage(d.photoAsset!)
                          : null,
                      backgroundColor: const Color(0xFFF3F6FB),
                      child: d.photoAsset == null
                          ? Text(
                              d.firstName[0],
                              style: waitingText(18, weight: FontWeight.w700),
                            )
                          : null,
                    ),
                    if (d.ratingLabel != null)
                      Positioned(
                        left: 2,
                        right: 2,
                        bottom: -9,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: MoveraTokens.ink,
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            '★ ${d.ratingLabel}',
                            textAlign: TextAlign.center,
                            style: waitingText(
                              10,
                              weight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        d.firstName,
                        style: waitingText(18, weight: FontWeight.w700),
                      ),
                      if (d.tripsLabel != null)
                        Text(
                          d.tripsLabel!,
                          style: waitingText(
                            12,
                            color: const Color(0xFF5C656C),
                          ),
                        ),
                      if (d.vehicleLabel.isNotEmpty)
                        Text(
                          d.vehicleLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: waitingText(
                            13,
                            weight: FontWeight.w500,
                            color: const Color(0xFF5C656C),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (d.vehicleImageAsset != null)
                      Image.asset(
                        excludeFromSemantics: true,
                        d.vehicleImageAsset!,
                        height: 40,
                        width: 72,
                        fit: BoxFit.contain,
                      ),
                    if (d.plate != null) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF6F8FA),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: MoveraTokens.line),
                        ),
                        child: Text(
                          d.plate!,
                          style: waitingText(
                            14,
                            weight: FontWeight.w700,
                          ).copyWith(letterSpacing: 0.4),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Material(
                  color: const Color(0xFFF6F8FA),
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    onTap: () => Navigator.push(
                      context,
                      BottomToTopTransition(Chat(driverName: d.firstName)),
                    ),
                    borderRadius: BorderRadius.circular(14),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 18,
                            color: MoveraTokens.ink,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Message',
                            style: waitingText(14, weight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _IconChip(
                icon: Icons.phone_outlined,
                onTap: onCall,
                semanticLabel: 'Call driver',
              ),
              const SizedBox(width: 8),
              _IconChip(
                icon: Icons.more_horiz_rounded,
                onTap: onMore,
                semanticLabel: 'More options',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class WaitingNotesAndPin extends StatelessWidget {
  const WaitingNotesAndPin({super.key, required this.notes});

  final RideNotes notes;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!notes.isEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final label in notes.selected)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F6FB),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    label,
                    style: waitingText(
                      12,
                      weight: FontWeight.w600,
                      color: MoveraTokens.accent,
                    ),
                  ),
                ),
            ],
          ),
        ],
        if (SafetyController.shared.preferences.pinRequired) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF6F8FA),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Show this PIN to your driver',
                  style: waitingText(12, color: const Color(0xFF5C656C)),
                ),
                Text(
                  SafetyController.shared.pin.pin,
                  style: waitingText(22, weight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 12),
        SafetyKitSheetRow(rideId: AppScope.instance.ride.rideId),
      ],
    );
  }
}

class _IconChip extends StatelessWidget {
  const _IconChip({
    required this.icon,
    required this.onTap,
    required this.semanticLabel,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Material(
        color: const Color(0xFFF6F8FA),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Icon(icon, size: 20, color: MoveraTokens.ink),
          ),
        ),
      ),
    );
  }
}
