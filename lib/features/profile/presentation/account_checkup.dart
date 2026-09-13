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
      title: 'Account check',
      child: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: Text(
              'A few steps keep this Movera account easy to recover.',
              style: accountText(14, color: kAccountMuted, height: 1.45),
            ),
          ),
          AccountRow(
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
                RightToLeftTransition(PersonalInfoPage(controller: _profile)),
              );
            },
          ),
          AccountRow(
            title: '2-step verification',
            body: ride.twoStepEnabled ? 'On' : 'Turn on an extra sign-in check',
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
          AccountRow(
            title: 'Recovery phone',
            body: ride.recoveryPhone ?? 'Add a backup number',
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
    );
  }
}
