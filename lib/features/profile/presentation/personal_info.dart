import 'package:flutter/material.dart';
import 'package:movera_rider/app/di.dart';
import 'package:movera_rider/features/profile/application/profile_controller.dart';
import 'package:movera_rider/features/profile/presentation/account_widgets.dart';

class PersonalInfoPage extends StatefulWidget {
  const PersonalInfoPage({super.key, this.controller});

  final ProfileController? controller;

  @override
  State<PersonalInfoPage> createState() => _PersonalInfoPageState();
}

class _PersonalInfoPageState extends State<PersonalInfoPage> {
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
      title: 'Personal info',
      child: ListView(
        children: [
          const SizedBox(height: 8),
          Center(
            child: CircleAvatar(
              radius: 40,
              backgroundImage: AssetImage(ride.photoAsset),
            ),
          ),
          const AccountSection('Details'),
          AccountRow(
            title: 'Name',
            body: ride.name,
            onTap: () async {
              final next = await showAccountTextEditor(
                context,
                title: 'Name',
                value: ride.name,
              );
              if (next != null && next.isNotEmpty) {
                await _profile.update(ride.copyWith(name: next));
              }
            },
          ),
          AccountRow(
            title: 'Gender',
            body: ride.gender,
            onTap: () async {
              final next = await showAccountChoice(
                context,
                title: 'Gender',
                options: const [
                  'Woman',
                  'Man',
                  'Non-binary',
                  'Prefer not to say',
                ],
                selected: ride.gender,
              );
              if (next != null) {
                await _profile.update(ride.copyWith(gender: next));
              }
            },
          ),
          AccountRow(
            title: 'Phone',
            body: '${ride.phone}  ·  Verified',
            onTap: () async {
              final next = await showAccountTextEditor(
                context,
                title: 'Phone',
                value: ride.phone,
                keyboard: TextInputType.phone,
              );
              if (next != null && next.isNotEmpty) {
                await _profile.update(ride.copyWith(phone: next));
              }
            },
          ),
          AccountRow(
            title: 'Email',
            body: '${ride.email}  ·  Verified',
            onTap: () async {
              final next = await showAccountTextEditor(
                context,
                title: 'Email',
                value: ride.email,
                keyboard: TextInputType.emailAddress,
              );
              if (next != null && next.contains('@')) {
                await _profile.update(ride.copyWith(email: next));
              }
            },
          ),
          AccountRow(
            title: 'Language',
            body: ride.language,
            onTap: () async {
              final next = await showAccountChoice(
                context,
                title: 'Language',
                options: const ['English', 'Svenska'],
                selected: ride.language,
              );
              if (next != null) {
                await _profile.update(ride.copyWith(language: next));
              }
            },
          ),
        ],
      ),
    );
  }
}
