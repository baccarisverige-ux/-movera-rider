import 'package:flutter/material.dart';
import 'package:movera_rider/app/di.dart';
import 'package:movera_rider/core/constants/appassets.dart';
import 'package:movera_rider/features/profile/application/profile_controller.dart';
import 'package:movera_rider/features/profile/domain/profile.dart';
import 'package:movera_rider/features/profile/presentation/account_widgets.dart';

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
      title: 'Security',
      child: ListView(
        children: [
          const AccountSection('Sign in'),
          AccountRow(
            title: 'Passkeys',
            body: ride.passkeyEnabled
                ? 'Ready on this device'
                : 'Use Face ID or a device passkey instead of a password.',
            onTap: () async {
              await _profile.update(
                ride.copyWith(passkeyEnabled: !ride.passkeyEnabled),
              );
            },
          ),
          AccountRow(
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
          AccountRow(
            title: 'Authenticator',
            body: ride.authenticatorEnabled
                ? 'Codes from your authenticator app are on'
                : 'Add a one-time code from an authenticator app.',
            onTap: () async {
              await _profile.update(
                ride.copyWith(authenticatorEnabled: !ride.authenticatorEnabled),
              );
            },
          ),
          AccountRow(
            title: '2-step verification',
            body: ride.twoStepEnabled
                ? 'On  ·  extra check after password'
                : 'Off  ·  add an extra check after password',
            trailing: Switch.adaptive(
              value: ride.twoStepEnabled,
              activeColor: kAccountAccent,
              onChanged: (on) {
                _profile.update(ride.copyWith(twoStepEnabled: on));
              },
            ),
          ),
          AccountRow(
            title: 'Recovery phone',
            body: ride.recoveryPhone ?? 'Add a backup number',
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
          const AccountSection('Connected accounts'),
          _SocialRow(
            asset: AppAssets.google,
            label: 'Google',
            connected: ride.googleConnected,
            onTap: () {
              _profile.update(
                ride.copyWith(googleConnected: !ride.googleConnected),
              );
            },
          ),
          _SocialRow(
            asset: AppAssets.apple,
            label: 'Apple',
            connected: ride.appleConnected,
            onTap: () {
              _profile.update(
                ride.copyWith(appleConnected: !ride.appleConnected),
              );
            },
          ),
          const AccountSection('Login activity'),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(
              'Devices that used this Movera account recently.',
              style: accountText(13, color: kAccountMuted, height: 1.4),
            ),
          ),
          for (final session in ride.logins) _LoginCard(session: session),
          AccountRow(
            title: 'Sign out other devices',
            body: 'Keeps this browser signed in.',
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
        ],
      ),
    );
  }
}

class _SocialRow extends StatelessWidget {
  const _SocialRow({
    required this.asset,
    required this.label,
    required this.connected,
    required this.onTap,
  });

  final String asset;
  final String label;
  final bool connected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AccountRow(
      title: label,
      body: connected ? 'Connected' : 'Not connected',
      trailing: TextButton(
        onPressed: onTap,
        child: Text(
          connected ? 'Disconnect' : 'Connect',
          style: accountText(13.5, weight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _LoginCard extends StatelessWidget {
  const _LoginCard({required this.session});

  final LoginSession session;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kAccountLine),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              session.device,
              style: accountText(15, weight: FontWeight.w600),
            ),
            if (session.current)
              Text(
                'This session',
                style: accountText(12.5, color: kAccountAccent),
              ),
            const SizedBox(height: 4),
            Text(session.place, style: accountText(13, color: kAccountMuted)),
            Text(session.source, style: accountText(13, color: kAccountMuted)),
          ],
        ),
      ),
    );
  }
}
