import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movera_rider/features/auth/presentation/phone_verify.dart';

/// Verification used to announce a code sent to +96441938184 — a number nobody
/// typed, on one of the first screens a rider ever sees.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

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

  test('no hardcoded phone number survives in auth', () {
    for (final name in const [
      'lib/features/auth/presentation/phone_verify.dart',
      'lib/features/auth/presentation/sign_in_phone.dart',
      'lib/features/auth/presentation/create_acc.dart',
    ]) {
      final src = File(name).readAsStringSync();
      expect(src.contains('96441938184'), isFalse, reason: name);
    }
  });

  test('the broken verification copy is gone', () {
    final src = File(
      'lib/features/auth/presentation/phone_verify.dart',
    ).readAsStringSync();
    expect(src.contains('Did you don'), isFalse);
    expect(src.contains('4 digit code'), isFalse);
    expect(src.contains('4-digit code'), isTrue);
  });

  test('sign-in defaults to Sweden, where Movera operates', () {
    final src = File(
      'lib/features/auth/presentation/sign_in_phone.dart',
    ).readAsStringSync();
    expect(src.contains("getCountryByIsoCode('SE')"), isTrue);
    expect(src.contains("selectedCountryCode = '+1'"), isFalse);
  });

  testWidgets('the resend row fits the screen and acts', (tester) async {
    await pump(tester, const PhoneVerification(phoneNumber: '+46 701234567'));

    expect(tester.takeException(), isNull);
    expect(find.text('Resend code'), findsOneWidget);
    expect(find.text('Sign in'), findsNothing);

    await tester.tap(find.text('Resend code'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    // A SnackBar appears twice mid-animation; one is enough.
    expect(find.textContaining('sent another code'), findsAtLeastNWidgets(1));
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
      find.textContaining('sent a verification code to your phone',
          findRichText: true),
      findsOneWidget,
    );
    expect(find.textContaining('+', findRichText: true), findsNothing);
  });
}
