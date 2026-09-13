import 'package:flutter/material.dart';
import 'package:movera_rider/app/di.dart';
import 'package:movera_rider/features/profile/application/profile_controller.dart';
import 'package:movera_rider/features/profile/presentation/account_widgets.dart';
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
      title: 'Privacy',
      child: ListView(
        children: [
          const AccountSection('Privacy'),
          AccountRow(
            title: 'Privacy notice',
            body: 'What Movera stores and how you control it.',
            onTap: () {
              Navigator.push(
                context,
                RightToLeftTransition(const AccountLegalPage(kind: 'privacy')),
              );
            },
          ),
          const AccountSection('How we reach you'),
          AccountRow(
            title: 'Ride updates',
            body: 'Pickup, driver, and reservation alerts.',
            trailing: Switch.adaptive(
              value: ride.rideUpdates,
              activeColor: kAccountAccent,
              onChanged: (on) =>
                  _profile.update(ride.copyWith(rideUpdates: on)),
            ),
          ),
          AccountRow(
            title: 'Email',
            body: 'Receipts and account notes.',
            trailing: Switch.adaptive(
              value: ride.emailUpdates,
              activeColor: kAccountAccent,
              onChanged: (on) =>
                  _profile.update(ride.copyWith(emailUpdates: on)),
            ),
          ),
          AccountRow(
            title: 'Offers',
            body: 'Occasional Movera news. Off by default.',
            trailing: Switch.adaptive(
              value: ride.promotions,
              activeColor: kAccountAccent,
              onChanged: (on) => _profile.update(ride.copyWith(promotions: on)),
            ),
          ),
          const AccountSection('Apps with access'),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            child: Text(
              'No third-party apps can read this Movera account yet.',
              style: accountText(13.5, color: kAccountMuted, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
