import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movera_rider/features/profile/application/profile_controller.dart';
import 'package:movera_rider/features/profile/data/profile_repository.dart';
import 'package:movera_rider/features/profile/presentation/account_home.dart';
import 'package:movera_rider/features/profile/presentation/personal_info.dart';
import 'package:movera_rider/features/profile/presentation/privacy.dart';
import 'package:movera_rider/features/profile/presentation/security.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  ProfileController controller() {
    return ProfileController(
      store: ProfileRepository(storageKey: 'test_profile'),
    );
  }

  Future<void> pumpPhone(WidgetTester tester, Widget home) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(home: home));
  }

  testWidgets('account hub is Movera not Uber', (tester) async {
    await pumpPhone(tester, AccountHomePage(controller: controller()));
    expect(find.text('Movera account'), findsOneWidget);
    expect(find.text('Personal info'), findsOneWidget);
    expect(find.text('Security'), findsOneWidget);
    expect(find.text('Privacy'), findsOneWidget);
    expect(find.text('Ben Gleason'), findsOneWidget);
    expect(find.textContaining('Uber'), findsNothing);
  });

  testWidgets('personal info edits name', (tester) async {
    final c = controller();
    await pumpPhone(tester, PersonalInfoPage(controller: c));
    expect(find.text('Name'), findsOneWidget);
    expect(find.text('Phone'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    await tester.tap(find.text('Name'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Houssem Baccari');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(c.profile.name, 'Houssem Baccari');
  });

  testWidgets('security toggles 2-step', (tester) async {
    final c = controller();
    await pumpPhone(tester, SecurityPage(controller: c));
    expect(find.text('Passkeys'), findsOneWidget);
    expect(find.text('2-step verification'), findsOneWidget);
    expect(c.profile.twoStepEnabled, isFalse);
    await tester.tap(find.byType(Switch).first);
    await tester.pump();
    expect(c.profile.twoStepEnabled, isTrue);
    expect(find.textContaining('Uber'), findsNothing);
  });

  testWidgets('privacy communication toggles persist', (tester) async {
    final c = controller();
    await pumpPhone(tester, PrivacyPage(controller: c));
    expect(find.text('Ride updates'), findsOneWidget);
    expect(find.text('Offers'), findsOneWidget);
    expect(c.profile.promotions, isFalse);
    await tester.tap(find.byType(Switch).last);
    await tester.pump();
    expect(c.profile.promotions, isTrue);
  });
}
