import 'package:flutter/material.dart';
import 'package:movera_rider/features/safety/presentation/safety_marks.dart';
import 'package:movera_rider/features/safety/presentation/safety_ui.dart';

class SafetyTipsPage extends StatelessWidget {
  const SafetyTipsPage({super.key});

  @override
  Widget build(BuildContext context) {
    const tips = [
      ('Meet in a well-lit place', 'Wait indoors or near other people until your Movera arrives.'),
      ('Check the car before you sit', 'Match the plate, colour and driver photo in the app.'),
      ('Share the ride when it helps', 'Use trip sharing so someone you trust can follow along.'),
      ('Sit where you feel comfortable', 'The back seat is usually the calmest choice.'),
      ('Keep 112 available', 'In Sweden, 112 is the emergency number. Only you can place that call.'),
    ];
    return SafetyScaffold(
      title: 'Safety tips',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          const Center(child: SafetyMark(SafetyMarks.tips, size: 72)),
          const SizedBox(height: 16),
          Text(
            'Simple advice for a safer ride.',
            textAlign: TextAlign.center,
            style: SafetyUi.text(15, color: SafetyUi.muted, height: 1.45),
          ),
          const SizedBox(height: 18),
          Container(
            decoration: SafetyUi.cardDecoration(),
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
            child: Column(
              children: [
                for (var i = 0; i < tips.length; i++) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${i + 1}'.padLeft(2, '0'),
                            style: SafetyUi.text(13, color: SafetyUi.accent, weight: FontWeight.w600)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(tips[i].$1, style: SafetyUi.text(15.5, weight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Text(tips[i].$2, style: SafetyUi.text(13.5, color: SafetyUi.muted, height: 1.4)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (i != tips.length - 1) const Divider(height: 1, color: SafetyUi.line),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
