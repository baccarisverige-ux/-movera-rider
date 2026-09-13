import 'package:flutter/material.dart';
import 'package:movera_rider/app/di.dart';
import 'package:movera_rider/core/constants/appassets.dart';
import 'package:movera_rider/core/constants/appcolors.dart';
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
      child: ListView(
        padding: const EdgeInsets.only(bottom: 36),
        children: [
          const AccountHeadline(
            'Account',
            body: 'Your Movera profile and sign-in.',
          ),
          const SizedBox(height: 22),
          Center(
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 46,
                  backgroundColor: AppColor.liteBlue,
                  backgroundImage: AssetImage(ride.photoAsset),
                ),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColor.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Center(
                    child: Image.asset(AppAssets.camera, height: 14),
                  ),
                ),
              ],
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
          const SizedBox(height: 26),
          AccountGroup(
            children: [
              AccountTile(
                asset: AppAssets.profile_2user,
                title: 'Personal info',
                body: 'Name, phone, email, language',
                onTap: () => _open(PersonalInfoPage(controller: _profile)),
              ),
              AccountTile(
                asset: AppAssets.verify,
                title: 'Security',
                body: 'Passkeys, 2-step, devices',
                onTap: () => _open(SecurityPage(controller: _profile)),
              ),
              AccountTile(
                asset: AppAssets.privacyPolicy,
                title: 'Privacy',
                body: 'How Movera uses your data',
                showDivider: false,
                onTap: () => _open(PrivacyPage(controller: _profile)),
              ),
            ],
          ),
          if (!ride.checkupComplete) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Material(
                color: AppColor.liteBlue,
                borderRadius: BorderRadius.circular(22),
                child: InkWell(
                  onTap: () => _open(AccountCheckupPage(controller: _profile)),
                  borderRadius: BorderRadius.circular(22),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                    child: Row(
                      children: [
                        Image.asset(AppAssets.verify, height: 56),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Finish your account',
                                style: accountText(
                                  15.5,
                                  weight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Add recovery and 2-step so this account stays yours.',
                                style: accountText(
                                  13,
                                  color: kAccountMuted,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          AccountGroup(
            children: [
              AccountTile(
                asset: AppAssets.safety,
                title: 'Safety',
                body: 'Share a trip and reach help fast',
                onTap: () => _open(const SafetyHub()),
              ),
              AccountTile(
                asset: AppAssets.support,
                title: 'Support',
                body: 'Help with a ride or reservation',
                onTap: () => _open(const SupportHome()),
              ),
              AccountTile(
                asset: AppAssets.document,
                title: 'Terms',
                body: 'How Movera rides work',
                onTap: () => _open(const AccountLegalPage(kind: 'terms')),
              ),
              AccountTile(
                asset: AppAssets.privacyPolicy,
                title: 'Privacy notice',
                body: 'What we keep and why',
                showDivider: false,
                onTap: () => _open(const AccountLegalPage(kind: 'privacy')),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Center(
            child: TextButton(
              onPressed: () async {
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
              child: Text(
                'Log out',
                style: accountText(
                  15,
                  weight: FontWeight.w600,
                  color: const Color(0xFFB42318),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
