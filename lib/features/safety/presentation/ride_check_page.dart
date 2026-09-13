import 'package:flutter/material.dart';
import 'package:movera_rider/features/safety/application/safety_controller.dart';
import 'package:movera_rider/features/safety/presentation/safety_marks.dart';
import 'package:movera_rider/features/safety/presentation/safety_ui.dart';

class RideCheckPage extends StatefulWidget {
  const RideCheckPage({super.key, required this.controller});
  final SafetyController controller;

  @override
  State<RideCheckPage> createState() => _RideCheckPageState();
}

class _RideCheckPageState extends State<RideCheckPage> {
  SafetyController get _ctl => widget.controller;

  @override
  void initState() {
    super.initState();
    _ctl.addListener(_onChange);
  }

  @override
  void dispose() {
    _ctl.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final on = _ctl.rideCheckPolicy.enabled;
    return SafetyScaffold(
      title: 'RideCheck',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          const Center(child: SafetyMark(SafetyMarks.rideCheck, size: 96)),
          const SizedBox(height: 16),
          Text(
            'Movera can check on you when a ride appears to stop unexpectedly or move significantly off route.',
            textAlign: TextAlign.center,
            style: SafetyUi.text(15, color: SafetyUi.muted, height: 1.45),
          ),
          const SizedBox(height: 20),
          Container(
            decoration: SafetyUi.cardDecoration(),
            padding: const EdgeInsets.fromLTRB(18, 8, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text('RideCheck alerts', style: SafetyUi.text(15.5, weight: FontWeight.w500)),
                ),
                Switch.adaptive(
                  value: on,
                  activeColor: SafetyUi.accent,
                  onChanged: _ctl.setRideCheck,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Container(
            decoration: SafetyUi.cardDecoration(),
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('What RideCheck looks for', style: SafetyUi.text(15, weight: FontWeight.w600)),
                const SizedBox(height: 10),
                Text(
                  'Unexpected long stops, major route changes, a trip continuing well past the destination, or a sudden loss of movement.',
                  style: SafetyUi.text(13.5, color: SafetyUi.muted, height: 1.45),
                ),
                const SizedBox(height: 12),
                Text(
                  'Live route monitoring is not connected to a production backend yet. Turning this on saves your preference so Movera can use it when RideCheck is fully active.',
                  style: SafetyUi.text(13.5, color: SafetyUi.muted, height: 1.45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
