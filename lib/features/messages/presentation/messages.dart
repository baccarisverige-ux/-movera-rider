import 'package:flutter/material.dart';
import 'package:movera_rider/shared/design_system/movera_empty_state.dart';

/// Rider message inbox.
///
/// Until the real backend/message transport is connected, this surface stays
/// intentionally empty rather than inventing previous conversations. Active
/// trip chat is still opened from the matched-driver card.
class MessagesInbox extends StatelessWidget {
  const MessagesInbox({super.key});

  static const _ink = Color(0xFF1D252C);
  static const _muted = Color(0xFF5C656C);
  static const _line = Color(0xFFE7EBEE);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 10),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded, color: _ink),
                    tooltip: 'Back',
                  ),
                  const Expanded(
                    child: Text(
                      'Messages',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _ink,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.25,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            const Divider(height: 1, color: _line),
            const Expanded(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: MoveraEmptyState(
                    icon: Icons.chat_bubble_outline_rounded,
                    title: 'No conversations yet',
                    message:
                        'Messages with your driver will appear here when a ride is connected. Active-trip chat stays available from your ride screen.',
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 0, 24, 22),
              child: Text(
                'Trip messages will use the same conversation when Movera messaging is connected.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _muted,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

export 'package:movera_rider/features/messages/presentation/chat.dart';
