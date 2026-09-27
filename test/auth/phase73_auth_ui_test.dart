import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movera_rider/app/config/env.dart';
import 'package:movera_rider/core/api/api_client.dart';
import 'package:movera_rider/core/api/in_process_mock_client.dart';
import 'package:movera_rider/core/auth/token_store.dart';
import 'package:movera_rider/features/auth/application/auth_controller.dart';
import 'package:movera_rider/features/auth/data/auth_repository.dart';
import 'package:movera_rider/features/auth/presentation/phone_verify.dart';
import 'package:movera_rider/features/auth/presentation/sign_in.dart';
import 'package:movera_rider/features/auth/presentation/create_acc.dart';
import 'package:movera_rider/features/auth/presentation/sign_in_phone.dart';
import 'package:movera_rider/features/home/presentation/home.dart';
import 'package:movera_rider/shared/widgets/checkbox.dart';
import 'package:pinput/pinput.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  const env = AppEnv(
    flavor: AppFlavor.test,
    apiBaseUrl: 'https://api.test.movera.invalid',
    mapsEnabled: true,
  );

  Future<void> pump(WidgetTester tester, Widget child) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (_, __) => MaterialApp(home: child),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }

  AuthController controllerFor(InProcessMockClient client) {
    final tokens = MemoryTokenStore();
    return AuthController(
      auth: AuthRepository(
        api: ApiClient(env: env, client: client, tokens: tokens),
        tokens: tokens,
      ),
    );
  }

  testWidgets('failed OTP request stays on phone entry', (tester) async {
    final client = InProcessMockClient()..failNext = true;
    final controller = controllerFor(client);
    await pump(tester, SignInPhone(controller: controller));

    await tester.enterText(find.byType(EditableText).first, '701234567');
    await tester.tap(find.text('Continue'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));

    expect(find.byType(SignInPhone), findsOneWidget);
    expect(find.byType(PhoneVerification), findsNothing);
    expect(find.textContaining('Could not send'), findsAtLeastNWidgets(1));
  });

  testWidgets('wrong OTP cannot reveal Home', (tester) async {
    final client = InProcessMockClient();
    final controller = controllerFor(client);
    final challenge = await controller.requestOtp(phone: '+46701234567');

    await pump(
      tester,
      PhoneVerification(
        challenge: challenge,
        controller: controller,
      ),
    );

    expect(find.text('Phone verification'), findsOneWidget);
    expect(find.byType(Home, skipOffstage: false), findsNothing);
    await tester.tap(find.byType(Pinput));
    await tester.enterText(find.byType(EditableText).last, '9999');
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));

    expect(find.text('Phone verification'), findsOneWidget);
    expect(find.textContaining('not valid'), findsAtLeastNWidgets(1));
    expect(find.byType(Home, skipOffstage: false), findsNothing);
  });

  testWidgets(
    'Phase 132 cluster 4: SignInPhone rejects a too-short number that the '
    'old length-only check would have accepted',
    (tester) async {
      final client = InProcessMockClient();
      final controller = controllerFor(client);
      await pump(tester, SignInPhone(controller: controller));

      // 5 national digits: old check was `'+46$digits'.length < 7`, i.e.
      // '+4612345' has length 8, which passed. The real E.164 validator
      // requires 7-10 national digits, so this must now be rejected.
      await tester.enterText(find.byType(EditableText).first, '12345');
      await tester.tap(find.text('Continue'));
      await tester.pump();

      expect(find.byType(PhoneVerification), findsNothing);
      expect(find.textContaining('Enter a valid phone number'), findsAtLeastNWidgets(1));
    },
  );

  testWidgets(
    'Phase 132 cluster 4: CreateAccount rejects the same too-short number '
    'SignInPhone now rejects, closing the old threshold mismatch',
    (tester) async {
      final client = InProcessMockClient();
      final controller = controllerFor(client);
      await pump(tester, CreateAccount(controller: controller));

      await tester.enterText(find.byType(EditableText).at(0), 'Test Rider');
      // Same 5-digit number as the SignInPhone case above.
      await tester.enterText(find.byType(EditableText).at(1), '12345');
      await tester.tap(find.byType(CustomCheckBox));
      await tester.pump();
      await tester.tap(find.text('Continue'));
      await tester.pump();

      expect(find.byType(PhoneVerification), findsNothing);
      expect(find.textContaining('Enter a valid phone number'), findsAtLeastNWidgets(1));
    },
  );

  testWidgets(
    'Phase 132 cluster 4: CreateAccount accepts the same valid Swedish '
    'number SignInPhone accepts',
    (tester) async {
      final client = InProcessMockClient();
      final controller = controllerFor(client);
      await pump(tester, CreateAccount(controller: controller));

      await tester.enterText(find.byType(EditableText).at(0), 'Test Rider');
      await tester.enterText(find.byType(EditableText).at(1), '701234567');
      await tester.tap(find.byType(CustomCheckBox));
      await tester.pump();
      await tester.tap(find.text('Continue'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      expect(find.byType(PhoneVerification), findsOneWidget);
    },
  );

  testWidgets('auth-required sign-in reaches create-account phone flow', (tester) async {
    const authEnv = AppEnv(
      flavor: AppFlavor.test,
      apiBaseUrl: 'https://api.test.movera.invalid',
      mapsEnabled: true,
      authRequired: true,
    );
    final tokens = MemoryTokenStore();
    final controller = AuthController(
      auth: AuthRepository(
        api: ApiClient(env: authEnv, client: InProcessMockClient(), tokens: tokens),
        tokens: tokens,
      ),
    );
    await pump(tester, SignIn(controller: controller));
    expect(find.byType(Home, skipOffstage: false), findsNothing);
    await tester.tap(find.text('Continue with phone'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(CreateAccount), findsOneWidget);
    expect(find.byType(Home, skipOffstage: false), findsNothing);
  });
}
