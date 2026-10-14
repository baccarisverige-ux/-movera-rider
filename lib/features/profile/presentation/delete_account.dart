import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movera_rider/core/constants/appassets.dart';
import 'package:movera_rider/core/logging/app_log.dart';
import 'package:movera_rider/features/auth/presentation/sign_out_flow.dart';
import 'package:movera_rider/features/profile/application/account_deletion_controller.dart';
import 'package:movera_rider/features/profile/presentation/account_widgets.dart';
import 'package:movera_rider/shared/widgets/app_icon_asset.dart';

/// Delete account (FLOW-2): says what is deleted, asks once more, sends the
/// request, then signs out and wipes this device.
class DeleteAccountPage extends StatefulWidget {
  const DeleteAccountPage({super.key, this.controller});

  final AccountDeletionController? controller;

  @override
  State<DeleteAccountPage> createState() => _DeleteAccountPageState();
}

class _DeleteAccountPageState extends State<DeleteAccountPage> {
  late final AccountDeletionController _controller =
      widget.controller ?? AccountDeletionController();
  bool _sending = false;
  bool _sent = false;
  String? _error;

  Future<void> _confirmAndSend() async {
    if (_sending) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Delete your account?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'This can\'t be undone. You will be signed out on this device.',
          style: GoogleFonts.poppins(fontSize: 13.5),
        ),
        actions: [
          TextButton(
            key: const ValueKey('delete-account-cancel'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            key: const ValueKey('delete-account-confirm'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFB42318),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await _controller.requestDeletion();
      if (!mounted) return;
      setState(() {
        _sending = false;
        _sent = true;
      });
    } catch (error) {
      AppLog.warning(
        'account.deletion_request_failed',
        extra: {'error': error.toString()},
      );
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error =
            'We couldn\'t send your request. Check your connection and try again.';
      });
    }
  }

  void _done() => showSignInRoot(navigator: Navigator.of(context));

  @override
  Widget build(BuildContext context) {
    if (_sent) return _sentView();
    return AccountScaffold(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 36),
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(4, 0, 4, 18),
            child: AccountHeadline(
              'Delete account',
              body: 'We delete your Movera account and the data tied to it.',
            ),
          ),
          const AccountGroup(
            children: [
              AccountTile(
                mark: AccountIcon.asset(AppAssets.solarUserRounded),
                title: 'Your profile',
                body: 'Name, phone number, email and sign-in methods',
              ),
              AccountTile(
                mark: AccountIcon.asset(AppAssets.solarMapPoint),
                title: 'Your places',
                body: 'Home, Work, saved places and recent addresses',
              ),
              AccountTile(
                mark: AccountIcon.asset(AppAssets.solarWallet),
                title: 'Payments',
                body: 'Saved cards, wallet balance and payment settings',
              ),
              AccountTile(
                mark: AccountIcon.asset(AppAssets.solarClock),
                title: 'Trips and safety',
                body: 'Ride history, reservations and trusted contacts',
                showDivider: false,
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Text(
              'Receipts we must keep by law are kept only as long as '
              'required. Deleting can\'t be undone, and you are signed out '
              'on this device once the request is sent.',
              style: accountText(13, color: kAccountMuted, height: 1.4),
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Text(
                _error!,
                style: accountText(13.5, color: const Color(0xFFB42318)),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _sending
                ? const SizedBox(
                    height: 54,
                    child: Center(child: CircularProgressIndicator()),
                  )
                : AccountFillButton(
                    label: 'Delete my account',
                    onTap: _confirmAndSend,
                  ),
          ),
        ],
      ),
    );
  }

  /// The session is already over: back and Done both lead to Sign in.
  Widget _sentView() {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _done();
      },
      child: Scaffold(
        backgroundColor: kAccountSoft,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 48, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppIconAsset(
                  AppAssets.solarCheckCircle,
                  size: 44,
                  color: kAccountAccent,
                ),
                const SizedBox(height: 18),
                const AccountHeadline(
                  'Your deletion request was sent',
                  body:
                      'Movera will delete your account. You are signed out, '
                      'and your data has been removed from this device.',
                ),
                const Spacer(),
                AccountFillButton(label: 'Done', onTap: _done),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
