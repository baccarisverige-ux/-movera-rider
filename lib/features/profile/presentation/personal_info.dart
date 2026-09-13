import 'package:flutter/material.dart';
import 'package:movera_rider/app/di.dart';
import 'package:movera_rider/core/constants/appcolors.dart';
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
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 36),
        children: [
          const AccountHeadline(
            'Personal info',
            body: 'Name, phone, and how we reach you.',
          ),
          const SizedBox(height: 20),
          Center(
            child: CircleAvatar(
              radius: 44,
              backgroundColor: AppColor.liteBlue,
              backgroundImage: AssetImage(ride.photoAsset),
            ),
          ),
          const SizedBox(height: 22),
          AccountGroup(
            children: [
              AccountTile(
                mark: const AccountIcon(Icons.badge_outlined),
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
              AccountTile(
                mark: const AccountIcon(Icons.wc_outlined),
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
              AccountTile(
                mark: const AccountIcon(Icons.phone_outlined),
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
              AccountTile(
                mark: const AccountIcon(Icons.mail_outline_rounded),
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
              AccountTile(
                mark: const AccountIcon(Icons.language_rounded),
                title: 'Language',
                body: ride.language,
                showDivider: false,
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
        ],
      ),
    );
  }
}
