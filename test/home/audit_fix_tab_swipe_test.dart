import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movera_rider/features/home/presentation/widgets/home_tab_page.dart';

/// NAV-5: the bottom-bar swipe moves Home <-> Payment <-> Account. Schedule
/// ride is a booking flow, not a page, so a swipe never lands on it (it was a
/// dead end the rider could not swipe out of, and Account was unreachable).
void main() {
  Future<int?> swipe(WidgetTester tester, int tab, Offset by) async {
    int? result;
    var done = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () async {
                  result = await Navigator.of(context).push<int>(
                    MaterialPageRoute(
                      builder: (_) => HomeTabPage(
                        tab: tab,
                        child: const Scaffold(body: SizedBox.expand()),
                      ),
                    ),
                  );
                  done = true;
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.flingFrom(const Offset(200, 300), by, 1000);
    await tester.pumpAndSettle();
    expect(done, isTrue, reason: 'the swipe should leave the tab page');
    return result;
  }

  const left = Offset(-200, 0);
  const right = Offset(200, 0);

  testWidgets('swipe left from Payment opens Account, not Schedule', (
    tester,
  ) async {
    expect(await swipe(tester, HomeTabs.payment, left), HomeTabs.account);
  });

  testWidgets('swipe right from Account goes back to Payment', (tester) async {
    expect(await swipe(tester, HomeTabs.account, right), HomeTabs.payment);
  });

  testWidgets('swipe right from Payment goes back to Home', (tester) async {
    expect(await swipe(tester, HomeTabs.payment, right), HomeTabs.home);
  });
}
