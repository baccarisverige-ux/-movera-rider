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
    BuildContext? homeContext;
    BuildContext? childContext;

    await tester.pumpWidget(
      MaterialApp(
        navigatorObservers: [observer],
        home: Builder(
          builder: (context) {
            homeContext = context;
            return Scaffold(
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
                              builder: (pageContext) {
                                childContext = pageContext;
                                return TextButton(
                                  onPressed: () => Navigator.pop(pageContext),
                                  child: const Text('Back from child'),
                                );
                              },
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
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(moveraRouteIsSettled(homeContext!), isTrue);

    await tester.tap(find.text('Open child'));
    await tester.pump();
    expect(childContext, isNotNull);
    expect(moveraRouteIsSettled(childContext!), isFalse);

    await tester.pump(const Duration(milliseconds: 120));
    expect(moveraRouteIsSettled(childContext!), isFalse);

    await tester.pump(const Duration(milliseconds: 140));
    expect(moveraRouteIsSettled(childContext!), isTrue);
    expect(find.text('Back from child'), findsOneWidget);

    await tester.tap(find.text('Back from child'));
    await tester.pump();
    expect(moveraNavigationSettled, isFalse);
    expect(moveraRouteIsSettled(homeContext!), isFalse);

    await tester.pump(const Duration(milliseconds: 120));
    expect(moveraRouteIsSettled(homeContext!), isFalse);

    await tester.pump(const Duration(milliseconds: 140));
    expect(moveraNavigationSettled, isTrue);
    expect(moveraRouteIsSettled(homeContext!), isTrue);
    expect(find.text('Open child'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
