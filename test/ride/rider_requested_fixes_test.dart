import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:movera_rider/features/ride_complete/presentation/add_tip.dart';

void main() {
  

  

  testWidgets('custom tip works alongside fixed tip suggestions', (tester) async {
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 844),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (_, __) => const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: RideCompletedAddTip()),
          ),
        ),
      ),
    );

    expect(find.text('10 kr'), findsOneWidget);
    expect(find.text('20 kr'), findsOneWidget);
    expect(find.text('30 kr'), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('custom-tip-field')), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey<String>('custom-tip-field')),
      '45',
    );
    await tester.pump();

    expect(find.text('Custom tip: 45 kr selected.'), findsOneWidget);

    await tester.tap(find.text('20 kr'));
    await tester.pump();

    expect(find.text('20 kr selected.'), findsOneWidget);
    final field = tester.widget<TextField>(
      find.byKey(const ValueKey<String>('custom-tip-field')),
    );
    expect(field.controller?.text, isEmpty);
  });
}
