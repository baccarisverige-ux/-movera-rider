import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movera_rider/features/support/application/support_controller.dart';
import 'package:movera_rider/features/support/domain/support.dart';
import 'package:movera_rider/shared/widgets/navigation_transition.dart';

class SupportHome extends StatelessWidget {
  const SupportHome({super.key});

  static const Color ink = Color(0xFF1D252C);
  static const Color muted = Color(0xFF778189);
  static const Color line = Color(0xFFE7EBEE);
  static const Color accent = Color(0xFF2D5878);
  static const Color cta = Color(0xFF11181D);
  static const Color soft = Color(0xFFF4F6F8);
  static const Color accentSoft = Color(0xFFEAF2F8);

  static TextStyle text(
    double size, {
    FontWeight weight = FontWeight.w400,
    Color color = ink,
    double? height,
    double? letterSpacing,
  }) {
    return GoogleFonts.poppins(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  static final List<SupportRide> rides = SupportController().rides();

  @override
  Widget build(BuildContext context) {
    final recent = rides.take(3).toList();
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: ink),
                ),
                const Spacer(),
                _PillButton(
                  icon: Icons.mail_outline_rounded,
                  label: 'Messages',
                  onTap: () => Navigator.push(
                    context,
                    RightToLeftTransition(const SupportMessages()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Help',
                        style: text(
                          34,
                          weight: FontWeight.w700,
                          letterSpacing: -0.8,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'What can we help with?',
                        style: text(16, color: muted),
                      ),
                    ],
                  ),
                ),
                const _TeamAvatars(),
              ],
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Text('Select a ride', style: text(16, weight: FontWeight.w700)),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    RightToLeftTransition(const SelectSupportRide()),
                  ),
                  child: Text(
                    'View all',
                    style: text(14, weight: FontWeight.w500, color: muted),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (recent.isEmpty)
              const _EmptyCard(
                title: 'No rides to review',
                subtitle:
                    'Completed or cancelled rides will appear here when real ride history is available.',
              )
            else
              for (final ride in recent)
                _RideCard(
                  ride: ride,
                  onTap: () => Navigator.push(
                    context,
                    RightToLeftTransition(SelectIssue(ride: ride)),
                  ),
                ),
            const SizedBox(height: 20),
            Text(
              'Browse all help topics',
              style: text(16, weight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _TopicChip(
                  label: 'Rides',
                  onTap: () => Navigator.push(
                    context,
                    RightToLeftTransition(const SelectSupportRide()),
                  ),
                ),
                _TopicChip(
                  label: 'Payments',
                  onTap: () => Navigator.push(
                    context,
                    RightToLeftTransition(
                      const HelpArticle(
                        title: 'Payments and pricing',
                        body:
                            'Payment and pricing help will use your real booking and payment data when those support services are connected.',
                      ),
                    ),
                  ),
                ),
                _TopicChip(
                  label: 'Account',
                  onTap: () => Navigator.push(
                    context,
                    RightToLeftTransition(
                      const HelpArticle(
                        title: 'Account and data',
                        body:
                            'Update the account information that is available in the app. Support will only show account or trip details when real data is available.',
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            Text('Something else', style: text(16, weight: FontWeight.w700)),
            const SizedBox(height: 10),
            _ActionCard(
              title: 'Support messaging',
              icon: Icons.headset_mic_rounded,
              onTap: () => Navigator.push(
                context,
                RightToLeftTransition(const HowCanWeHelp()),
              ),
            ),
            const SizedBox(height: 10),
            _ActionCard(
              title: 'Browse help articles',
              icon: Icons.menu_book_rounded,
              onTap: () => Navigator.push(
                context,
                RightToLeftTransition(const HelpArticles()),
              ),
            ),
            const SizedBox(height: 10),
            _ActionCard(
              title: 'Cases',
              icon: Icons.forum_outlined,
              onTap: () => Navigator.push(
                context,
                RightToLeftTransition(const SupportMessages()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HowCanWeHelp extends StatelessWidget {
  const HowCanWeHelp({super.key});

  @override
  Widget build(BuildContext context) {
    return _SupportScaffold(
      title: 'How can we help you?',
      trailing: _exit(context),
      child: Column(
        children: [
          _LineItem(
            icon: Icons.directions_car_filled_outlined,
            title: 'I need help with a ride',
            onTap: () => Navigator.push(
              context,
              RightToLeftTransition(const SelectSupportRide()),
            ),
          ),
          _LineItem(
            icon: Icons.chat_bubble_outline_rounded,
            title: 'Something else',
            onTap: () => Navigator.push(
              context,
              RightToLeftTransition(const SupportChat()),
            ),
          ),
        ],
      ),
    );
  }
}

class SelectSupportRide extends StatelessWidget {
  const SelectSupportRide({super.key});

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<SupportRide>>{};
    for (final ride in SupportHome.rides) {
      grouped.putIfAbsent(ride.monthTitle, () => []).add(ride);
    }
    return _SupportScaffold(
      title: 'Select ride',
      trailing: _exit(context),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          if (grouped.isEmpty)
            const _EmptyCard(
              title: 'No rides yet',
              subtitle:
                  'Completed and cancelled rides will appear here when real ride history is available.',
            )
          else
            for (final entry in grouped.entries) ...[
              Text(
                entry.key,
                style: SupportHome.text(16, weight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              for (final ride in entry.value)
                _RideRow(
                  ride: ride,
                  onTap: () => Navigator.push(
                    context,
                    RightToLeftTransition(SelectIssue(ride: ride)),
                  ),
                ),
              const SizedBox(height: 16),
            ],
        ],
      ),
    );
  }
}

class SelectIssue extends StatelessWidget {
  const SelectIssue({super.key, required this.ride});

  final SupportRide ride;

  static const issues = [
    'I was charged more than expected',
    'I was charged twice',
    'I lost an item',
    'My ride happened without me',
    'The driver didn’t meet expectations',
    'I was wrongly charged a wait time fee',
    'I have a question about tips',
  ];

  @override
  Widget build(BuildContext context) {
    return _SupportScaffold(
      title: '',
      trailing: _exit(context),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          _CompactTrip(ride: ride),
          const SizedBox(height: 28),
          Text(
            'Select an issue',
            style: SupportHome.text(22, weight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          for (final issue in issues)
            _LineItem(
              title: issue,
              onTap: () => Navigator.push(
                context,
                RightToLeftTransition(SupportChat(ride: ride, issue: issue)),
              ),
            ),
          _LineItem(
            title: 'Something else',
            accent: true,
            onTap: () => Navigator.push(
              context,
              RightToLeftTransition(SupportChat(ride: ride)),
            ),
          ),
        ],
      ),
    );
  }
}

class HelpArticles extends StatelessWidget {
  const HelpArticles({super.key});

  static const topics = [
    (
      'About Movera',
      'Movera lets riders choose an available ride category, set pickup and destination, and manage the ride flow in the app.'
    ),
    (
      'App and features',
      'Use the map to set pickup and destination, choose a category, and schedule a ride when you need a later pickup.'
    ),
    (
      'Account and data',
      'Your account only shows information that is actually available in this build. You can edit supported profile fields from Account.'
    ),
    (
      'Payments and pricing',
      'Pricing and payment support will use the real booking and payment record when those services are connected.'
    ),
    (
      'Using Movera',
      'Confirm pickup, choose a ride category, and follow the booking flow shown in the app.'
    ),
    (
      'Safety',
      'Use the available Safety tools in the app if you need safety-related help during a ride.'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return _SupportScaffold(
      title: 'Help articles',
      trailing: _exit(context),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
        children: [
          for (final topic in topics)
            _LineItem(
              title: topic.$1,
              onTap: () => Navigator.push(
                context,
                RightToLeftTransition(
                  HelpArticle(title: topic.$1, body: topic.$2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class HelpArticle extends StatelessWidget {
  const HelpArticle({super.key, required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return _SupportScaffold(
      title: title,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(body, style: SupportHome.text(15, height: 1.5)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: () => Navigator.push(
                  context,
                  RightToLeftTransition(const HowCanWeHelp()),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: SupportHome.cta,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(26),
                  ),
                ),
                child: Text(
                  'Support options',
                  style: SupportHome.text(
                    15.5,
                    weight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SupportMessages extends StatelessWidget {
  const SupportMessages({super.key});

  @override
  Widget build(BuildContext context) {
    return _SupportScaffold(
      title: 'Support messages',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Text('Active', style: SupportHome.text(18, weight: FontWeight.w700)),
          const SizedBox(height: 12),
          const _EmptyCard(
            title: 'No active cases',
            subtitle:
                'Support messaging is not connected in this build, so no active conversations are shown.',
          ),
          const SizedBox(height: 28),
          Text('Closed', style: SupportHome.text(18, weight: FontWeight.w700)),
          const SizedBox(height: 12),
          const _EmptyCard(
            title: 'No closed cases',
            subtitle:
                'Closed support conversations will appear here when real support messaging is connected.',
          ),
        ],
      ),
    );
  }
}

class SupportChat extends StatelessWidget {
  const SupportChat({super.key, this.ride, this.issue});

  final SupportRide? ride;
  final String? issue;

  @override
  Widget build(BuildContext context) {
    final script = SupportController().chat(ride: ride);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 12, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: SupportHome.ink,
                    ),
                  ),
                  Text(
                    'Help',
                    style: SupportHome.text(18, weight: FontWeight.w600),
                  ),
                  const Spacer(),
                  _PillButton(
                    label: 'Close',
                    onTap: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: SupportHome.line),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                children: [
                  if (ride != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: SupportHome.accentSoft,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFD5E3EC)),
                      ),
                      child: _RideCard(ride: ride!, compact: true),
                    ),
                    const SizedBox(height: 18),
                  ],
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _MiraMark(),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              script.welcome,
                              style: SupportHome.text(15, height: 1.45),
                            ),
                            if (issue != null) ...[
                              const SizedBox(height: 14),
                              Align(
                                alignment: Alignment.centerRight,
                                child: Container(
                                  padding: const EdgeInsets.fromLTRB(
                                    14,
                                    12,
                                    14,
                                    12,
                                  ),
                                  constraints:
                                      const BoxConstraints(maxWidth: 280),
                                  decoration: BoxDecoration(
                                    color: SupportHome.ink,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    issue!,
                                    style: SupportHome.text(
                                      14,
                                      height: 1.4,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                script.issueAck,
                                style: SupportHome.text(15, height: 1.45),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: TextField(
                enabled: false,
                decoration: InputDecoration(
                  hintText: 'Support messaging unavailable',
                  hintStyle: SupportHome.text(14, color: SupportHome.muted),
                  filled: true,
                  fillColor: SupportHome.soft,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: const Icon(
                    Icons.send_rounded,
                    color: SupportHome.muted,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SupportScaffold extends StatelessWidget {
  const _SupportScaffold({
    required this.title,
    required this.child,
    this.trailing,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 12, 4),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: SupportHome.ink,
                    ),
                  ),
                  const Spacer(),
                  if (trailing != null) trailing!,
                ],
              ),
            ),
            if (title.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: Text(
                  title,
                  style: SupportHome.text(
                    28,
                    weight: FontWeight.w700,
                    letterSpacing: -0.6,
                  ),
                ),
              ),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

Widget _exit(BuildContext context) {
  return TextButton(
    onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
    child: Text(
      'Exit',
      style: SupportHome.text(
        14,
        weight: FontWeight.w600,
        color: SupportHome.accent,
      ),
    ),
  );
}

class _RideCard extends StatelessWidget {
  const _RideCard({required this.ride, this.onTap, this.compact = false});

  final SupportRide ride;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      margin: compact ? EdgeInsets.zero : const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SupportHome.line),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: SupportHome.soft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Image.asset(
              ride.image,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.directions_car_filled_rounded,
                color: SupportHome.muted,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ride.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: SupportHome.text(14.5, weight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  ride.whenLabel,
                  style: SupportHome.text(12.5, color: SupportHome.muted),
                ),
                Text(
                  ride.priceLabel,
                  style: SupportHome.text(12.5, color: SupportHome.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: card,
      ),
    );
  }
}

class _RideRow extends StatelessWidget {
  const _RideRow({required this.ride, required this.onTap});

  final SupportRide ride;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: SupportHome.soft,
              child: Icon(
                ride.failed || ride.cancelled
                    ? Icons.no_crash_outlined
                    : Icons.directions_car_filled_outlined,
                color: SupportHome.ink,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ride.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: SupportHome.text(14.5, weight: FontWeight.w600),
                  ),
                  Text(
                    ride.whenLabel,
                    style: SupportHome.text(12.5, color: SupportHome.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              ride.failed ? 'Failed' : 'kr ${ride.price.toStringAsFixed(2)}',
              style: SupportHome.text(14, weight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactTrip extends StatelessWidget {
  const _CompactTrip({required this.ride});

  final SupportRide ride;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SupportHome.line),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.directions_car_filled_outlined,
            color: SupportHome.ink,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ride.title,
                  style: SupportHome.text(14, weight: FontWeight.w600),
                ),
                Text(
                  ride.longWhen,
                  style: SupportHome.text(12.5, color: SupportHome.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SupportHome.soft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SupportHome.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: SupportHome.text(15, weight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: SupportHome.text(13, color: SupportHome.muted, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: SupportHome.soft,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: SupportHome.text(15, weight: FontWeight.w600),
                ),
              ),
              Icon(icon, color: SupportHome.accent, size: 28),
            ],
          ),
        ),
      ),
    );
  }
}

class _LineItem extends StatelessWidget {
  const _LineItem({
    required this.title,
    required this.onTap,
    this.icon,
    this.accent = false,
  });

  final String title;
  final VoidCallback onTap;
  final IconData? icon;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          leading: icon == null ? null : Icon(icon, color: SupportHome.ink),
          title: Text(
            title,
            style: SupportHome.text(
              15.5,
              weight: FontWeight.w500,
              color: accent ? SupportHome.accent : SupportHome.ink,
            ),
          ),
          trailing: Icon(
            Icons.chevron_right_rounded,
            color: accent ? SupportHome.accent : SupportHome.muted,
          ),
        ),
        const Divider(
          height: 1,
          indent: 12,
          endIndent: 12,
          color: SupportHome.line,
        ),
      ],
    );
  }
}

class _TopicChip extends StatelessWidget {
  const _TopicChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: SupportHome.line),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: SupportHome.text(14.5, weight: FontWeight.w600),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: SupportHome.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({required this.label, required this.onTap, this.icon});

  final String label;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: SupportHome.soft,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: SupportHome.ink),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: SupportHome.text(13.5, weight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TeamAvatars extends StatelessWidget {
  const _TeamAvatars();

  @override
  Widget build(BuildContext context) {
    const colors = [
      Color(0xFF2D5878),
      Color(0xFF4A7A96),
      Color(0xFF1D252C),
    ];
    return SizedBox(
      width: 86,
      height: 40,
      child: Stack(
        children: [
          for (var i = 0; i < 3; i++)
            Positioned(
              left: i * 22.0,
              child: CircleAvatar(
                radius: 18,
                backgroundColor: colors[i],
                child: const Icon(
                  Icons.person_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MiraMark extends StatelessWidget {
  const _MiraMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: const BoxDecoration(
        color: Color(0xFF2D5878),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.auto_awesome, color: Colors.white, size: 15),
    );
  }
}
