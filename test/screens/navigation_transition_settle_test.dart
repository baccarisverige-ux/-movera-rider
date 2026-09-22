import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movera_rider/app/router/home_history_observer.dart';

void main() {
  testWidgets('navigation settled state covers route entry and exit animations', (
    tester,
  ) async {
    moveraNavigationTransitions.value = 0;
    moveraNavigationEpoch.value = 0;

    final observer = HomeHistoryObserver();

    await tester.pumpWidget(
      MaterialApp(
        navigatorObservers: [observer],
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    PageRouteBuilder<void>(
                      transitionDuration: const Duration(milliseconds: 240),
                      reverseTransitionDuration:
                          const Duration(milliseconds: 240),
                      pageBuilder: (_, __, ___) => Scaffold(
                        body: Center(
                          child: Builder(
                            builder: (pageContext) => TextButton(
                              onPressed: () => Navigator.pop(pageContext),
                              child: const Text('Back from child'),
                            ),
                          ),
                        ),
                      ),
                      transitionsBuilder: (_, animation, __, child) =>
                          FadeTransition(opacity: animation, child: child),
                    ),
                  );
                },
                child: const Text('Open child'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(moveraNavigationSettled, isTrue);

    await tester.tap(find.text('Open child'));
    await tester.pump();
    expect(moveraNavigationSettled, isFalse);

    await tester.pump(const Duration(milliseconds: 120));
    expect(moveraNavigationSettled, isFalse);

    await tester.pump(const Duration(milliseconds: 140));
    expect(moveraNavigationSettled, isTrue);
    expect(find.text('Back from child'), findsOneWidget);

    await tester.tap(find.text('Back from child'));
    await tester.pump();
    expect(moveraNavigationSettled, isFalse);

    await tester.pump(const Duration(milliseconds: 120));
    expect(moveraNavigationSettled, isFalse);

    await tester.pump(const Duration(milliseconds: 140));
    expect(moveraNavigationSettled, isTrue);
    expect(find.text('Open child'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
