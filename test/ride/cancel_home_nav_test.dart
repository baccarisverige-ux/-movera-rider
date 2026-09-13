import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movera_rider/app/navigator_key.dart';
import 'package:movera_rider/app/router/ride_navigator.dart';

void main() {
  testWidgets('cancel can pop a locked searching route back to Home', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: moveraNavigatorKey,
        home: const Scaffold(body: Text('home-root')),
      ),
    );

    final nav = moveraNavigatorKey.currentState!;
    nav.push(
      MaterialPageRoute<void>(
        builder: (context) {
          return _LockedSearch(onLeave: () => RideNavigator.home(context));
        },
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('searching'), findsOneWidget);

    await tester.tap(find.text('Cancel ride'));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('home-root'), findsOneWidget);
    expect(find.text('searching'), findsNothing);
  });

  testWidgets('cancel removes searching even when PopScope blocks pop', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: moveraNavigatorKey,
        home: const Scaffold(body: Text('home-root')),
      ),
    );
    moveraNavigatorKey.currentState!.push(
      MaterialPageRoute<void>(
        builder: (context) {
          return PopScope(
            canPop: false,
            child: Scaffold(
              body: Column(
                children: [
                  const Text('searching'),
                  TextButton(
                    onPressed: () => RideNavigator.home(context),
                    child: const Text('Cancel ride'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('searching'), findsOneWidget);
    await tester.tap(find.text('Cancel ride'));
    await tester.pumpAndSettle();
    expect(find.text('searching'), findsNothing);
    expect(find.text('home-root'), findsOneWidget);
  });
}

class _LockedSearch extends StatefulWidget {
  const _LockedSearch({required this.onLeave});

  final VoidCallback onLeave;

  @override
  State<_LockedSearch> createState() => _LockedSearchState();
}

class _LockedSearchState extends State<_LockedSearch> {
  bool _leaving = false;

  Future<void> _cancel() async {
    setState(() => _leaving = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onLeave();
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _leaving,
      child: Scaffold(
        body: Column(
          children: [
            const Text('searching'),
            TextButton(onPressed: _cancel, child: const Text('Cancel ride')),
          ],
        ),
      ),
    );
  }
}
