import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movera_rider/features/home/presentation/side_menu.dart';

/// The Messages menu item was a product ask to remove, not an audit finding.
/// The in-ride "Message driver" entry point (Waiting screen) is unaffected.
void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('the side menu no longer has a Messages row', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final key = GlobalKey<ScaffoldState>();
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (_, __) => MaterialApp(
          home: Scaffold(
            key: key,
            drawer: const RiderSideMenu(),
            body: const Center(child: Text('Home body')),
          ),
        ),
      ),
    );
    key.currentState!.openDrawer();
    await tester.pumpAndSettle();

    expect(find.text('Messages'), findsNothing);
    expect(find.byIcon(Icons.chat_bubble_outline_rounded), findsNothing);

    // The rest of the menu is untouched.
    expect(find.text('Wallet'), findsOneWidget);
    expect(find.text('Ride History'), findsOneWidget);
    expect(find.text('Payments'), findsOneWidget);
    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('Saved Places'), findsOneWidget);
    expect(find.text('Safety'), findsOneWidget);
    expect(find.text('Support'), findsOneWidget);
    expect(find.text('About'), findsOneWidget);
  });
}
