import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movera_rider/features/saved_places/data/saved_places_repository.dart';
import 'package:movera_rider/features/saved_places/presentation/confirm_location.dart';
import 'package:movera_rider/features/saved_places/presentation/pickup_location.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  test('saved places keep add actions without seeded location shortcuts', () {
    final repository = SavedPlacesRepository();

    expect(
      repository.options().map((option) => option.title),
      orderedEquals(['Add Home', 'Add Work', 'Add School', 'Add Gym']),
    );
    expect(repository.shortcuts(), isEmpty);
  });

  testWidgets('pickup search shows honest empty states instead of demo trips',
      (tester) async {
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
          home: RiderSearchPickupLocation(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Your Last Trip'), findsOneWidget);
    expect(find.text('No recent trips yet'), findsOneWidget);
    expect(
      find.text(
        'Completed trips will appear here when real ride history is available.',
      ),
      findsOneWidget,
    );
    expect(find.text('Search Result'), findsOneWidget);
    expect(find.text('No search results'), findsOneWidget);
    expect(
      find.text('Place search isn’t connected in this build yet.'),
      findsOneWidget,
    );

    expect(find.text('30 Main Street'), findsNothing);
    expect(find.text('5.9km|30 Main Street, London'), findsNothing);
    expect(find.textContaining('Dubai'), findsNothing);
    expect(find.textContaining('Sharjah'), findsNothing);
  });

  testWidgets('pickup confirmation contains no seeded address suggestions',
      (tester) async {
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
          home: Scaffold(
            body: PickupLocationBottomSheet(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Pickup location'), findsOneWidget);
    expect(find.text('Location unavailable'), findsOneWidget);
    expect(find.text('No location suggestions'), findsOneWidget);
    expect(
      find.text('Location suggestions aren’t connected in this build yet.'),
      findsOneWidget,
    );

    expect(find.textContaining('Islamabad'), findsNothing);
    expect(find.textContaining('Tashkent'), findsNothing);
    expect(find.textContaining('Ludwig Passage'), findsNothing);
  });
}
