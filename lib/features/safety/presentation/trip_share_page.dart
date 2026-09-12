import 'package:flutter/material.dart';
import 'package:movera_rider/features/safety/application/safety_controller.dart';
import 'package:movera_rider/features/safety/domain/safety_preferences.dart';
import 'package:movera_rider/features/safety/presentation/safety_ui.dart';

class TripSharePage extends StatefulWidget {
  const TripSharePage({super.key, required this.controller});
  final SafetyController controller;

  @override
  State<TripSharePage> createState() => _TripSharePageState();
}

class _TripSharePageState extends State<TripSharePage> {
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
    final prefs = _ctl.preferences;
    final shareable = _ctl.contacts.where((c) => c.isEnabled).toList();
    return SafetyScaffold(
      title: 'Share trip status',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          Text(
            'Share your active ride with people you trust.',
            style: SafetyUi.text(15, color: SafetyUi.muted, height: 1.45),
          ),
          const SizedBox(height: 20),
          Container(
            decoration: SafetyUi.cardDecoration(),
            padding: const EdgeInsets.fromLTRB(18, 8, 8, 8),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text('Trip sharing', style: SafetyUi.text(15.5, weight: FontWeight.w500)),
                    ),
                    Switch.adaptive(
                      value: prefs.tripShareEnabled,
                      activeColor: SafetyUi.accent,
                      onChanged: (value) => _ctl.setTripShare(enabled: value),
                    ),
                  ],
                ),
                const Divider(height: 1, color: SafetyUi.line),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Automatically share every ride', style: SafetyUi.text(15)),
                  subtitle: Text(
                    'When a ride starts, selected contacts can follow it.',
                    style: SafetyUi.text(12.5, color: SafetyUi.muted),
                  ),
                  value: prefs.tripShareMode == TripShareMode.auto,
                  activeColor: SafetyUi.accent,
                  onChanged: prefs.tripShareEnabled
                      ? (value) => _ctl.setTripShare(
                            mode: value ? TripShareMode.auto : TripShareMode.manual,
                          )
                      : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text('Trusted contacts', style: SafetyUi.text(16, weight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(
            'A live tracking link is created only when a ride is shared. Movera does not publish a public URL from this screen.',
            style: SafetyUi.text(13, color: SafetyUi.muted, height: 1.4),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: SafetyUi.cardDecoration(),
            child: shareable.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'Add an emergency contact first, then choose who can follow your rides.',
                      style: SafetyUi.text(14, color: SafetyUi.muted, height: 1.4),
                    ),
                  )
                : Column(
                    children: [
                      for (var i = 0; i < shareable.length; i++)
                        Column(
                          children: [
                            CheckboxListTile(
                              value: prefs.tripShareContactIds.contains(shareable[i].id) ||
                                  shareable[i].shareTrips,
                              activeColor: SafetyUi.accent,
                              title: Text(shareable[i].name, style: SafetyUi.text(15.5)),
                              subtitle: Text(
                                shareable[i].relationship,
                                style: SafetyUi.text(12.5, color: SafetyUi.muted),
                              ),
                              onChanged: prefs.tripShareEnabled
                                  ? (value) async {
                                      final selected = [...prefs.tripShareContactIds];
                                      if (value == true) {
                                        if (!selected.contains(shareable[i].id)) {
                                          selected.add(shareable[i].id);
                                        }
                                      } else {
                                        selected.remove(shareable[i].id);
                                      }
                                      await _ctl.setTripShare(contactIds: selected);
                                      await _ctl.editContact(
                                        shareable[i].copyWith(shareTrips: value == true),
                                      );
                                    }
                                  : null,
                            ),
                            if (i != shareable.length - 1)
                              const Divider(height: 1, color: SafetyUi.line),
                          ],
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
