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
import 'package:movera_rider/features/auth/presentation/sign_in_phone.dart';
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

    await tester.enterText(find.byType(TextField).first, '701234567');
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
    await tester.tap(find.byType(Pinput));
    await tester.enterText(find.byType(EditableText).last, '9999');
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));

    expect(find.text('Phone verification'), findsOneWidget);
    expect(find.textContaining('not valid'), findsAtLeastNWidgets(1));
  });
}
