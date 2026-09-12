import 'package:flutter/material.dart';
import 'package:movera_rider/features/safety/application/safety_controller.dart';
import 'package:movera_rider/features/safety/presentation/safety_ui.dart';

class PinVerificationPage extends StatefulWidget {
  const PinVerificationPage({super.key, required this.controller});
  final SafetyController controller;

  @override
  State<PinVerificationPage> createState() => _PinVerificationPageState();
}

class _PinVerificationPageState extends State<PinVerificationPage> {
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

  Future<void> _confirmRotate() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Change PIN?', style: SafetyUi.text(18, weight: FontWeight.w600)),
          content: Text(
            'Movera will create a new 4-digit PIN. Share it with your driver only when the ride begins.',
            style: SafetyUi.text(14, color: SafetyUi.muted, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel', style: SafetyUi.text(14, color: SafetyUi.muted)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Change PIN', style: SafetyUi.text(14, color: SafetyUi.accent, weight: FontWeight.w600)),
            ),
          ],
        );
      },
    );
    if (ok == true) await _ctl.rotatePin();
  }

  @override
  Widget build(BuildContext context) {
    final pin = _ctl.pin.pin;
    return SafetyScaffold(
      title: 'PIN verification',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          Text(
            'Add an extra check before your ride begins. Your driver must confirm your PIN before starting the trip.',
            style: SafetyUi.text(15, color: SafetyUi.muted, height: 1.45),
          ),
          const SizedBox(height: 22),
          Container(
            decoration: SafetyUi.cardDecoration(),
            padding: const EdgeInsets.fromLTRB(18, 8, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text('Verify rides with a PIN', style: SafetyUi.text(15.5, weight: FontWeight.w500)),
                ),
                Switch.adaptive(
                  value: _ctl.preferences.pinRequired,
                  activeColor: SafetyUi.accent,
                  onChanged: _ctl.setPinRequired,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Container(
            decoration: SafetyUi.cardDecoration(),
            padding: const EdgeInsets.fromLTRB(18, 22, 18, 22),
            child: Column(
              children: [
                Text('Your PIN', style: SafetyUi.text(13, color: SafetyUi.muted)),
                const SizedBox(height: 10),
                Text(
                  pin.split('').join('  '),
                  style: SafetyUi.text(34, weight: FontWeight.w700, letterSpacing: 2),
                ),
                const SizedBox(height: 8),
                Text(
                  _ctl.preferences.pinRequired
                      ? 'Share this PIN with your driver when the trip starts.'
                      : 'PIN is saved. Turn on verification to use it on rides.',
                  textAlign: TextAlign.center,
                  style: SafetyUi.text(13, color: SafetyUi.muted, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 52,
            child: OutlinedButton(
              onPressed: _confirmRotate,
              style: OutlinedButton.styleFrom(
                foregroundColor: SafetyUi.accent,
                side: const BorderSide(color: Color(0xFFD5DEE5)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text('Change PIN', style: SafetyUi.text(15.5, weight: FontWeight.w600, color: SafetyUi.accent)),
            ),
          ),
        ],
      ),
    );
  }
}
