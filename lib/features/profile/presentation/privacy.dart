import 'package:flutter/material.dart';
import 'package:movera_rider/app/di.dart';
import 'package:movera_rider/core/constants/appassets.dart';
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
      child: ListView(
        padding: const EdgeInsets.only(bottom: 36),
        children: [
          const AccountHero(asset: AppAssets.privacyPolicy, height: 96),
          const AccountHeadline(
            'Privacy',
            body: 'What Movera keeps, and how we reach you.',
          ),
          const SizedBox(height: 18),
          AccountGroup(
            children: [
              AccountTile(
                asset: AppAssets.document,
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
                asset: AppAssets.sound,
                title: 'Ride updates',
                body: 'Pickup, driver, and reservation alerts',
                trailing: Switch.adaptive(
                  value: ride.rideUpdates,
                  activeColor: kAccountAccent,
                  onChanged: (on) =>
                      _profile.update(ride.copyWith(rideUpdates: on)),
                ),
              ),
              AccountTile(
                asset: AppAssets.message,
                title: 'Email',
                body: 'Receipts and account notes',
                trailing: Switch.adaptive(
                  value: ride.emailUpdates,
                  activeColor: kAccountAccent,
                  onChanged: (on) =>
                      _profile.update(ride.copyWith(emailUpdates: on)),
                ),
              ),
              AccountTile(
                asset: AppAssets.promotions,
                title: 'Offers',
                body: 'Occasional Movera news. Off by default',
                showDivider: false,
                trailing: Switch.adaptive(
                  value: ride.promotions,
                  activeColor: kAccountAccent,
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
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
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
