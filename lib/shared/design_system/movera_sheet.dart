import 'package:flutter/material.dart';
import 'package:movera_rider/shared/design_system/motion/movera_motion.dart';
import 'package:movera_rider/shared/design_system/tokens.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:smooth_sheets/smooth_sheets.dart';

class MoveraSheet extends StatelessWidget {
  const MoveraSheet({
    super.key,
    required this.child,
    this.showHandle = true,
    this.color = Colors.white,
  });

  final Widget child;
  final bool showHandle;
  final Color color;

  static Future<T?> show<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool swipeDismissible = true,
    bool barrierDismissible = true,
    Color barrierColor = const Color(0x46000000),
    Color backgroundColor = Colors.white,
  }) async {
    final motion = MoveraSheetMotion.of(context);
    final route = MoveraModalSheetRoute<T>(
      barrierDismissible: barrierDismissible,
      swipeDismissible: swipeDismissible,
      barrierColor: barrierColor,
      openDuration: motion.forward,
      closeDuration: motion.reverse,
      openCurve: motion.forwardCurve,
      builder: (ctx) {
        final keyboardInset = MediaQuery.viewInsetsOf(ctx).bottom;
        return Sheet(
          physics: MoveraSheetMotion.physics,
          scrollConfiguration: const SheetScrollConfiguration(),
          decoration: MoveraSheetMotion.decoration(color: backgroundColor),
          child: Padding(
            padding: EdgeInsets.only(bottom: keyboardInset),
            child: PointerInterceptor(child: builder(ctx)),
          ),
        );
      },
    );
    final result = await Navigator.of(
      context,
      rootNavigator: true,
    ).push<T>(route);
    await route.completed;
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(MoveraTokens.radiusSheet),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showHandle) ...[
            const SizedBox(height: 10),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: MoveraTokens.line,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ],
          child,
        ],
      ),
    );
  }
}

/// Owns [ChangeNotifier]s for the life of a pushed [MoveraSheet] route.
///
/// [MoveraSheet.show] now resolves only after the route fully unmounts.
/// Keeping field-owned notifiers here still guarantees their lifetime matches
/// the modal route itself, including interrupted/gesture dismissals.
class MoveraSheetDisposables extends StatefulWidget {
  const MoveraSheetDisposables({
    super.key,
    required this.disposables,
    required this.child,
  });

  final List<ChangeNotifier> disposables;
  final Widget child;

  @override
  State<MoveraSheetDisposables> createState() => _MoveraSheetDisposablesState();
}

class _MoveraSheetDisposablesState extends State<MoveraSheetDisposables> {
  @override
  void dispose() {
    for (final item in widget.disposables) {
      item.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
