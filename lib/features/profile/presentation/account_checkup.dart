import 'package:flutter/material.dart';
import 'package:movera_rider/app/di.dart';
import 'package:movera_rider/features/profile/application/profile_controller.dart';
import 'package:movera_rider/features/profile/presentation/account_widgets.dart';
import 'package:movera_rider/features/profile/presentation/personal_info.dart';
import 'package:movera_rider/features/profile/presentation/security.dart';
import 'package:movera_rider/shared/widgets/navigation_transition.dart';

class AccountCheckupPage extends StatefulWidget {
  const AccountCheckupPage({super.key, this.controller});

  final ProfileController? controller;

  @override
  State<AccountCheckupPage> createState() => _AccountCheckupPageState();
}

class _AccountCheckupPageState extends State<AccountCheckupPage> {
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
            'Account check',
            body: 'A few steps keep this Movera account easy to recover.',
          ),
          const SizedBox(height: 18),
          AccountGroup(
            children: [
              AccountTile(
                mark: const AccountIcon(Icons.phone_outlined),
                title: 'Phone number',
                body: ride.phoneVerified ? ride.phone : 'Add a phone number',
                trailing: Icon(
                  ride.phoneVerified
                      ? Icons.check_circle_rounded
                      : Icons.circle_outlined,
                  color: ride.phoneVerified ? kAccountAccent : kAccountMuted,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    RightToLeftTransition(
                      PersonalInfoPage(controller: _profile),
                    ),
                  );
                },
              ),
              AccountTile(
                mark: const AccountIcon(Icons.security_outlined),
                title: '2-step verification',
                body: ride.twoStepEnabled
                    ? 'On'
                    : 'Turn on an extra sign-in check',
                trailing: Icon(
                  ride.twoStepEnabled
                      ? Icons.check_circle_rounded
                      : Icons.circle_outlined,
                  color: ride.twoStepEnabled ? kAccountAccent : kAccountMuted,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    RightToLeftTransition(SecurityPage(controller: _profile)),
                  );
                },
              ),
              AccountTile(
                mark: const AccountIcon(Icons.phone_iphone_outlined),
                title: 'Recovery phone',
                body: ride.recoveryPhone ?? 'Add a backup number',
                showDivider: false,
                trailing: Icon(
                  (ride.recoveryPhone ?? '').isNotEmpty
                      ? Icons.check_circle_rounded
                      : Icons.circle_outlined,
                  color: (ride.recoveryPhone ?? '').isNotEmpty
                      ? kAccountAccent
                      : kAccountMuted,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    RightToLeftTransition(SecurityPage(controller: _profile)),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
