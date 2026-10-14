import 'package:flutter/material.dart';
import 'package:movera_rider/shared/widgets/responsive_size.dart';

/// UI-2: the expanded Home sheet holds more than a short phone (or large
/// text) can show. Its content scrolls inside the sheet instead of being cut
/// off under the bottom navigation; where everything fits there is nothing to
/// scroll, so the reference layout is unchanged.
///
/// It uses the sheet's [PrimaryScrollController], so a drag first moves the
/// sheet to the top stop, then scrolls, and a drag down at the top of the
/// content moves the sheet down again.
class HomeSheetScroll extends StatelessWidget {
  const HomeSheetScroll({super.key, required this.child});

  /// Space the floating bottom navigation covers at the full stop, less the
  /// content's own bottom padding.
  static double get navClearance => ResSize.h * 56;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      primary: true,
      physics: const ClampingScrollPhysics(),
      padding: EdgeInsets.only(bottom: navClearance),
      child: child,
    );
  }
}
