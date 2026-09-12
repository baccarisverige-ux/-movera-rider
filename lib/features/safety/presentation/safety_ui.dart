import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SafetyUi {
  static const ink = Color(0xFF1C2329);
  static const muted = Color(0xFF7A858E);
  static const accent = Color(0xFF2D5878);
  static const canvas = Color(0xFFF3F5F6);
  static const card = Color(0xFFFFFFFF);
  static const line = Color(0xFFE8ECF0);
  static const danger = Color(0xFFB42318);

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

  static BoxDecoration cardDecoration({double radius = 22}) {
    return BoxDecoration(
      color: card,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.035),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }
}

class SafetyScaffold extends StatelessWidget {
  const SafetyScaffold({
    super.key,
    required this.title,
    required this.child,
    this.footer,
  });

  final String title;
  final Widget child;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SafetyUi.canvas,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 20, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                    color: SafetyUi.ink,
                  ),
                  Expanded(
                    child: Text(
                      title,
                      style: SafetyUi.text(17, weight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: child),
            if (footer != null) footer!,
          ],
        ),
      ),
    );
  }
}

class SafetyRow extends StatelessWidget {
  const SafetyRow({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.status,
    this.onTap,
    this.showDivider = true,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? status;
  final VoidCallback? onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 12, 16),
            child: Row(
              children: [
                Icon(icon, size: 22, color: SafetyUi.ink.withOpacity(0.78)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: SafetyUi.text(16, weight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: SafetyUi.text(13, color: SafetyUi.muted, height: 1.35),
                      ),
                    ],
                  ),
                ),
                if (status != null) ...[
                  const SizedBox(width: 8),
                  Text(status!, style: SafetyUi.text(13, color: SafetyUi.accent, weight: FontWeight.w500)),
                ],
                const Icon(Icons.chevron_right_rounded, color: SafetyUi.muted),
              ],
            ),
          ),
        ),
        if (showDivider)
          const Padding(
            padding: EdgeInsets.only(left: 56),
            child: Divider(height: 1, color: SafetyUi.line),
          ),
      ],
    );
  }
}
