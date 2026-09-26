import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movera_rider/app/config/env.dart';
import 'package:movera_rider/core/api/api_client.dart';
import 'package:movera_rider/core/api/in_process_mock_client.dart';
import 'package:movera_rider/features/profile/application/account_security_controller.dart';
import 'package:movera_rider/features/profile/application/profile_controller.dart';
import 'package:movera_rider/features/profile/data/account_security_repository.dart';
import 'package:movera_rider/features/profile/data/profile_repository.dart';
import 'package:movera_rider/features/profile/presentation/account_checkup.dart';
import 'package:movera_rider/features/profile/presentation/personal_info.dart';
import 'package:movera_rider/features/profile/presentation/security.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  const env = AppEnv(
    flavor: AppFlavor.test,
    apiBaseUrl: 'https://api.test.movera.invalid',
    mapsEnabled: true,
  );

  Future<AccountSecurityController> securityController() async {
    final controller = AccountSecurityController(
      repository: AccountSecurityRepository(
        api: ApiClient(
          env: env,
          client: InProcessMockClient(),
        ),
      ),
    );
    await controller.load();
    return controller;
  }

  Future<ProfileController> profileController() async {
    final controller = ProfileController(
      store: ProfileRepository(storageKey: 'phase74_ui_profile'),
    );
    await controller.hydrate();
    return controller;
  }

  Future<void> pump(WidgetTester tester, Widget child) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(home: child));
    await tester.pumpAndSettle();
  }

  testWidgets('unsupported security controls are read-only and truthful',
      (tester) async {
    final security = await securityController();
    await pump(
      tester,
      SecurityPage(securityController: security),
    );

    expect(
      find.text('Unavailable until secure account service is connected'),
      findsAtLeastNWidgets(5),
    );
    expect(find.byType(Switch), findsNothing);
    expect(find.text('Connect'), findsNothing);
    expect(find.text('Disconnect'), findsNothing);
  });

  testWidgets('Account Check uses server verification metadata', (tester) async {
    final security = await securityController();
    final profile = await profileController();
    await pump(
      tester,
      AccountCheckupPage(
        controller: profile,
        securityController: security,
      ),
    );

    expect(
      find.text('+46701234567 · Not verified'),
      findsOneWidget,
    );
    expect(find.text('Unavailable'), findsAtLeastNWidgets(2));
  });

  testWidgets('Personal Info cannot locally edit phone or email',
      (tester) async {
    final security = await securityController();
    final profile = await profileController();
    await pump(
      tester,
      PersonalInfoPage(
        controller: profile,
        securityController: security,
      ),
    );

    expect(find.text('+46701234567 · Not verified'), findsOneWidget);
    expect(find.text('rider@example.test · Verified'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);

    await tester.tap(find.text('Phone'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNothing);

    await tester.tap(find.text('Email'));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('server revocation removes other sessions from Security',
      (tester) async {
    final security = await securityController();
    await pump(
      tester,
      SecurityPage(securityController: security),
    );

    expect(find.text('Other device'), findsOneWidget);
    await tester.tap(find.text('Sign out other devices'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign out others'));
    await tester.pumpAndSettle();

    expect(find.text('Other device'), findsNothing);
    expect(
      security.state!.sessions.every((session) => session.current),
      isTrue,
    );
  });
}
