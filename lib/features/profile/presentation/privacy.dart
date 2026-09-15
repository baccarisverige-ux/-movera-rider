import 'package:flutter/material.dart';
import 'package:movera_rider/app/di.dart';
import 'package:movera_rider/features/profile/application/profile_controller.dart';
import 'package:movera_rider/features/profile/presentation/account_widgets.dart';
import 'package:movera_rider/shared/design_system/adaptive_switch_colors.dart';
import 'package:movera_rider/shared/design_system/movera_empty_state.dart';
import 'package:movera_rider/shared/widgets/navigation_transition.dart';

class PrivacyPage extends StatefulWidget {
  const PrivacyPage({super.key, this.controller});

  final ProfileController? controller;

  @override
  State<PrivacyPage> createState() => _PrivacyPageState();
}

class _PrivacyPageState extends State<PrivacyPage> {
  late final ProfileController _profile;

  @override
  void initState() {
    super.initState();
    _profile = widget.controller ?? AppScope.instance.profile;
    _profile.addListener(_refresh);
  }

  @override
  void dispose() {
    _profile.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final ride = _profile.profile;
    return AccountScaffold(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 36),
        children: [
          const AccountHeadline(
            'Privacy',
            body: 'What Movera keeps, and how we reach you.',
          ),
          const SizedBox(height: 18),
          AccountGroup(
            children: [
              AccountTile(
                mark: const AccountIcon(Icons.description_outlined),
                title: 'Privacy notice',
                body: 'What we store and how you control it',
                showDivider: false,
                onTap: () {
                  Navigator.push(
                    context,
                    RightToLeftTransition(
                      const AccountLegalPage(kind: 'privacy'),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 20, 10),
            child: Text(
              'How we reach you',
              style: accountText(
                13,
                weight: FontWeight.w600,
                color: kAccountMuted,
              ),
            ),
          ),
          AccountGroup(
            children: [
              AccountTile(
                mark: const AccountIcon(Icons.notifications_none_rounded),
                title: 'Ride updates',
                body: 'Pickup, driver, and reservation alerts',
                trailing: Switch.adaptive(
                  value: ride.rideUpdates,
                  activeThumbColor: adaptiveSwitchThumbColor(
                    context,
                    kAccountAccent,
                  ),
                  activeTrackColor: adaptiveSwitchTrackColor(
                    context,
                    kAccountAccent,
                  ),
                  onChanged: (on) =>
                      _profile.update(ride.copyWith(rideUpdates: on)),
                ),
              ),
              AccountTile(
                mark: const AccountIcon(Icons.mail_outline_rounded),
                title: 'Email',
                body: 'Receipts and account notes',
                trailing: Switch.adaptive(
                  value: ride.emailUpdates,
                  activeThumbColor: adaptiveSwitchThumbColor(
                    context,
                    kAccountAccent,
                  ),
                  activeTrackColor: adaptiveSwitchTrackColor(
                    context,
                    kAccountAccent,
                  ),
                  onChanged: (on) =>
                      _profile.update(ride.copyWith(emailUpdates: on)),
                ),
              ),
              AccountTile(
                mark: const AccountIcon(Icons.local_offer_outlined),
                title: 'Offers',
                body: 'Occasional Movera news. Off by default',
                showDivider: false,
                trailing: Switch.adaptive(
                  value: ride.promotions,
                  activeThumbColor: adaptiveSwitchThumbColor(
                    context,
                    kAccountAccent,
                  ),
                  activeTrackColor: adaptiveSwitchTrackColor(
                    context,
                    kAccountAccent,
                  ),
                  onChanged: (on) =>
                      _profile.update(ride.copyWith(promotions: on)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 20, 10),
            child: Text(
              'Apps with access',
              style: accountText(
                13,
                weight: FontWeight.w600,
                color: kAccountMuted,
              ),
            ),
          ),
          const MoveraEmptyState(
            icon: Icons.apps_outlined,
            title: 'No connected apps',
            message:
                'No third-party apps can read this Movera account yet.',
            compact: true,
          ),
        ],
      ),
    );
  }
}
