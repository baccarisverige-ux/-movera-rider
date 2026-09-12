import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movera_rider/shared/widgets/navigation_transition.dart';

class SupportHome extends StatelessWidget {
  const SupportHome({super.key});

  static const Color _ink = Color(0xFF1D252C);
  static const Color _muted = Color(0xFF778189);
  static const Color _line = Color(0xFFE7EBEE);
  static const Color _accent = Color(0xFF2D5878);
  static const Color _cta = Color(0xFF11181D);
  static const Color _soft = Color(0xFFF6F8FA);
  static const Color _accentSoft = Color(0xFFEAF2F8);

  static TextStyle text(
    double size, {
    FontWeight weight = FontWeight.w400,
    Color color = _ink,
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

  static final List<SupportRide> rides = [
    SupportRide(
      title: 'Klockarvägen 37, Södertälje 15159',
      when: DateTime(2026, 8, 31, 17, 0),
      price: 229,
      image: 'assets/images/rides/movera.png',
    ),
    SupportRide(
      title: 'Alby Centrum',
      when: DateTime(2026, 9, 1, 15, 40),
      price: 211,
      image: 'assets/images/rides/comfort.png',
    ),
    SupportRide(
      title: 'Fotoautomat Arlanda Terminal 5',
      when: DateTime(2026, 8, 30, 21, 25),
      price: 0,
      image: 'assets/images/rides/electric.png',
      cancelled: true,
      extra: '2 drivers',
    ),
    SupportRide(
      title: 'Bilia Länna Mercedes-Benz',
      when: DateTime(2026, 6, 3, 16, 29),
      price: 463,
      image: 'assets/images/rides/xl.png',
    ),
    SupportRide(
      title: 'Bilia Södertälje – Mercedes-Benz',
      when: DateTime(2025, 10, 29, 15, 32),
      price: 0,
      image: 'assets/images/rides/premium.png',
      failed: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final recent = rides.first;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded, color: _ink),
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Support',
                        style: text(34, weight: FontWeight.w700, letterSpacing: -0.8),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'What can we help with?',
                        style: text(16, color: _muted),
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
                Text('Recent trips', style: text(16, weight: FontWeight.w700)),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    RightToLeftTransition(const SelectSupportRide()),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'See all',
                        style: text(14, weight: FontWeight.w600, color: _accent),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: _accent, size: 18),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _RideTile(
              ride: recent,
              filled: true,
              onTap: () => Navigator.push(
                context,
                RightToLeftTransition(SelectIssue(ride: recent)),
              ),
            ),
            const SizedBox(height: 28),
            Text('Something else', style: text(16, weight: FontWeight.w700)),
            const SizedBox(height: 10),
            _ActionCard(
              title: 'Contact a support agent',
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

class SupportRide {
  const SupportRide({
    required this.title,
    required this.when,
    required this.price,
    required this.image,
    this.cancelled = false,
    this.failed = false,
    this.extra,
  });

  final String title;
  final DateTime when;
  final double price;
  final String image;
  final bool cancelled;
  final bool failed;
  final String? extra;

  String get whenLabel {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final hour = when.hour.toString().padLeft(2, '0');
    final minute = when.minute.toString().padLeft(2, '0');
    return '${months[when.month - 1]} ${when.day} · $hour:$minute';
  }

  String get monthTitle {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return '${months[when.month - 1]} ${when.year}';
  }

  String get priceLabel {
    if (cancelled) {
      return extra == null ? 'kr 0 · Cancelled' : 'kr 0 · Cancelled · $extra';
    }
    if (failed) return 'Failed';
    return 'kr ${price.toStringAsFixed(0)}';
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
          for (final entry in grouped.entries) ...[
            Text(
              entry.key,
              style: SupportHome.text(16, weight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            for (final ride in entry.value)
              _RideTile(
                ride: ride,
                onTap: () => Navigator.push(
                  context,
                  RightToLeftTransition(SelectIssue(ride: ride)),
                ),
              ),
            const SizedBox(height: 18),
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
      title: 'Select an issue',
      trailing: _exit(context),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          _RideTile(ride: ride, outlined: true),
          const SizedBox(height: 22),
          Text(
            'Select an issue',
            style: SupportHome.text(18, weight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
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
    ('About Movera', 'Who we are, cities we serve, and how Movera works.'),
    ('App and features', 'Maps, categories, scheduling, and account tools.'),
    ('Account and data', 'Phone, profile, privacy, and saved places.'),
    ('Payments and pricing', 'Cards, Swish, cash, Wallet, and fares.'),
    ('Using Movera', 'Booking, waiting, and completing a trip.'),
    ('Safety', 'Share trip, emergency help, and trusted contacts.'),
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
        child: Text(
          '$body\n\nIf you still need help, contact Movera Support. An agent can look up your trip, fare, and payment method.',
          style: SupportHome.text(15, color: SupportHome._ink, height: 1.5),
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
          const SizedBox(height: 16),
          Text(
            'No messages found',
            style: SupportHome.text(14, color: SupportHome._muted),
          ),
          const SizedBox(height: 32),
          Text('Closed', style: SupportHome.text(18, weight: FontWeight.w700)),
          const SizedBox(height: 8),
          _CaseRow(
            title: 'I was charged for cancellation',
            preview: 'Hi. Thanks for getting in touch. After checking this trip…',
            date: '29 October 2024',
          ),
          _CaseRow(
            title: 'I want to cancel my delayed order',
            preview: 'Thanks for reaching out again. Please summarize…',
            date: '28 October 2024',
          ),
          _CaseRow(
            title: 'I want to cancel my delayed order',
            preview: 'Yes',
            date: '28 October 2024',
          ),
        ],
      ),
    );
  }
}

class SupportChat extends StatefulWidget {
  const SupportChat({super.key, this.ride, this.issue});

  final SupportRide? ride;
  final String? issue;

  @override
  State<SupportChat> createState() => _SupportChatState();
}

class _SupportChatState extends State<SupportChat> {
  final _controller = TextEditingController();
  final _messages = <_ChatLine>[];

  @override
  void initState() {
    super.initState();
    final ride = widget.ride;
    _messages.add(
      _ChatLine(
        fromBot: true,
        text: ride == null
            ? 'Hi, I’m Mira from Movera Support. How can we help?'
            : 'Hey! How can we help with your ride to ${ride.title}?',
      ),
    );
    if (widget.issue != null) {
      _messages.add(_ChatLine(fromBot: false, text: widget.issue!));
      _messages.add(
        _ChatLine(
          fromBot: true,
          text:
              'Thanks, I looked at this trip. Tell me a bit more and I’ll take it from here.',
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(_ChatLine(fromBot: false, text: text));
      _messages.add(
        _ChatLine(
          fromBot: true,
          text:
              'Got it. A Movera agent can follow up on this. You’ll also find the case under Support messages.',
        ),
      );
    });
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final ride = widget.ride;
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
                    icon: const Icon(Icons.arrow_back_rounded, color: SupportHome._ink),
                  ),
                  const CircleAvatar(
                    radius: 18,
                    backgroundColor: SupportHome._accentSoft,
                    child: Icon(Icons.smart_toy_outlined, color: SupportHome._accent, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mira',
                          style: SupportHome.text(15, weight: FontWeight.w700),
                        ),
                        Text(
                          'Movera Support',
                          style: SupportHome.text(12, color: SupportHome._muted),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.popUntil(context, (route) => route.isFirst || route.settings.name == null),
                    child: Text(
                      'Exit',
                      style: SupportHome.text(14, weight: FontWeight.w600, color: SupportHome._accent),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: SupportHome._line),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      border: Border.all(color: SupportHome._line),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      'You’re chatting with Mira, Movera’s support assistant. We use this conversation to help with your trip.',
                      style: SupportHome.text(13, color: SupportHome._ink, height: 1.4),
                    ),
                  ),
                  if (ride != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: SupportHome._accentSoft,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFD5E3EC)),
                      ),
                      child: _RideTile(ride: ride, compact: true),
                    ),
                  ],
                  const SizedBox(height: 18),
                  for (final line in _messages) ...[
                    Align(
                      alignment: line.fromBot ? Alignment.centerLeft : Alignment.centerRight,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                        constraints: const BoxConstraints(maxWidth: 320),
                        decoration: BoxDecoration(
                          color: line.fromBot ? SupportHome._soft : SupportHome._ink,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          line.text,
                          style: SupportHome.text(
                            14,
                            height: 1.4,
                            color: line.fromBot ? SupportHome._ink : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                  if (widget.issue == null && ride != null) ...[
                    const SizedBox(height: 8),
                    _Choice(
                      label: 'Share feedback about the driver or vehicle',
                      onTap: () => _send('Share feedback about the driver or vehicle'),
                    ),
                    _Choice(
                      label: 'That’s all I need',
                      onTap: () => Navigator.pop(context),
                    ),
                    _Choice(
                      label: 'Help with something else',
                      onTap: () => _send('Help with something else'),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: TextField(
                controller: _controller,
                onSubmitted: _send,
                decoration: InputDecoration(
                  hintText: 'Describe your issue',
                  hintStyle: SupportHome.text(14, color: SupportHome._muted),
                  filled: true,
                  fillColor: SupportHome._soft,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: IconButton(
                    onPressed: () => _send(_controller.text),
                    icon: const Icon(Icons.send_rounded, color: SupportHome._accent),
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

class _ChatLine {
  const _ChatLine({required this.fromBot, required this.text});
  final bool fromBot;
  final String text;
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
                    icon: const Icon(Icons.arrow_back_rounded, color: SupportHome._ink),
                  ),
                  const Spacer(),
                  if (trailing != null) trailing!,
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Text(
                title,
                style: SupportHome.text(28, weight: FontWeight.w700, letterSpacing: -0.6),
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
      style: SupportHome.text(14, weight: FontWeight.w600, color: SupportHome._accent),
    ),
  );
}

class _RideTile extends StatelessWidget {
  const _RideTile({
    required this.ride,
    this.onTap,
    this.filled = false,
    this.outlined = false,
    this.compact = false,
  });

  final SupportRide ride;
  final VoidCallback? onTap;
  final bool filled;
  final bool outlined;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final body = Padding(
      padding: EdgeInsets.all(compact ? 0 : 14),
      child: Row(
        children: [
          Container(
            width: compact ? 48 : 58,
            height: compact ? 48 : 58,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Image.asset(
              ride.image,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.directions_car_filled_rounded,
                color: SupportHome._muted,
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
                  style: SupportHome.text(12.5, color: SupportHome._muted),
                ),
                Text(
                  ride.priceLabel,
                  style: SupportHome.text(12.5, color: SupportHome._muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    final card = Container(
      margin: compact ? EdgeInsets.zero : const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: filled ? SupportHome._soft : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: outlined || !filled
            ? Border.all(color: SupportHome._line)
            : null,
      ),
      child: body,
    );
    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(16), child: card),
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
      color: SupportHome._soft,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          child: Row(
            children: [
              Expanded(
                child: Text(title, style: SupportHome.text(15, weight: FontWeight.w600)),
              ),
              Icon(icon, color: SupportHome._accent, size: 28),
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
          leading: icon == null
              ? null
              : Icon(icon, color: SupportHome._ink),
          title: Text(
            title,
            style: SupportHome.text(
              15.5,
              weight: FontWeight.w500,
              color: accent ? SupportHome._accent : SupportHome._ink,
            ),
          ),
          trailing: Icon(
            Icons.chevron_right_rounded,
            color: accent ? SupportHome._accent : SupportHome._muted,
          ),
        ),
        const Divider(height: 1, indent: 12, endIndent: 12, color: SupportHome._line),
      ],
    );
  }
}

class _Choice extends StatelessWidget {
  const _Choice({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: SupportHome._line),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(label, style: SupportHome.text(15, weight: FontWeight.w600)),
                ),
                const Icon(Icons.chevron_right_rounded, color: SupportHome._muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CaseRow extends StatelessWidget {
  const _CaseRow({
    required this.title,
    required this.preview,
    required this.date,
  });

  final String title;
  final String preview;
  final String date;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.chat_bubble_outline_rounded, color: SupportHome._muted),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: SupportHome.text(15, weight: FontWeight.w600, color: SupportHome._muted)),
                Text(preview, maxLines: 1, overflow: TextOverflow.ellipsis, style: SupportHome.text(13, color: SupportHome._muted)),
                Text(date, style: SupportHome.text(12, color: SupportHome._muted)),
              ],
            ),
          ),
        ],
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
                child: const Icon(Icons.person_rounded, color: Colors.white, size: 18),
              ),
            ),
        ],
      ),
    );
  }
}
