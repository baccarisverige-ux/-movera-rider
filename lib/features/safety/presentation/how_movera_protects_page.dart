import 'package:flutter/material.dart';
import 'package:movera_rider/features/safety/presentation/safety_marks.dart';
import 'package:movera_rider/features/safety/presentation/safety_ui.dart';

class HowMoveraProtectsPage extends StatelessWidget {
  const HowMoveraProtectsPage({super.key});

  @override
  Widget build(BuildContext context) {
    const items = [
      (
        'PIN verification',
        'Ask your driver to confirm your PIN before the trip starts, so you know you are in the right car.',
      ),
      (
        'Emergency contacts',
        'Keep trusted people one tap away. You choose who is primary and who can follow a ride.',
      ),
      (
        'Trip sharing',
        'Share an active ride with people you trust. Tracking links are issued per ride — never as a public page from this menu.',
      ),
      (
        'RideCheck',
        'Movera can look for unexpected stops or large route changes once the live safety service is connected.',
      ),
      (
        'Masked calls',
        'During a ride you can reach your driver without sharing your personal number.',
      ),
    ];
    return SafetyScaffold(
      title: 'How Movera protects you',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          const Center(child: SafetyMark(SafetyMarks.protect, size: 72)),
          const SizedBox(height: 16),
          Text(
            'Learn about our safety features.',
            textAlign: TextAlign.center,
            style: SafetyUi.text(15, color: SafetyUi.muted, height: 1.45),
          ),
          const SizedBox(height: 18),
          Container(
            decoration: SafetyUi.cardDecoration(),
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
            child: Column(
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(items[i].$1, style: SafetyUi.text(16, weight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        Text(items[i].$2, style: SafetyUi.text(13.5, color: SafetyUi.muted, height: 1.45)),
                      ],
                    ),
                  ),
                  if (i != items.length - 1) const Divider(height: 1, color: SafetyUi.line),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
