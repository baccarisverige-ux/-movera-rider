import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movera_rider/app/router/ride_navigator.dart';
import 'package:movera_rider/features/ride_booking/domain/ride_status.dart';
import 'package:movera_rider/features/ride_complete/application/ride_complete_controller.dart';
import 'package:movera_rider/features/ride_complete/presentation/add_tip.dart';
import 'package:movera_rider/features/ride_complete/presentation/driver_info.dart';
import 'package:movera_rider/features/ride_complete/presentation/give_review.dart';
import 'package:movera_rider/features/ride_complete/presentation/trip_detail.dart';
import 'package:movera_rider/shared/design_system/tokens.dart';

class RideCompleted extends StatefulWidget {
  const RideCompleted({
    super.key,
    this.status = RideStatus.tripCompleted,
  });

  final RideStatus status;

  @override
  State<RideCompleted> createState() => _RideCompletedState();
}

class _RideCompletedState extends State<RideCompleted> {
  final RideCompleteController _controller = RideCompleteController();
  bool _leaving = false;

  Future<void> _closeAndHome() async {
    if (_leaving || !mounted) return;
    _leaving = true;
    _controller.close();
    RideNavigator.home(context, status: RideStatus.closed);
  }

  _CompletionSpec get _spec => _CompletionSpec.fromStatus(widget.status);

  @override
  Widget build(BuildContext context) {
    final spec = _spec;
    final canRate = widget.status == RideStatus.ratingPending;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _closeAndHome();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F5F1),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                child: Row(
                  children: [
                    _CircleAction(
                      icon: Icons.arrow_back_ios_new_rounded,
                      label: 'Back',
                      onTap: _closeAndHome,
                    ),
                    Expanded(
                      child: Text(
                        'Trip complete',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: MoveraTokens.ink,
                        ),
                      ),
                    ),
                    const SizedBox(width: 46),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                  child: Column(
                    children: [
                      _CompletionHero(spec: spec),
                      const SizedBox(height: 14),
                      _SurfaceCard(
                        child: const RideCompletedDriverInfo(),
                      ),
                      const SizedBox(height: 14),
                      _SurfaceCard(
                        child: const RideCompletedTripDetail(),
                      ),
                      if (canRate) ...[
                        const SizedBox(height: 14),
                        const _SurfaceCard(
                          child: RideCompletedGiveReview(),
                        ),
                        const SizedBox(height: 14),
                        const _SurfaceCard(
                          child: RideCompletedAddTip(),
                        ),
                      ],
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        height: MoveraTokens.buttonHeight,
                        child: FilledButton(
                          onPressed: _leaving ? null : _closeAndHome,
                          style: FilledButton.styleFrom(
                            backgroundColor: MoveraTokens.cta,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: Text(
                            'Done',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompletionHero extends StatelessWidget {
  const _CompletionHero({required this.spec});

  final _CompletionSpec spec;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: MoveraTokens.line),
        boxShadow: [
          BoxShadow(
            color: MoveraTokens.ink.withValues(alpha: 0.05),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F7),
              borderRadius: BorderRadius.circular(20),
            ),
            alignment: Alignment.center,
            child: Icon(
              spec.icon,
              size: 29,
              color: MoveraTokens.accent,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            spec.title,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 23,
              fontWeight: FontWeight.w700,
              color: MoveraTokens.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            spec.message,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: MoveraTokens.muted,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFB),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(
                  spec.statusIcon,
                  size: 18,
                  color: MoveraTokens.accent,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    spec.statusLabel,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: MoveraTokens.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: MoveraTokens.line),
      ),
      child: child,
    );
  }
}

class _CircleAction extends StatelessWidget {
  const _CircleAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: Colors.white,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: MoveraTokens.line),
            ),
            alignment: Alignment.center,
            child: Icon(
              icon,
              size: 18,
              color: MoveraTokens.ink,
            ),
          ),
        ),
      ),
    );
  }
}

class _CompletionSpec {
  const _CompletionSpec({
    required this.title,
    required this.message,
    required this.statusLabel,
    required this.icon,
    required this.statusIcon,
  });

  final String title;
  final String message;
  final String statusLabel;
  final IconData icon;
  final IconData statusIcon;

  factory _CompletionSpec.fromStatus(RideStatus status) {
    switch (status) {
      case RideStatus.paymentProcessing:
        return const _CompletionSpec(
          title: 'Ride finished',
          message:
              'Your trip is complete. Payment confirmation is still processing.',
          statusLabel: 'Payment processing',
          icon: Icons.route_rounded,
          statusIcon: Icons.hourglass_top_rounded,
        );
      case RideStatus.paymentFinalized:
        return const _CompletionSpec(
          title: 'All set',
          message:
              'Your trip is complete and the payment has been confirmed.',
          statusLabel: 'Payment confirmed',
          icon: Icons.check_rounded,
          statusIcon: Icons.verified_rounded,
        );
      case RideStatus.ratingPending:
        return const _CompletionSpec(
          title: 'How was your ride?',
          message:
              'Your trip and payment are complete. You can now rate your driver.',
          statusLabel: 'Ready for feedback',
          icon: Icons.star_outline_rounded,
          statusIcon: Icons.rate_review_outlined,
        );
      case RideStatus.tripCompleted:
      default:
        return const _CompletionSpec(
          title: 'You have arrived',
          message:
              'Your ride has ended. Payment status will update when it is confirmed.',
          statusLabel: 'Trip completed',
          icon: Icons.flag_rounded,
          statusIcon: Icons.check_circle_outline_rounded,
        );
    }
  }
}
