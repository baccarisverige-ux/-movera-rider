import 'package:flutter/material.dart';
import 'package:movera_rider/app/di.dart';
import 'package:movera_rider/core/constants/appassets.dart';
import 'package:movera_rider/features/profile/application/profile_controller.dart';
import 'package:movera_rider/features/profile/domain/profile.dart';
import 'package:movera_rider/features/profile/presentation/account_widgets.dart';
import 'package:movera_rider/shared/design_system/adaptive_switch_colors.dart';

class SecurityPage extends StatefulWidget {
  const SecurityPage({super.key, this.controller});

  final ProfileController? controller;

  @override
  State<SecurityPage> createState() => _SecurityPageState();
}

class _SecurityPageState extends State<SecurityPage> {
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

  String _passwordLine(DateTime when) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return 'Last changed ${when.day} ${months[when.month - 1]} ${when.year}';
  }

  @override
  Widget build(BuildContext context) {
    final ride = _profile.profile;
    return AccountScaffold(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 36),
        children: [
          const AccountHeadline('Security', body: 'How you sign in to Movera.'),
          const SizedBox(height: 18),
          AccountGroup(
            children: [
              AccountTile(
                mark: const AccountIcon(Icons.key_outlined),
                title: 'Passkeys',
                body: ride.passkeyEnabled
                    ? 'Ready on this device'
                    : 'Face ID or a device passkey',
                onTap: () {
                  _profile.update(
                    ride.copyWith(passkeyEnabled: !ride.passkeyEnabled),
                  );
                },
              ),
              AccountTile(
                mark: const AccountIcon(Icons.password_outlined),
                title: 'Password',
                body: _passwordLine(ride.passwordUpdatedAt),
                onTap: () async {
                  final next = await showAccountTextEditor(
                    context,
                    title: 'New password',
                    value: '',
                  );
                  if (next != null && next.length >= 8) {
                    await _profile.update(
                      ride.copyWith(passwordUpdatedAt: DateTime.now()),
                    );
                  }
                },
              ),
              AccountTile(
                mark: const AccountIcon(Icons.phonelink_lock_outlined),
                title: 'Authenticator',
                body: ride.authenticatorEnabled
                    ? 'One-time codes are on'
                    : 'Add codes from an authenticator app',
                onTap: () {
                  _profile.update(
                    ride.copyWith(
                      authenticatorEnabled: !ride.authenticatorEnabled,
                    ),
                  );
                },
              ),
              AccountTile(
                mark: const AccountIcon(Icons.security_outlined),
                title: '2-step verification',
                body: ride.twoStepEnabled
                    ? 'On  ·  extra check after password'
                    : 'Off  ·  add an extra check after password',
                trailing: Switch.adaptive(
                  value: ride.twoStepEnabled,
                  activeThumbColor: adaptiveSwitchThumbColor(
                    context,
                    kAccountAccent,
                  ),
                  activeTrackColor: adaptiveSwitchTrackColor(
                    context,
                    kAccountAccent,
                  ),
                  onChanged: (on) {
                    _profile.update(ride.copyWith(twoStepEnabled: on));
                  },
                ),
              ),
              AccountTile(
                mark: const AccountIcon(Icons.phone_iphone_outlined),
                title: 'Recovery phone',
                body: ride.recoveryPhone ?? 'Add a backup number',
                showDivider: false,
                onTap: () async {
                  final next = await showAccountTextEditor(
                    context,
                    title: 'Recovery phone',
                    value: ride.recoveryPhone ?? ride.phone,
                    keyboard: TextInputType.phone,
                  );
                  if (next != null && next.isNotEmpty) {
                    await _profile.update(ride.copyWith(recoveryPhone: next));
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 20, 10),
            child: Text(
              'Connected accounts',
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
                mark: Image.asset(AppAssets.google, height: 20),
                title: 'Google',
                body: ride.googleConnected ? 'Connected' : 'Not connected',
                trailing: TextButton(
                  onPressed: () {
                    _profile.update(
                      ride.copyWith(googleConnected: !ride.googleConnected),
                    );
                  },
                  child: Text(
                    ride.googleConnected ? 'Disconnect' : 'Connect',
                    style: accountText(13.5, weight: FontWeight.w600),
                  ),
                ),
              ),
              AccountTile(
                mark: Image.asset(AppAssets.apple, height: 20),
                title: 'Apple',
                body: ride.appleConnected ? 'Connected' : 'Not connected',
                showDivider: false,
                trailing: TextButton(
                  onPressed: () {
                    _profile.update(
                      ride.copyWith(appleConnected: !ride.appleConnected),
                    );
                  },
                  child: Text(
                    ride.appleConnected ? 'Disconnect' : 'Connect',
                    style: accountText(13.5, weight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 20, 10),
            child: Text(
              'Login activity',
              style: accountText(
                13,
                weight: FontWeight.w600,
                color: kAccountMuted,
              ),
            ),
          ),
          AccountGroup(
            children: [
              for (var i = 0; i < ride.logins.length; i++)
                _LoginTile(
                  session: ride.logins[i],
                  showDivider: i != ride.logins.length - 1,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: AccountTile(
              title: 'Sign out other devices',
              body: 'Keeps this browser signed in.',
              showDivider: false,
              onTap: () async {
                final confirm = await showAccountChoice(
                  context,
                  title: 'Sign out other devices?',
                  options: const ['Sign out others', 'Cancel'],
                  selected: '',
                );
                if (confirm != 'Sign out others') return;
                await _profile.update(
                  ride.copyWith(
                    logins: ride.logins.where((item) => item.current).toList(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginTile extends StatelessWidget {
  const _LoginTile({required this.session, required this.showDivider});

  final LoginSession session;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return AccountTile(
      mark: const AccountIcon(Icons.smartphone_outlined),
      title: session.device,
      body: session.current
          ? 'This session  ·  ${session.place}'
          : '${session.place}  ·  ${session.source}',
      showDivider: showDivider,
    );
  }
}
