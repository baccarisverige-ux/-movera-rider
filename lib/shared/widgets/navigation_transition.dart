import 'package:flutter/material.dart';
import 'package:movera_rider/shared/design_system/motion/movera_motion.dart';

class BottomToTopTransition<T> extends PageRouteBuilder<T> {
  BottomToTopTransition(Widget page)
      : super(
          pageBuilder: (context, animation, secondary) => page,
          transitionDuration: MoveraDurations.large,
          reverseTransitionDuration: MoveraDurations.normal,
          transitionsBuilder: (context, animation, secondary, child) {
            return _sheetCover(context, animation, child);
          },
        );
}

class TopToBottomTransition<T> extends PageRouteBuilder<T> {
  TopToBottomTransition(Widget page)
      : super(
          pageBuilder: (context, animation, secondary) => page,
          transitionDuration: MoveraDurations.large,
          reverseTransitionDuration: MoveraDurations.normal,
          transitionsBuilder: (context, animation, secondary, child) {
            if (MoveraMotion.reduced(context)) return child;
            final curved = CurvedAnimation(
              parent: animation,
              curve: MoveraCurves.open,
              reverseCurve: MoveraCurves.close,
            );
            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, -0.06),
                  end: Offset.zero,
                ).animate(curved),
                child: child,
              ),
            );
          },
        );
}

/// Full-screen ride lifecycle stages use a deliberately quiet transition.
///
/// Map-heavy ride pages must not slide over one another for hundreds of
/// milliseconds: on web/PWA that briefly keeps two platform maps alive and can
/// look like a crash. Forward navigation gets a short fade; unwinding the ride
/// stack back to Home is instantaneous so intermediate stages never flash.
class RideStageTransition<T> extends PageRouteBuilder<T> {
  RideStageTransition(Widget page)
      : super(
          pageBuilder: (context, animation, secondary) => page,
          transitionDuration: const Duration(milliseconds: 120),
          reverseTransitionDuration: Duration.zero,
          transitionsBuilder: (context, animation, secondary, child) {
            if (MoveraMotion.reduced(context)) return child;
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            );
            final veil = Tween<double>(
              begin: 0.12,
              end: 0,
            ).animate(curved);
            // Never fade the incoming ride stage itself. Fading the whole
            // child exposes the previous stage underneath for a few frames,
            // which is especially visible after that stage has already parked
            // its map. Keep an opaque neutral surface behind the new stage and
            // fade only a very light veil over the new screen.
            return Stack(
              fit: StackFit.expand,
              children: [
                const ColoredBox(color: Color(0xFFF6F5F1)),
                child,
                IgnorePointer(
                  child: FadeTransition(
                    opacity: veil,
                    child: const ColoredBox(color: Color(0xFFF6F5F1)),
                  ),
                ),
              ],
            );
          },
        );
}

class SwitchTransition<T> extends PageRouteBuilder<T> {
  SwitchTransition(Widget page)
      : super(
          pageBuilder: (context, animation, secondary) => page,
          transitionDuration: MoveraDurations.normal,
          reverseTransitionDuration: MoveraDurations.micro,
          transitionsBuilder: (context, animation, secondary, child) {
            if (MoveraMotion.reduced(context)) return child;
            final curved = CurvedAnimation(
              parent: animation,
              curve: MoveraCurves.open,
              reverseCurve: MoveraCurves.close,
            );
            return FadeTransition(opacity: curved, child: child);
          },
        );
}

class LeftToRightTransition<T> extends PageRouteBuilder<T> {
  LeftToRightTransition(Widget page)
      : super(
          pageBuilder: (context, animation, secondary) => page,
          transitionDuration: MoveraDurations.normal,
          reverseTransitionDuration: MoveraDurations.micro,
          transitionsBuilder: (context, animation, secondary, child) {
            return _sideCover(context, animation, child, const Offset(-0.06, 0));
          },
        );
}

class RightToLeftTransition<T> extends PageRouteBuilder<T> {
  RightToLeftTransition(Widget page)
      : super(
          pageBuilder: (context, animation, secondary) => page,
          transitionDuration: MoveraDurations.normal,
          reverseTransitionDuration: MoveraDurations.micro,
          transitionsBuilder: (context, animation, secondary, child) {
            return _sideCover(context, animation, child, const Offset(0.06, 0));
          },
        );
}

Widget _sheetCover(BuildContext context, Animation<double> animation, Widget child) {
  if (MoveraMotion.reduced(context)) return child;
  final curved = CurvedAnimation(
    parent: animation,
    curve: MoveraCurves.open,
    reverseCurve: MoveraCurves.close,
  );
  return FadeTransition(
    opacity: curved,
    child: SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.08),
        end: Offset.zero,
      ).animate(curved),
      child: child,
    ),
  );
}

Widget _sideCover(
  BuildContext context,
  Animation<double> animation,
  Widget child,
  Offset begin,
) {
  if (MoveraMotion.reduced(context)) return child;
  final curved = CurvedAnimation(
    parent: animation,
    curve: MoveraCurves.open,
    reverseCurve: MoveraCurves.close,
  );
  return FadeTransition(
    opacity: curved,
    child: SlideTransition(
      position: Tween<Offset>(begin: begin, end: Offset.zero).animate(curved),
      child: child,
    ),
  );
}
