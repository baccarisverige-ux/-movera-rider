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

/// Verification used to announce a code sent to +96441938184 — a number nobody
/// typed, on one of the first screens a rider ever sees.
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

  AuthController controller() {
    final tokens = MemoryTokenStore();
    return AuthController(
      auth: AuthRepository(
        api: ApiClient(
          env: env,
          client: InProcessMockClient(),
          tokens: tokens,
        ),
        tokens: tokens,
      ),
    );
  }

  testWidgets('resend row fits and respects the server retry window',
      (tester) async {
    final auth = controller();
    final challenge = await auth.requestOtp(phone: '+46701234567');
    await pump(
      tester,
      PhoneVerification(
        challenge: challenge,
        controller: auth,
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Resend code'), findsOneWidget);
    expect(find.text('Sign in'), findsNothing);

    await tester.tap(find.text('Resend code'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      find.textContaining('request another code in'),
      findsAtLeastNWidgets(1),
    );
  });

  testWidgets('a known number is shown back to the rider', (tester) async {
    await pump(tester, const PhoneVerification(phoneNumber: '+46 701234567'));

    expect(
      find.textContaining('+46 701234567', findRichText: true),
      findsOneWidget,
    );
  });

  testWidgets('an unknown number is not invented', (tester) async {
    await pump(tester, const PhoneVerification());

    expect(
      find.textContaining(
        'sent a verification code to your phone',
        findRichText: true,
      ),
      findsOneWidget,
    );
    expect(find.textContaining('+', findRichText: true), findsNothing);
  });
}
