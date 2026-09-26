import 'dart:async';

import 'package:flutter/material.dart';
import 'package:movera_rider/app/di.dart';
import 'package:movera_rider/core/constants/appcolors.dart';
import 'package:movera_rider/features/profile/application/account_security_controller.dart';
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
  late final AccountSecurityController _security;

  @override
  void initState() {
    super.initState();
    _profile = widget.controller ?? AppScope.instance.profile;
    _security = AppScope.instance.accountSecurity;
    _profile.addListener(_refresh);
    _security.addListener(_refresh);
    if (_security.state == null && !_security.loading) {
      unawaited(_security.load());
    }
  }

  @override
  void dispose() {
    _profile.removeListener(_refresh);
    _security.removeListener(_refresh);
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
    final name = ride.name.trim().isEmpty ? 'Profile not set' : ride.name;
    final email = ride.email.trim().isEmpty ? 'Email not added' : ride.email;
    final hasPhoto = ride.photoAsset.trim().isNotEmpty;
    final security = _security.available ? _security.state : null;
    final checkupComplete = security?.checkupComplete == true;

    return AccountScaffold(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 36),
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 0, 4, 18),
            child: AccountHeadline(
              'Account',
              body: 'Your Movera profile and account settings.',
            ),
          ),
          AccountGroup(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColor.liteBlue,
                      backgroundImage: hasPhoto ? AssetImage(ride.photoAsset) : null,
                      child: hasPhoto
                          ? null
                          : const Icon(Icons.person_outline_rounded),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: accountText(18, weight: FontWeight.w600),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            email,
                            style: accountText(13, color: kAccountMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          AccountGroup(
            children: [
              AccountTile(
                mark: const AccountIcon(Icons.person_outline_rounded),
                title: 'Personal info',
                body: 'Name, phone, email, language',
                onTap: () => _open(PersonalInfoPage(controller: _profile)),
              ),
              AccountTile(
                mark: const AccountIcon(Icons.verified_user_outlined),
                title: 'Security',
                body: 'Passkeys, 2-step, devices',
                onTap: () => _open(SecurityPage(securityController: _security)),
              ),
              AccountTile(
                mark: const AccountIcon(Icons.lock_outline_rounded),
                title: 'Privacy',
                body: 'How Movera uses your data',
                showDivider: false,
                onTap: () => _open(PrivacyPage(controller: _profile)),
              ),
            ],
          ),
          if (!checkupComplete) ...[
            const SizedBox(height: 14),
            AccountGroup(
              children: [
                AccountTile(
                  mark: const AccountIcon(Icons.task_alt_rounded),
                  title: 'Finish your account',
                  body: security == null
                      ? 'Security status unavailable.'
                      : 'Add verified recovery and 2-step so this account stays yours.',
                  showDivider: false,
                  onTap: () => _open(
                    AccountCheckupPage(
                      controller: _profile,
                      securityController: _security,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          AccountGroup(
            children: [
              AccountTile(
                mark: const AccountIcon(Icons.verified_outlined),
                title: 'Safety',
                body: 'Share a trip and reach help fast',
                onTap: () => _open(const SafetyHub()),
              ),
              AccountTile(
                mark: const AccountIcon(Icons.headset_mic_outlined),
                title: 'Support',
                body: 'Help with a ride or reservation',
                onTap: () => _open(const SupportHome()),
              ),
              AccountTile(
                mark: const AccountIcon(Icons.description_outlined),
                title: 'Terms',
                body: 'How Movera rides work',
                onTap: () => _open(const AccountLegalPage(kind: 'terms')),
              ),
              AccountTile(
                mark: const AccountIcon(Icons.privacy_tip_outlined),
                title: 'Privacy notice',
                body: 'What we keep and why',
                showDivider: false,
                onTap: () => _open(const AccountLegalPage(kind: 'privacy')),
              ),
            ],
          ),

        ],
      ),
    );
  }
}
