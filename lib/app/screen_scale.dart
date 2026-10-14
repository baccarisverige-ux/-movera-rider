import 'package:flutter/widgets.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// The design the layouts were drawn on (iPhone X/11 Pro width and height).
const Size moveraDesignSize = Size(375, 812);

/// Bounds for the ScreenUtil scale factors (UI-9). Without them widths grew
/// 3.4x on a 1280x800 desktop window and heights ignored screens shorter than
/// 700 px (`splitScreenMode`).
const double moveraMinScale = 0.85;
const double moveraMaxScale = 1.25;

double _bounded(double screen, double design) {
  if (screen <= 0) return design;
  final factor = screen / design;
  if (factor < moveraMinScale) return screen / moveraMinScale;
  if (factor > moveraMaxScale) return screen / moveraMaxScale;
  // Inside the bounds keep the real design value, so phones between the
  // bounds (the 390x844 reference included) scale exactly as before.
  return design;
}

/// The design size handed to ScreenUtil for a [screen], chosen so that
/// `scaleWidth` and `scaleHeight` stay inside [moveraMinScale] and
/// [moveraMaxScale] on every axis.
Size moveraDesignSizeFor(Size screen) => Size(
  _bounded(screen.width, moveraDesignSize.width),
  _bounded(screen.height, moveraDesignSize.height),
);

/// The app's one ScreenUtil setup. Tests pump through this too, so they see
/// the same scaling as production.
class MoveraScreenUtilInit extends StatelessWidget {
  const MoveraScreenUtilInit({
    super.key,
    required this.builder,
    this.ensureScreenSize = true,
  });

  final ScreenUtilInitBuilder builder;
  final bool ensureScreenSize;

  @override
  Widget build(BuildContext context) {
    // The root View provides this MediaQuery, so a window resize rebuilds
    // ScreenUtil with new bounds.
    final screen = MediaQuery.maybeSizeOf(context) ?? moveraDesignSize;
    return ScreenUtilInit(
      designSize: moveraDesignSizeFor(screen),
      minTextAdapt: true,
      ensureScreenSize: ensureScreenSize,
      builder: builder,
    );
  }
}
