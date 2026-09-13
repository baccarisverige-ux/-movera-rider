import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movera_rider/shared/design_system/movera_sheet.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

const Color kAccountInk = Color(0xFF172127);
const Color kAccountMuted = Color(0xFF7B858B);
const Color kAccountLine = Color(0xFFE6E9EB);
const Color kAccountSoft = Color(0xFFF5F6F6);
const Color kAccountCta = Color(0xFF11181D);
const Color kAccountAccent = Color(0xFF356879);

TextStyle accountText(
  double size, {
  FontWeight weight = FontWeight.w400,
  Color color = kAccountInk,
  double? height,
}) {
  return GoogleFonts.poppins(
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
  );
}

class AccountScaffold extends StatelessWidget {
  const AccountScaffold({
    super.key,
    required this.title,
    required this.child,
    this.actions = const [],
  });

  final String title;
  final Widget child;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          SizedBox(height: top + 4),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 12, 8),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: kAccountInk),
                ),
                Expanded(
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: accountText(16, weight: FontWeight.w600),
                  ),
                ),
                ...actions,
                if (actions.isEmpty) const SizedBox(width: 48),
              ],
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class AccountSection extends StatelessWidget {
  const AccountSection(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 8),
      child: Text(label, style: accountText(20, weight: FontWeight.w700)),
    );
  }
}

class AccountRow extends StatelessWidget {
  const AccountRow({
    super.key,
    required this.title,
    this.body,
    this.trailing,
    this.onTap,
    this.danger = false,
  });

  final String title;
  final String? body;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return PointerInterceptor(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 16, 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: accountText(
                        15,
                        weight: FontWeight.w600,
                        color: danger ? const Color(0xFFB42318) : kAccountInk,
                      ),
                    ),
                    if (body != null && body!.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        body!,
                        style: accountText(
                          13,
                          color: kAccountMuted,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              trailing ??
                  (onTap == null
                      ? const SizedBox.shrink()
                      : const Icon(
                          Icons.chevron_right_rounded,
                          color: kAccountMuted,
                        )),
            ],
          ),
        ),
      ),
    );
  }
}

class AccountCardButton extends StatelessWidget {
  const AccountCardButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: PointerInterceptor(
        child: Material(
          color: kAccountSoft,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Column(
                children: [
                  Icon(icon, size: 26, color: kAccountInk),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: accountText(12, weight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AccountFillButton extends StatelessWidget {
  const AccountFillButton({
    super.key,
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PointerInterceptor(
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: Material(
          color: kAccountCta,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Center(
              child: Text(
                label,
                style: accountText(
                  15,
                  weight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<String?> showAccountTextEditor(
  BuildContext context, {
  required String title,
  required String value,
  TextInputType keyboard = TextInputType.text,
}) {
  final controller = TextEditingController(text: value);
  return MoveraSheet.show<String>(
    context: context,
    builder: (context) {
      return Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          8,
          20,
          16 + MediaQuery.paddingOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: accountText(20, weight: FontWeight.w700)),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              keyboardType: keyboard,
              autofocus: true,
              style: accountText(16),
              decoration: InputDecoration(
                filled: true,
                fillColor: kAccountSoft,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            AccountFillButton(
              label: 'Save',
              onTap: () => Navigator.pop(context, controller.text.trim()),
            ),
          ],
        ),
      );
    },
  );
}

Future<String?> showAccountChoice(
  BuildContext context, {
  required String title,
  required List<String> options,
  required String selected,
}) {
  return MoveraSheet.show<String>(
    context: context,
    builder: (context) {
      return Padding(
        padding: EdgeInsets.fromLTRB(
          12,
          8,
          12,
          16 + MediaQuery.paddingOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Text(
                title,
                style: accountText(20, weight: FontWeight.w700),
              ),
            ),
            for (final option in options)
              AccountRow(
                title: option,
                trailing: option == selected
                    ? const Icon(Icons.check_rounded, color: kAccountAccent)
                    : const SizedBox.shrink(),
                onTap: () => Navigator.pop(context, option),
              ),
          ],
        ),
      );
    },
  );
}

class AccountLegalPage extends StatelessWidget {
  const AccountLegalPage({super.key, required this.kind});

  final String kind;

  @override
  Widget build(BuildContext context) {
    final terms = kind == 'terms';
    return AccountScaffold(
      title: terms ? 'Terms' : 'Privacy notice',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(
            terms ? 'Movera terms for riders' : 'Movera privacy notice',
            style: accountText(24, weight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Text(
            terms
                ? 'Book now and scheduled rides are separate. A reservation keeps the same ID if you edit it. Cancel before pickup according to the waiting window on the reservation.'
                : 'Movera stores the name, phone, email, and places you save so we can run your trips. You can change communication preferences any time. Location is used for pickup, tracking, and safety tools while a ride is active.',
            style: accountText(14.5, color: kAccountMuted, height: 1.5),
          ),
        ],
      ),
    );
  }
}
