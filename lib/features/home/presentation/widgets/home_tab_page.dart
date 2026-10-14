import 'package:flutter/material.dart';
import 'package:movera_rider/shared/widgets/horizontal_swipe.dart';

/// Bottom-bar order on Home: Home, Payment, Schedule ride, Account.
abstract final class HomeTabs {
  static const int home = 0;
  static const int payment = 1;
  static const int schedule = 2;
  static const int account = 3;
  static const int last = account;

  /// The pages a horizontal swipe moves between: Home, Payment, Account.
  /// Schedule ride is a booking flow rather than a page, so the swipe skips
  /// it (NAV-5).
  static const List<int> swipeOrder = [home, payment, account];

  /// The tab a swipe left (forward) from [tab] opens, or null at the end.
  static int? nextOf(int tab) {
    final i = swipeOrder.indexOf(tab);
    return i < 0 || i + 1 >= swipeOrder.length ? null : swipeOrder[i + 1];
  }

  /// The tab a swipe right (back) from [tab] returns to.
  static int previousOf(int tab) {
    final i = swipeOrder.indexOf(tab);
    return i <= 0 ? home : swipeOrder[i - 1];
  }
}

/// A bottom-bar page pushed over Home. A swipe pops it with the index of
/// the neighbouring page (see [HomeTabs.swipeOrder]) so Home can open that
/// one next.
class HomeTabPage extends StatelessWidget {
  const HomeTabPage({super.key, required this.tab, required this.child});

  final int tab;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final next = HomeTabs.nextOf(tab);
    return HorizontalSwipe(
      onSwipeLeft: next != null ? () => Navigator.of(context).pop(next) : null,
      onSwipeRight: () => Navigator.of(context).pop(HomeTabs.previousOf(tab)),
      child: child,
    );
  }
}
