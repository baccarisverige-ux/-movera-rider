import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movera_rider/features/ride_complete/application/ride_complete_controller.dart';
import 'package:movera_rider/features/ride_complete/data/ride_complete_repository.dart';
import 'package:movera_rider/features/ride_complete/presentation/add_tip.dart';
import 'package:movera_rider/shared/design_system/movera_empty_state.dart';

/// Tipping is offered in SEK. The removed demo tipping UI — dollar amounts,
/// "Add another amount", "SET TIP", a driver called Marle — must stay gone,
/// and an empty catalog must still degrade to the honest state rather than
/// invent an amount.
void main() {
  Future<void> pump(WidgetTester tester, Widget child) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 844),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (_, __) => MaterialApp(home: Scaffold(body: child)),
      ),
    );
    await tester.pumpAndSettle();
  }

  test('tip amounts are SEK and carry no demo values', () {
    final amounts = const TipCatalog().amounts();
    expect(amounts, isNotEmpty);
    for (final amount in amounts) {
      expect(amount, contains('kr'));
      expect(amount, isNot(contains(r'$')));
    }
  });

  testWidgets('tips render as selectable SEK amounts', (tester) async {
    await pump(tester, const RideCompletedAddTip());

    expect(find.text('Tip your driver'), findsOneWidget);
    expect(find.byType(MoveraEmptyState), findsNothing);
    for (final amount in TipCatalog.defaults) {
      expect(find.text(amount), findsOneWidget);
    }

    await tester.tap(find.text(TipCatalog.defaults.first));
    await tester.pumpAndSettle();
    expect(
      find.text('${TipCatalog.defaults.first} added for your driver.'),
      findsOneWidget,
    );
  });

  testWidgets('an empty catalog still shows the honest state', (tester) async {
    await pump(
      tester,
      RideCompletedAddTip(
        controller: RideCompleteController(
          tips: const TipCatalog(amounts: []),
        ),
      ),
    );

    expect(find.byType(MoveraEmptyState), findsOneWidget);
    expect(find.text('Tips unavailable'), findsOneWidget);
    expect(
      find.text("Tipping isn't available in this build."),
      findsOneWidget,
    );
  });

  testWidgets('the removed demo tipping UI stays gone', (tester) async {
    await pump(tester, const RideCompletedAddTip());

    expect(find.text(r'$1'), findsNothing);
    expect(find.text(r'$2'), findsNothing);
    expect(find.text(r'$5'), findsNothing);
    expect(find.text(r'$3.50'), findsNothing);
    expect(find.text('Add another amount'), findsNothing);
    expect(find.text('SET TIP'), findsNothing);
    expect(find.textContaining('Marle'), findsNothing);
  });
}
