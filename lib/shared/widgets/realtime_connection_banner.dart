import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movera_rider/core/realtime/realtime_connection.dart';

/// Compact transport-status surface for ride-critical screens.
///
/// It never changes ride state and offers no fake retry outcome. It only
/// reflects the shared realtime connection source so the future backend can
/// drive the same UI without changing presentation code.
class RealtimeConnectionBanner extends StatelessWidget {
  const RealtimeConnectionBanner({
    super.key,
    required this.connection,
  });

  final RealtimeConnection connection;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<RealtimeState>(
      stream: connection.states,
      initialData: connection.state,
      builder: (context, snapshot) {
        final state = snapshot.data ?? connection.state;
        final spec = _spec(state);

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: spec == null
              ? const SizedBox.shrink(key: ValueKey('realtime-connected'))
              : Semantics(
                  key: ValueKey('realtime-${state.name}'),
                  liveRegion: true,
                  label: spec.semantics,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xF71D252C),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x1F162C36),
                          blurRadius: 18,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 11,
                      ),
                      child: Row(
                        children: [
                          Icon(spec.icon, size: 18, color: Colors.white),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  spec.title,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  spec.subtitle,
                                  style: GoogleFonts.poppins(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                    color: const Color(0xFFD9E0E4),
                                    height: 1.25,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (state == RealtimeState.connecting ||
                              state == RealtimeState.reconnecting) ...[
                            const SizedBox(width: 10),
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
        );
      },
    );
  }

  _ConnectionSpec? _spec(RealtimeState state) {
    switch (state) {
      case RealtimeState.connected:
        return null;
      case RealtimeState.connecting:
        return const _ConnectionSpec(
          icon: Icons.sync_rounded,
          title: 'Connecting',
          subtitle: 'Restoring the live ride connection.',
          semantics: 'Connecting. Restoring the live ride connection.',
        );
      case RealtimeState.reconnecting:
        return const _ConnectionSpec(
          icon: Icons.sync_rounded,
          title: 'Reconnecting',
          subtitle: 'Ride details stay on screen while connection returns.',
          semantics:
              'Reconnecting. Ride details stay on screen while connection returns.',
        );
      case RealtimeState.disconnected:
        return const _ConnectionSpec(
          icon: Icons.wifi_off_rounded,
          title: 'Connection lost',
          subtitle: 'Live ride updates are temporarily unavailable.',
          semantics:
              'Connection lost. Live ride updates are temporarily unavailable.',
        );
      case RealtimeState.failed:
        return const _ConnectionSpec(
          icon: Icons.cloud_off_outlined,
          title: 'Connection problem',
          subtitle: 'Live ride updates could not be restored yet.',
          semantics:
              'Connection problem. Live ride updates could not be restored yet.',
        );
    }
  }
}

class _ConnectionSpec {
  const _ConnectionSpec({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.semantics,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String semantics;
}
