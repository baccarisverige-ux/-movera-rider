import 'package:url_launcher/url_launcher.dart';

/// Opens an external `mailto:` link; resolves with whether it opened.
typedef SupportUriLauncher = Future<bool> Function(Uri uri);

/// FLOW-8: a direct way to reach Movera while in-app messaging is not
/// connected. The address comes from the build
/// (`--dart-define=MOVERA_SUPPORT_EMAIL=...`); without one the app shows no
/// contact card rather than an invented address.
class SupportContact {
  const SupportContact({
    this.email = const String.fromEnvironment('MOVERA_SUPPORT_EMAIL'),
    SupportUriLauncher? launcher,
  }) : _launcher = launcher;

  final String email;
  final SupportUriLauncher? _launcher;

  bool get available => email.trim().contains('@');

  Uri mailto({String? subject}) => Uri(
    scheme: 'mailto',
    path: email.trim(),
    query: subject == null || subject.trim().isEmpty
        ? null
        : 'subject=${Uri.encodeComponent(subject.trim())}',
  );

  /// False when no mail app could be opened.
  Future<bool> openEmail({String? subject}) async {
    if (!available) return false;
    try {
      return await (_launcher ?? _launch)(mailto(subject: subject));
    } catch (_) {
      // No mail app or the platform refused: the caller says so.
      return false;
    }
  }

  static Future<bool> _launch(Uri uri) =>
      launchUrl(uri, mode: LaunchMode.externalApplication);
}
