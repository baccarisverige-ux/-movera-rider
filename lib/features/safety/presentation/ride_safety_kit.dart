import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movera_rider/features/safety/application/emergency_call_service.dart';
import 'package:movera_rider/features/safety/application/safety_audio_service.dart';
import 'package:movera_rider/features/safety/application/safety_controller.dart';
import 'package:movera_rider/features/safety/domain/ride_check.dart';
import 'package:movera_rider/features/safety/presentation/safety_hub.dart';
import 'package:movera_rider/features/safety/presentation/trip_share_page.dart';
import 'package:movera_rider/features/ride_booking/application/sheet_coordinator.dart';
import 'package:movera_rider/shared/design_system/movera_sheet.dart';
import 'package:movera_rider/shared/design_system/movera_toast.dart';
import 'package:movera_rider/shared/widgets/navigation_transition.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

const Color _ink = Color(0xFF1D252C);
const Color _muted = Color(0xFF5C656C);
const Color _line = Color(0xFFE7EBEE);
const Color _icon = Color(0xFF3A4550);

class SafetyKitMapButton extends StatelessWidget {
  const SafetyKitMapButton({super.key, this.rideId});

  final String? rideId;

  @override
  Widget build(BuildContext context) {
    return PointerInterceptor(
      child: Material(
        color: Colors.white,
        elevation: 2,
        shadowColor: Colors.black26,
        borderRadius: BorderRadius.circular(28),
        child: InkWell(
          onTap: () => showRideSafetyKit(context, rideId: rideId),
          borderRadius: BorderRadius.circular(28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 14, 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.shield_outlined, size: 18, color: _icon),
                  const SizedBox(width: 8),
                  Text(
                    'Safety Kit',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _ink,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SafetyKitSheetRow extends StatelessWidget {
  const SafetyKitSheetRow({super.key, this.rideId});

  final String? rideId;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () => showRideSafetyKit(context, rideId: rideId),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _line),
          ),
          child: Row(
            children: [
              const Icon(Icons.shield_outlined, size: 22, color: _icon),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Safety Kit',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _ink,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: _muted),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> showRideSafetyKit(BuildContext context, {String? rideId}) {
  SheetCoordinator.instance.open(RideSheet.safety);
  return MoveraSheet.show<void>(
    context: context,
    builder: (_) => RideSafetyKitSheet(rideId: rideId),
  ).whenComplete(() => SheetCoordinator.instance.close(RideSheet.safety));
}

class RideSafetyKitSheet extends StatefulWidget {
  const RideSafetyKitSheet({super.key, this.rideId, this.controller});
  final String? rideId;
  final SafetyController? controller;

  @override
  State<RideSafetyKitSheet> createState() => _RideSafetyKitSheetState();
}

class _RideSafetyKitSheetState extends State<RideSafetyKitSheet> {
  late final SafetyController _ctl = widget.controller ?? SafetyController.shared;
  String? _audioNote;
  bool _eventsAvailable = false;

  @override
  void initState() {
    super.initState();
    _ctl.addListener(_onChange);
    _loadSafety();
  }

  Future<void> _loadSafety() async {
    await _ctl.load();
    final rideId = widget.rideId;
    if (rideId == null || rideId.isEmpty) return;
    try {
      await _ctl.refreshRideCheckEvents(rideId);
      if (mounted) setState(() => _eventsAvailable = true);
    } catch (_) {
      // The Safety Kit remains usable; do not show cached alerts as live.
    }
  }

  @override
  void dispose() {
    _ctl.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  TextStyle _text(
    double size, {
    FontWeight weight = FontWeight.w400,
    Color color = _ink,
  }) {
    return GoogleFonts.poppins(
      fontSize: size,
      fontWeight: weight,
      color: color,
    );
  }

  Future<void> _call112() async {
    try {
      await _ctl.emergency.callEmergencyNumber();
      try {
        final registered = await _ctl.sos(rideId: widget.rideId);
        if (!mounted) return;
        MoveraToast.show(context, registered
            ? 'Phone dialer opened. Movera registered your SOS.'
            : 'Phone dialer opened. In-app SOS needs an active ride.');
      } catch (_) {
        if (!mounted) return;
        MoveraToast.show(context,
            'Phone dialer opened, but Movera could not register your SOS.');
      }
    } on EmergencyCallException catch (error) {
      if (!mounted) return;
      MoveraToast.show(context, error.message);
    }
  }

  Future<void> _resolveRideCheck(RideCheckEvent event) async {
    try {
      await _ctl.resolveRideCheck(event);
      if (!mounted) return;
      MoveraToast.show(context, 'Your RideCheck response was sent.');
    } catch (_) {
      if (!mounted) return;
      MoveraToast.show(context, 'Could not send your response. Please try again.');
    }
  }

  Future<void> _toggleAudio() async {
    try {
      if (_ctl.audio.isRecording) {
        await _ctl.audio.stop();
        if (!mounted) return;
        setState(
          () => _audioNote =
              'Recording saved on this device. Automatic upload is unavailable.',
        );
      } else {
        await _ctl.audio.start(rideId: widget.rideId ?? 'ride_local');
        if (!mounted) return;
        setState(
          () => _audioNote =
              'Recording. Tap Stop audio to save it on this device.',
        );
      }
    } on SafetyAudioException catch (error) {
      if (!mounted) return;
      setState(() => _audioNote = error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _audioNote =
          'Recording could not be saved. Check microphone access and try again.');
    }
  }

  Future<void> _shareTrip() async {
    if (!_ctl.preferences.tripShareEnabled ||
        !_ctl.contacts.any((contact) => contact.isEnabled &&
            (_ctl.preferences.tripShareContactIds.contains(contact.id) ||
                contact.shareTrips))) {
      final nav = Navigator.of(context);
      await popCurrentRouteAndWaitForExit(context);
      if (!nav.mounted) return;
      await nav.push(RightToLeftTransition(TripSharePage(controller: _ctl)));
      return;
    }
    try {
      final share = await _ctl.startShare(widget.rideId ?? '');
      if (!mounted) return;
      setState(() {
        _audioNote = share.isActive && share.contactIds.isNotEmpty
            ? 'Trip sharing started for ${share.contactIds.length} trusted contact${share.contactIds.length == 1 ? '' : 's'}.'
            : 'Trip sharing could not be started.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _audioNote = 'Could not start trip sharing. Please try again.');
    }
  }

  Future<void> _openHub() async {
    final nav = Navigator.of(context);
    await popCurrentRouteAndWaitForExit(context);
    if (!nav.mounted) return;
    await nav.push(RightToLeftTransition(SafetyHub(controller: _ctl)));
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.paddingOf(context).bottom;
    final recording = _ctl.audio.isRecording;
    final pendingAlerts = !_eventsAvailable || widget.rideId == null
        ? <RideCheckEvent>[]
        : _ctl.pendingRideCheckEvents(widget.rideId!);
    return PointerInterceptor(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 8, 20, 20 + inset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: _ink),
                  tooltip: 'Close',
                ),
                Expanded(
                  child: Text(
                    'Safety',
                    textAlign: TextAlign.center,
                    style: _text(17, weight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
            const SizedBox(height: 4),
            Text('Safety tools', style: _text(22, weight: FontWeight.w700)),
            const SizedBox(height: 16),
            if (pendingAlerts.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8ED),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFECCB93)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('RideCheck alert', style: _text(14, weight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text('Are you okay? Movera noticed something unusual with this ride.',
                        style: _text(12, color: _muted)),
                    TextButton(
                      onPressed: () => _resolveRideCheck(pendingAlerts.first),
                      child: const Text("I'm okay"),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                Expanded(
                  child: _Tool(
                    icon: Icons.call_outlined,
                    label: 'Contact 112',
                    onTap: _call112,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _Tool(
                    icon: recording
                        ? Icons.stop_circle_outlined
                        : Icons.mic_outlined,
                    label: recording ? 'Stop audio' : 'Record audio',
                    onTap: _toggleAudio,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _Tool(
                    icon: Icons.ios_share_outlined,
                    label: 'Share trip',
                    onTap: _shareTrip,
                  ),
                ),
              ],
            ),
            if (_audioNote != null) ...[
              const SizedBox(height: 12),
              Text(_audioNote!, style: _text(12, color: _muted)),
            ],
            const SizedBox(height: 14),
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                onTap: _openHub,
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: _line),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.shield_outlined, size: 22, color: _icon),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Safety preferences',
                              style: _text(14, weight: FontWeight.w600),
                            ),
                            Text(
                              'PIN, contacts, trip sharing and RideCheck',
                              style: _text(12, color: _muted),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: _muted),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tool extends StatelessWidget {
  const _Tool({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _line),
          ),
          child: Column(
            children: [
              Icon(icon, color: _icon, size: 22),
              const SizedBox(height: 10),
              Text(
                label,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _ink,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
