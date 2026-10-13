import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movera_rider/features/home/presentation/widgets/saved_places_row.dart';

void main() {
  testWidgets('unset Home / Work ask to be set and long-press edits', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    String? tapped;
    String? edited;
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (_, __) => MaterialApp(
          home: Scaffold(
            body: SavedPlacesRow(
              homeAddress: 'Klockarvägen 37',
              workAddress: null,
              savedPlaces: const [],
              onUseSavedPlace: (address, {required target, customType}) =>
                  tapped = '$target:$address',
              onEditSavedPlace: (target, {customType}) => edited = target,
              onAddPlace: () {},
            ),
          ),
        ),
      ),
    );
    expect(find.text('Set Work'), findsOneWidget);
    expect(find.text('Klockarvägen 37'), findsOneWidget);
    await tester.tap(find.text('Set Work'));
    expect(tapped, 'work:null');
    await tester.longPress(find.text('Home'));
    expect(edited, 'home');
  });
}
