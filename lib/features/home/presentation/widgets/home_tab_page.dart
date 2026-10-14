import 'package:flutter/material.dart';
import 'package:movera_rider/shared/widgets/horizontal_swipe.dart';

/// Bottom-bar order on Home: Home, Payment, Schedule ride, Account.
abstract final class HomeTabs {
  static const int home = 0;
  static const int payment = 1;
  static const int schedule = 2;
  static const int account = 3;
  static const int last = account;
}

/// A bottom-bar page pushed over Home. A swipe pops it with the index of
/// the neighbouring tab so Home can open that one next.
class HomeTabPage extends StatelessWidget {
  const HomeTabPage({super.key, required this.tab, required this.child});

  final int tab;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return HorizontalSwipe(
      onSwipeLeft: tab < HomeTabs.last
          ? () => Navigator.of(context).pop(tab + 1)
          : null,
      onSwipeRight: () => Navigator.of(context).pop(tab - 1),
      child: child,
    );
  }
}
