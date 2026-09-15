import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movera_rider/features/ride_complete/data/ride_complete_repository.dart';
import 'package:movera_rider/features/ride_complete/presentation/add_tip.dart';
import 'package:movera_rider/shared/design_system/movera_empty_state.dart';

void main() {
  test('tip catalog has no seeded demo amounts', () {
    expect(TipCatalog().amounts(), isEmpty);
  });

  testWidgets('completion shows honest unavailable tipping state', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 844),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (_, __) => const MaterialApp(
          home: Scaffold(body: RideCompletedAddTip()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tip your driver'), findsOneWidget);
    expect(find.byType(MoveraEmptyState), findsOneWidget);
    expect(find.byIcon(Icons.volunteer_activism_outlined), findsOneWidget);
    expect(find.text('Tips unavailable'), findsOneWidget);
    expect(
      find.text("Tipping isn't available in this build."),
      findsOneWidget,
    );

    expect(find.text(r'$1'), findsNothing);
    expect(find.text(r'$2'), findsNothing);
    expect(find.text(r'$5'), findsNothing);
    expect(find.text(r'$3.50'), findsNothing);
    expect(find.text('Add another amount'), findsNothing);
    expect(find.text('SET TIP'), findsNothing);
    expect(find.textContaining('Marle'), findsNothing);
    expect(find.byType(TextButton), findsNothing);
  });
}
