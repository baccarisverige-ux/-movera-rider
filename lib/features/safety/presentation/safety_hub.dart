import 'package:flutter/material.dart';
import 'package:movera_rider/features/safety/application/safety_controller.dart';
import 'package:movera_rider/features/safety/presentation/emergency_contacts_page.dart';
import 'package:movera_rider/features/safety/presentation/how_movera_protects_page.dart';
import 'package:movera_rider/features/safety/presentation/pin_verification_page.dart';
import 'package:movera_rider/features/safety/presentation/ride_check_page.dart';
import 'package:movera_rider/features/safety/presentation/safety_marks.dart';
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
      showTitle: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        children: [
          const SizedBox(height: 8),
          const Center(child: SafetyMark(SafetyMarks.shield, size: 120)),
          const SizedBox(height: 18),
          Text(
            'Safety',
            textAlign: TextAlign.center,
            style: SafetyUi.text(30, weight: FontWeight.w600, letterSpacing: -0.6),
          ),
          const SizedBox(height: 8),
          Text(
            'Quiet protection for every ride.',
            textAlign: TextAlign.center,
            style: SafetyUi.text(15, color: SafetyUi.muted, height: 1.4),
          ),
          const SizedBox(height: 32),
          Text('Safety preferences', style: SafetyUi.text(13, weight: FontWeight.w600, letterSpacing: 0.4, color: SafetyUi.muted)),
          const SizedBox(height: 10),
          Container(
            decoration: SafetyUi.cardDecoration(),
            child: Column(
              children: [
                SafetyRow(
                  mark: SafetyMarks.pin,
                  title: 'PIN verification',
                  subtitle: 'Verify your ride before it starts.',
                  status: _ctl.pinStatusLabel(),
                  onTap: () => _open(PinVerificationPage(controller: _ctl)),
                ),
                SafetyRow(
                  mark: SafetyMarks.contacts,
                  title: 'Emergency contacts',
                  subtitle: 'Choose trusted contacts for emergencies.',
                  status: _ctl.contactsStatusLabel(),
                  onTap: () => _open(EmergencyContactsPage(controller: _ctl)),
                ),
                SafetyRow(
                  mark: SafetyMarks.share,
                  title: 'Share trip status',
                  subtitle: 'Let people you trust follow your ride.',
                  status: _ctl.shareStatusLabel(),
                  onTap: () => _open(TripSharePage(controller: _ctl)),
                ),
                SafetyRow(
                  mark: SafetyMarks.rideCheck,
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
          Text('Safety resources', style: SafetyUi.text(13, weight: FontWeight.w600, letterSpacing: 0.4, color: SafetyUi.muted)),
          const SizedBox(height: 10),
          Container(
            decoration: SafetyUi.cardDecoration(),
            child: Column(
              children: [
                SafetyRow(
                  mark: SafetyMarks.tips,
                  title: 'Safety tips',
                  subtitle: 'Simple advice for a safer ride.',
                  onTap: () => _open(const SafetyTipsPage()),
                ),
                SafetyRow(
                  mark: SafetyMarks.protect,
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
