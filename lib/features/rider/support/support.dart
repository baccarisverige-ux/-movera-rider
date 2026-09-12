import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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

  static final List<SupportRide> rides = [
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
      title: 'Klockarvägen 37, Södertälje 15159',
      when: DateTime(2026, 8, 31, 17, 0),
      price: 229,
      image: 'assets/images/rides/movera.png',
    ),
    SupportRide(
      title: 'Fotoautomat Arlanda Terminal 5',
      when: DateTime(2026, 8, 30, 21, 21),
      price: 0,
      image: 'assets/images/rides/movera.png',
      cancelled: true,
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
                        style: text(34, weight: FontWeight.w700, letterSpacing: -0.8),
                      ),
                      const SizedBox(height: 6),
                      Text('What can we help with?', style: text(16, color: muted)),
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
                  child: Text('View all', style: text(14, weight: FontWeight.w500, color: muted)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (final ride in recent)
              _RideCard(
                ride: ride,
                onTap: () => Navigator.push(
                  context,
                  RightToLeftTransition(SelectIssue(ride: ride)),
                ),
              ),
            const SizedBox(height: 20),
            Text('Browse all help topics', style: text(16, weight: FontWeight.w700)),
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
                            'Pay with Apple Pay, Google Pay, card, Swish, Wallet, or cash to the driver. Fares are shown before you confirm. If a charge looks wrong, open the trip and contact Movera Support.',
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
                            'Update your phone, name, and saved places in Account. Movera only uses trip data to run your ride and support cases.',
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
    final hour = when.hour % 12 == 0 ? 12 : when.hour % 12;
    final minute = when.minute.toString().padLeft(2, '0');
    final ampm = when.hour >= 12 ? 'PM' : 'AM';
    return '${months[when.month - 1]} ${when.day} · $hour:$minute $ampm';
  }

  String get longWhen {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    final hour = when.hour.toString().padLeft(2, '0');
    final minute = when.minute.toString().padLeft(2, '0');
    return '${when.day} ${months[when.month - 1]} · $hour:$minute · $priceLabel';
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
            Text(entry.key, style: SupportHome.text(16, weight: FontWeight.w700)),
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
          Text('Select an issue', style: SupportHome.text(22, weight: FontWeight.w700)),
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
    ('About Movera', 'Movera is a Stockholm-area ride app. Choose Movera, Comfort, Premium, Priority, XL, Electric, or Pet, then pay with Apple Pay, card, Swish, Wallet, or cash.'),
    ('App and features', 'Use the map to set pickup and drop-off, pick a category, and follow the driver. Schedule a ride when you need a later pickup.'),
    ('Account and data', 'Your number, saved places, and trip history stay in your account. You can update them anytime in Account.'),
    ('Payments and pricing', 'The fare is shown before you confirm. Offer a different amount with the stepper, or pay the driver in cash or Swish.'),
    ('Using Movera', 'Confirm pickup, choose a ride, and wait for a nearby driver. Cancel before pickup if plans change.'),
    ('Safety', 'Share your trip, call the driver from the app, and contact support if something feels off.'),
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
                RightToLeftTransition(HelpArticle(title: topic.$1, body: topic.$2)),
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
                  'Contact support',
                  style: SupportHome.text(15.5, weight: FontWeight.w600, color: Colors.white),
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
          const SizedBox(height: 16),
          Text('No messages found', style: SupportHome.text(14, color: SupportHome.muted)),
          const SizedBox(height: 32),
          Text('Closed', style: SupportHome.text(18, weight: FontWeight.w700)),
          const SizedBox(height: 8),
          _CaseRow(
            title: 'I was charged for cancellation',
            preview: 'Hi. Thanks for getting in touch. After checking this trip…',
            date: '29 October 2024',
            onTap: () => Navigator.push(
              context,
              RightToLeftTransition(
                SupportChat(
                  ride: SupportHome.rides[1],
                  issue: 'I was charged for cancellation',
                ),
              ),
            ),
          ),
          _CaseRow(
            title: 'I want to cancel my delayed order',
            preview: 'Thanks for reaching out again. Please summarize…',
            date: '28 October 2024',
            onTap: () => Navigator.push(
              context,
              RightToLeftTransition(const SupportChat(issue: 'I want to cancel my delayed order')),
            ),
          ),
          _CaseRow(
            title: 'I want to cancel my delayed order',
            preview: 'Yes',
            date: '28 October 2024',
            onTap: () => Navigator.push(
              context,
              RightToLeftTransition(const SupportChat(issue: 'I want to cancel my delayed order')),
            ),
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
    final welcome = ride == null
        ? 'Hi, welcome to Movera support.\n\nHow can we help today?'
        : ride.cancelled
            ? 'Hi, welcome to Movera support.\n\nI checked this ride and you were not charged for it. If you’d like to share feedback about the driver or vehicle, choose an option below.'
            : 'Hey! How can we help with your ride to ${ride.title}?';
    _messages.add(_ChatLine(fromBot: true, text: welcome));
    if (widget.issue != null) {
      _messages.add(_ChatLine(fromBot: false, text: widget.issue!));
      _messages.add(
        const _ChatLine(
          fromBot: true,
          text: 'Thanks, I looked at this trip. Tell me a bit more and a Movera agent will take it from here.',
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
        const _ChatLine(
          fromBot: true,
          text:
              'Got it. A Movera agent can follow up on this. You’ll also find the case under Messages.',
        ),
      );
    });
    _controller.clear();
  }

  String get _stamp {
    final now = DateTime.now();
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final hour = now.hour % 12 == 0 ? 12 : now.hour % 12;
    final minute = now.minute.toString().padLeft(2, '0');
    final ampm = now.hour >= 12 ? 'PM' : 'AM';
    return '${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day} at $hour:$minute $ampm';
  }

  @override
  Widget build(BuildContext context) {
    final ride = widget.ride;
    final showChoices = widget.issue == null;
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
                    icon: const Icon(Icons.close_rounded, color: SupportHome.ink),
                  ),
                  Text('Help', style: SupportHome.text(18, weight: FontWeight.w600)),
                  const Spacer(),
                  _PillButton(
                    label: 'End chat',
                    onTap: () => Navigator.popUntil(context, (route) => route.isFirst),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: SupportHome.line),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                children: [
                  Center(
                    child: Text(
                      _stamp,
                      style: SupportHome.text(12, color: SupportHome.muted),
                    ),
                  ),
                  if (ride != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: SupportHome.accentSoft,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFD5E3EC)),
                      ),
                      child: _RideCard(ride: ride, compact: true),
                    ),
                  ],
                  const SizedBox(height: 18),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _MiraMark(),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          children: [
                            for (final line in _messages)
                              if (line.fromBot)
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Text(
                                      line.text,
                                      style: SupportHome.text(15, height: 1.45),
                                    ),
                                  ),
                                )
                              else
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                                    constraints: const BoxConstraints(maxWidth: 280),
                                    decoration: BoxDecoration(
                                      color: SupportHome.ink,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      line.text,
                                      style: SupportHome.text(14, height: 1.4, color: Colors.white),
                                    ),
                                  ),
                                ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (showChoices) ...[
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
                  hintStyle: SupportHome.text(14, color: SupportHome.muted),
                  filled: true,
                  fillColor: SupportHome.soft,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: IconButton(
                    onPressed: () => _send(_controller.text),
                    icon: const Icon(Icons.send_rounded, color: SupportHome.accent),
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
                    icon: const Icon(Icons.arrow_back_rounded, color: SupportHome.ink),
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
      style: SupportHome.text(14, weight: FontWeight.w600, color: SupportHome.accent),
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
                Text(ride.whenLabel, style: SupportHome.text(12.5, color: SupportHome.muted)),
                Text(ride.priceLabel, style: SupportHome.text(12.5, color: SupportHome.muted)),
              ],
            ),
          ),
        ],
      ),
    );
    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(16), child: card),
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
                  Text(ride.whenLabel, style: SupportHome.text(12.5, color: SupportHome.muted)),
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
          const Icon(Icons.directions_car_filled_outlined, color: SupportHome.ink),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ride.title, style: SupportHome.text(14, weight: FontWeight.w600)),
                Text(ride.longWhen, style: SupportHome.text(12.5, color: SupportHome.muted)),
              ],
            ),
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
                child: Text(title, style: SupportHome.text(15, weight: FontWeight.w600)),
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
        const Divider(height: 1, indent: 12, endIndent: 12, color: SupportHome.line),
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
          side: const BorderSide(color: SupportHome.line),
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
                const Icon(Icons.chevron_right_rounded, color: SupportHome.muted),
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
    this.onTap,
  });

  final String title;
  final String preview;
  final String date;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.chat_bubble_outline_rounded, color: SupportHome.muted),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: SupportHome.text(15, weight: FontWeight.w600, color: SupportHome.muted)),
                  Text(
                    preview,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: SupportHome.text(13, color: SupportHome.muted),
                  ),
                  Text(date, style: SupportHome.text(12, color: SupportHome.muted)),
                ],
              ),
            ),
          ],
        ),
      ),
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
              Text(label, style: SupportHome.text(14.5, weight: FontWeight.w600)),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded, size: 18, color: SupportHome.muted),
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
              Text(label, style: SupportHome.text(13.5, weight: FontWeight.w600)),
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
                child: const Icon(Icons.person_rounded, color: Colors.white, size: 18),
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
