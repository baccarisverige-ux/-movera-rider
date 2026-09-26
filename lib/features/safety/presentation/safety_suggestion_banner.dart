import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movera_rider/features/safety/application/safety_controller.dart';
import 'package:movera_rider/features/safety/presentation/ride_safety_kit.dart';
import 'package:movera_rider/features/safety/presentation/trip_share_page.dart';
import 'package:movera_rider/shared/widgets/navigation_transition.dart';

class SafetySuggestionBanner extends StatelessWidget {
  const SafetySuggestionBanner({super.key, this.rideId, this.tick = 0});

  final String? rideId;
  final int tick;

  @override
  Widget build(BuildContext context) {
    final safety = SafetyController.shared;
    final items = <_Item>[
      _Item(
        icon: Icons.ios_share_rounded,
        text: 'Share your trip',
        action: 'Share',
        onTap: () {
          if (safety.preferences.tripShareEnabled) {
            showRideSafetyKit(context, rideId: rideId);
            return;
          }
          Navigator.push(
            context,
            RightToLeftTransition(TripSharePage(controller: safety)),
          );
        },
      ),
      _Item(
        icon: Icons.shield_outlined,
        text: 'Open Safety Kit',
        action: 'Open',
        onTap: () => showRideSafetyKit(context, rideId: rideId),
      ),
      if (safety.preferences.pinRequired)
        _Item(
          icon: Icons.dialpad_outlined,
          text: 'Verify your driver',
          action: 'PIN',
          onTap: () => showRideSafetyKit(context, rideId: rideId),
        ),
    ];
    final item = items[tick % items.length];
    return Material(
      color: const Color(0xFFF3F6FB),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
        child: Row(
          children: [
            Icon(item.icon, size: 22, color: const Color(0xFF2D5878)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                item.text,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF1D252C),
                ),
              ),
            ),
            TextButton(
              onPressed: item.onTap,
              child: Text(
                item.action,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2D5878),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Item {
  const _Item({
    required this.icon,
    required this.text,
    required this.action,
    required this.onTap,
  });

  final IconData icon;
  final String text;
  final String action;
  final VoidCallback onTap;
}
