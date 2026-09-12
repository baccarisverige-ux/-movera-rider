import 'package:flutter/material.dart';
import 'package:movera_rider/features/safety/application/safety_controller.dart';
import 'package:movera_rider/features/safety/presentation/emergency_contacts_page.dart';
import 'package:movera_rider/features/safety/presentation/how_movera_protects_page.dart';
import 'package:movera_rider/features/safety/presentation/pin_verification_page.dart';
import 'package:movera_rider/features/safety/presentation/ride_check_page.dart';
import 'package:movera_rider/features/safety/presentation/safety_tips_page.dart';
import 'package:movera_rider/features/safety/presentation/safety_ui.dart';
import 'package:movera_rider/features/safety/presentation/trip_share_page.dart';
import 'package:movera_rider/shared/widgets/navigation_transition.dart';

class SafetyHub extends StatefulWidget {
  const SafetyHub({super.key, this.controller});

  final SafetyController? controller;

  @override
  State<SafetyHub> createState() => _SafetyHubState();
}

class _SafetyHubState extends State<SafetyHub> {
  late final SafetyController _ctl;

  @override
  void initState() {
    super.initState();
    _ctl = widget.controller ?? SafetyController.shared;
    _ctl.addListener(_onChange);
    _ctl.load();
  }

  @override
  void dispose() {
    _ctl.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  Future<void> _open(Widget page) async {
    await Navigator.push(context, RightToLeftTransition(page));
    await _ctl.load();
  }

  @override
  Widget build(BuildContext context) {
    return SafetyScaffold(
      title: 'Safety',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          Text('Safety', style: SafetyUi.text(32, weight: FontWeight.w700, letterSpacing: -0.7)),
          const SizedBox(height: 8),
          Text(
            'Your safety, before and during every ride.',
            style: SafetyUi.text(15, color: SafetyUi.muted, height: 1.4),
          ),
          const SizedBox(height: 28),
          Text('Safety preferences', style: SafetyUi.text(16, weight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(
            'Choose how Movera helps protect your rides.',
            style: SafetyUi.text(13.5, color: SafetyUi.muted),
          ),
          const SizedBox(height: 14),
          Container(
            decoration: SafetyUi.cardDecoration(),
            child: Column(
              children: [
                SafetyRow(
                  icon: Icons.pin_outlined,
                  title: 'PIN verification',
                  subtitle: 'Verify your ride before it starts.',
                  status: _ctl.pinStatusLabel(),
                  onTap: () => _open(PinVerificationPage(controller: _ctl)),
                ),
                SafetyRow(
                  icon: Icons.group_outlined,
                  title: 'Emergency contacts',
                  subtitle: 'Choose trusted contacts for emergencies.',
                  status: _ctl.contactsStatusLabel(),
                  onTap: () => _open(EmergencyContactsPage(controller: _ctl)),
                ),
                SafetyRow(
                  icon: Icons.ios_share_outlined,
                  title: 'Share trip status',
                  subtitle: 'Let people you trust follow your ride.',
                  status: _ctl.shareStatusLabel(),
                  onTap: () => _open(TripSharePage(controller: _ctl)),
                ),
                SafetyRow(
                  icon: Icons.health_and_safety_outlined,
                  title: 'RideCheck',
                  subtitle: 'Get help if a ride stops unexpectedly or goes off route.',
                  status: _ctl.rideCheckStatusLabel(),
                  onTap: () => _open(RideCheckPage(controller: _ctl)),
                  showDivider: false,
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Text('Safety resources', style: SafetyUi.text(16, weight: FontWeight.w700)),
          const SizedBox(height: 14),
          Container(
            decoration: SafetyUi.cardDecoration(),
            child: Column(
              children: [
                SafetyRow(
                  icon: Icons.lightbulb_outline_rounded,
                  title: 'Safety tips',
                  subtitle: 'Simple advice for a safer ride.',
                  onTap: () => _open(const SafetyTipsPage()),
                ),
                SafetyRow(
                  icon: Icons.verified_user_outlined,
                  title: 'How Movera protects you',
                  subtitle: 'Learn about our safety features.',
                  onTap: () => _open(const HowMoveraProtectsPage()),
                  showDivider: false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
