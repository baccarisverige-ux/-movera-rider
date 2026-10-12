import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movera_rider/app/config/env.dart';
import 'package:movera_rider/core/api/api_client.dart';
import 'package:movera_rider/core/api/in_process_mock_client.dart';
import 'package:movera_rider/core/auth/token_store.dart';
import 'package:movera_rider/core/feature_flags/feature_flags.dart';
import 'package:movera_rider/features/promotions/application/promotions_controller.dart';
import 'package:movera_rider/features/promotions/data/promotions_repository.dart';
import 'package:movera_rider/features/promotions/domain/promotion.dart';
import 'package:movera_rider/features/promotions/presentation/offers_screen.dart';
import 'package:movera_rider/features/promotions/presentation/promo_popup.dart';
import 'package:movera_rider/features/promotions/presentation/voucher_code_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  const testEnv = AppEnv(
    flavor: AppFlavor.test,
    apiBaseUrl: 'https://api.test.movera.invalid',
    mapsEnabled: true,
  );

  PromotionsController controller() => PromotionsController(
        repository: ApiPromotionsRepository(
          api: ApiClient(env: testEnv, client: InProcessMockClient(), tokens: MemoryTokenStore()),
        ),
        flags: const FeatureFlags(),
      );

  Future<void> pump(WidgetTester tester, Widget screen) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 844),
        minTextAdapt: true,
        builder: (_, __) => MaterialApp(home: screen),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('offers lists what the rider has and a code can be added from it', (tester) async {
    final promotions = controller();
    await pump(tester, OffersScreen(controller: promotions));
    expect(find.text('Offers & vouchers'), findsOneWidget);
    expect(find.text('Welcome to Movera'), findsOneWidget);
    expect(find.text('30% off, up to kr 50'), findsOneWidget);

    await tester.tap(find.text('Add a voucher code'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'nosuchcode');
    await tester.tap(find.text('Use code'));
    await tester.pumpAndSettle();
    expect(find.text(RedeemFailure.unknownCode.message), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'flat40');
    await tester.tap(find.text('Use code'));
    await tester.pumpAndSettle();
    expect(find.byType(VoucherCodeSheet), findsNothing);
    expect(find.text('kr 40 off'), findsOneWidget);
    expect(promotions.live.map((item) => item.code), containsAll(['WELCOME30', 'FLAT40']));
  });

  testWidgets('the voucher sheet opens with a code from a link already filled in', (tester) async {
    final promotions = controller();
    await pump(tester, VoucherCodeSheet(initialCode: 'AUTUMN15', controller: promotions));
    expect(find.text('AUTUMN15'), findsOneWidget);
    await tester.tap(find.text('Use code'));
    await tester.pumpAndSettle();
    expect(promotions.live.map((item) => item.code), contains('AUTUMN15'));
  });

  testWidgets('the popup shows the offer and the code, and tells whether the rider took it', (tester) async {
    final promotion = Promotion(
      id: 'p',
      code: 'WELCOME30',
      title: 'Welcome to Movera',
      kind: PromotionKind.percent,
      value: 30,
      maxPerRideMinor: 5000,
      minFareMinor: 0,
      ridesLeft: 3,
      validFrom: DateTime.utc(2026, 1, 1),
      validTo: DateTime.utc(2026, 12, 31),
      popup: true,
    );
    bool? result;
    await pump(
      tester,
      Builder(
        builder: (context) => Center(
          child: FilledButton(
            onPressed: () async => result = await showPromoPopup(context, promotion),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome to Movera'), findsOneWidget);
    expect(find.text('30% off, up to kr 50'), findsOneWidget);
    expect(find.text('WELCOME30'), findsOneWidget);
    await tester.tap(find.text('Use it now'));
    await tester.pumpAndSettle();
    expect(result, isTrue);
  });
}
