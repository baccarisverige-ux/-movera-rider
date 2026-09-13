import 'package:flutter/material.dart';
import 'package:movera_rider/app/di.dart';
import 'package:movera_rider/features/profile/application/profile_controller.dart';
import 'package:movera_rider/features/profile/presentation/account_checkup.dart';
import 'package:movera_rider/features/profile/presentation/account_widgets.dart';
import 'package:movera_rider/features/profile/presentation/personal_info.dart';
import 'package:movera_rider/features/profile/presentation/privacy.dart';
import 'package:movera_rider/features/profile/presentation/security.dart';
import 'package:movera_rider/features/safety/presentation/safety_hub.dart';
import 'package:movera_rider/features/support/presentation/support.dart';
import 'package:movera_rider/shared/widgets/navigation_transition.dart';

class AccountHomePage extends StatefulWidget {
  const AccountHomePage({super.key, this.controller});

  final ProfileController? controller;

  @override
  State<AccountHomePage> createState() => _AccountHomePageState();
}

class _AccountHomePageState extends State<AccountHomePage> {
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

  Future<void> _open(Widget page) {
    return Navigator.push(context, RightToLeftTransition(page));
  }

  @override
  Widget build(BuildContext context) {
    final ride = _profile.profile;
    return AccountScaffold(
      title: 'Movera account',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Center(
            child: CircleAvatar(
              radius: 42,
              backgroundImage: AssetImage(ride.photoAsset),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            ride.name,
            textAlign: TextAlign.center,
            style: accountText(22, weight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            ride.email,
            textAlign: TextAlign.center,
            style: accountText(13.5, color: kAccountMuted),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              AccountCardButton(
                icon: Icons.person_outline_rounded,
                label: 'Personal info',
                onTap: () => _open(PersonalInfoPage(controller: _profile)),
              ),
              const SizedBox(width: 10),
              AccountCardButton(
                icon: Icons.verified_user_outlined,
                label: 'Security',
                onTap: () => _open(SecurityPage(controller: _profile)),
              ),
              const SizedBox(width: 10),
              AccountCardButton(
                icon: Icons.lock_outline_rounded,
                label: 'Privacy',
                onTap: () => _open(PrivacyPage(controller: _profile)),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (!ride.checkupComplete)
            Material(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: kAccountLine),
              ),
              child: InkWell(
                onTap: () => _open(AccountCheckupPage(controller: _profile)),
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Finish your account',
                        style: accountText(16, weight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Add a recovery number and extra sign-in protection so your Movera account stays yours.',
                        style: accountText(
                          13,
                          color: kAccountMuted,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Continue',
                        style: accountText(13.5, weight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 8),
          AccountRow(
            title: 'Safety',
            body: 'Share a trip and reach Movera support fast.',
            onTap: () => _open(const SafetyHub()),
          ),
          AccountRow(
            title: 'Support',
            body: 'Help with a ride, payment, or reservation.',
            onTap: () => _open(const SupportHome()),
          ),
          AccountRow(
            title: 'Terms',
            body: 'How Movera rides and reservations work.',
            onTap: () => _open(const AccountLegalPage(kind: 'terms')),
          ),
          AccountRow(
            title: 'Privacy notice',
            body: 'What we keep and how you control it.',
            onTap: () => _open(const AccountLegalPage(kind: 'privacy')),
          ),
          AccountRow(
            title: 'Log out',
            danger: true,
            trailing: const SizedBox.shrink(),
            onTap: () async {
              final leave = await showAccountChoice(
                context,
                title: 'Log out of Movera?',
                options: const ['Log out', 'Stay signed in'],
                selected: '',
              );
              if (leave == 'Log out' && context.mounted) {
                Navigator.popUntil(context, (route) => route.isFirst);
              }
            },
          ),
        ],
      ),
    );
  }
}
