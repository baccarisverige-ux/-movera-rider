import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movera_rider/features/saved_places/application/saved_places_controller.dart';
import 'package:movera_rider/features/saved_places/data/saved_places_repository.dart';
import 'package:movera_rider/features/saved_places/domain/saved_place.dart';
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

  Future<void> pumpPickup(
    WidgetTester tester, {
    SavedPlacesController? places,
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 844),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (_, __) => MaterialApp(
          home: RiderSearchPickupLocation(places: places),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('pickup search shows honest empty states instead of demo trips',
      (tester) async {
    await pumpPickup(tester);

    expect(find.text('Your last trip'), findsOneWidget);
    expect(find.text('No recent trips yet'), findsOneWidget);
    expect(
      find.text(
        'Completed trips will appear here when real ride history is available.',
      ),
      findsOneWidget,
    );
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Work'), findsOneWidget);
    expect(find.text('Not saved yet'), findsNWidgets(2));
    expect(find.text('Search results'), findsOneWidget);
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

  testWidgets('empty Home shortcut opens the existing save-location flow',
      (tester) async {
    await pumpPickup(tester);
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(find.text('Add new address'), findsOneWidget);
    expect(find.text('Add location'), findsOneWidget);
  });

  testWidgets('saved Home shortcut keeps selection instead of opening save flow',
      (tester) async {
    String? selected;
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 844),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (_, __) => MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: TextButton(
                  onPressed: () async {
                    selected = await Navigator.push<String>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RiderSearchPickupLocation(
                          places: SavedPlacesController(
                            store: SavedPlacesRepository(
                              shortcuts: const [
                                PlaceShortcut(
                                  title: 'Home',
                                  subtitle: 'Klockarvägen 37',
                                  kind: 'home',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  child: const Text('Open pickup'),
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open pickup'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(selected, 'Klockarvägen 37');
    expect(find.text('Add new address'), findsNothing);
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
    expect(find.text('Close'), findsOneWidget);
    expect(find.byIcon(Icons.location_searching_outlined), findsOneWidget);

    expect(find.textContaining('Islamabad'), findsNothing);
    expect(find.textContaining('Tashkent'), findsNothing);
    expect(find.textContaining('Ludwig Passage'), findsNothing);
  });
}
