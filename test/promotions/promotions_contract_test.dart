import 'package:flutter_test/flutter_test.dart';
import 'package:movera_rider/app/config/env.dart';
import 'package:movera_rider/core/api/api_client.dart';
import 'package:movera_rider/core/api/in_process_mock_client.dart';
import 'package:movera_rider/core/auth/token_store.dart';
import 'package:movera_rider/core/feature_flags/feature_flags.dart';
import 'package:movera_rider/features/promotions/application/promotions_controller.dart';
import 'package:movera_rider/features/promotions/data/promotions_repository.dart';
import 'package:movera_rider/features/promotions/domain/promotion.dart';
import 'package:movera_rider/features/ride_booking/data/api_quote_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  const testEnv = AppEnv(
    flavor: AppFlavor.test,
    apiBaseUrl: 'https://api.test.movera.invalid',
    mapsEnabled: true,
  );

  ApiClient client(InProcessMockClient mock) =>
      ApiClient(env: testEnv, client: mock, tokens: MemoryTokenStore());

  test('the rider starts with the welcome promotion, marked as a popup', () async {
    final repo = ApiPromotionsRepository(api: client(InProcessMockClient()));
    final list = await repo.list();
    expect(list.map((item) => item.code), ['WELCOME30']);
    expect(list.single.popup, isTrue);
    expect(list.single.ridesLeft, 3);
  });

  test('a code unlocks once; unknown, ended and repeated codes are refused with a reason', () async {
    final repo = ApiPromotionsRepository(api: client(InProcessMockClient()));
    final unlocked = await repo.redeem('autumn15');
    expect(unlocked.code, 'AUTUMN15');
    expect((await repo.list()).map((item) => item.code), containsAll(['WELCOME30', 'AUTUMN15']));

    Future<RedeemFailure> failure(String code) async {
      try {
        await repo.redeem(code);
      } on RedeemException catch (fault) {
        return fault.failure;
      }
      fail('expected $code to be refused');
    }

    expect(await failure('AUTUMN15'), RedeemFailure.alreadyUsed);
    expect(await failure('NOSUCHCODE'), RedeemFailure.unknownCode);
    expect(await failure('OLDCODE'), RedeemFailure.expired);
  });

  test('a quote with the code is lowered by the promotion, within its cap', () async {
    final mock = InProcessMockClient();
    final quotes = ApiQuoteRepository(api: client(mock));
    final plain = await quotes.quote(rideType: 'movera', distanceMeters: 8000);
    expect(plain.totalMinor, 25900);
    expect(plain.discountMinor, 0);

    final discounted = await quotes.quote(rideType: 'movera', distanceMeters: 8000, promoCode: 'WELCOME30');
    expect(discounted.discountMinor, 5000, reason: '30% of kr 259 is kr 77.70, capped at kr 50');
    expect(discounted.totalMinor, 20900);

    final unknown = await quotes.quote(rideType: 'movera', distanceMeters: 8000, promoCode: 'NOPE');
    expect(unknown.totalMinor, 25900);
  });

  test('the controller remembers promotions, applies the best code and shows a popup once', () async {
    final mock = InProcessMockClient();
    final controller = PromotionsController(
      repository: ApiPromotionsRepository(api: client(mock)),
      flags: const FeatureFlags(),
    );
    await controller.load();
    expect(controller.live.map((item) => item.code), ['WELCOME30']);
    expect(controller.appliedCode, 'WELCOME30');
    expect(controller.bestFor(rideType: 'movera', fareMinor: 25900)?.code, 'WELCOME30');

    final popup = controller.popupToShow();
    expect(popup?.code, 'WELCOME30');
    await controller.markPopupSeen(popup!);
    expect(controller.popupToShow(), isNull);

    final again = PromotionsController(
      repository: ApiPromotionsRepository(api: client(mock)),
      flags: const FeatureFlags(),
    );
    await again.load();
    expect(again.popupToShow(), isNull, reason: 'closing the popup is remembered on the phone');
    expect(again.live.length, 1);

    await again.redeem('FLAT40');
    expect(again.live.map((item) => item.code), containsAll(['WELCOME30', 'FLAT40']));
    expect(() => again.redeem('FLAT40'), throwsA(isA<RedeemException>()));
  });

  test('promotions switched off: nothing is applied and no popup shows', () async {
    final controller = PromotionsController(
      repository: ApiPromotionsRepository(api: client(InProcessMockClient())),
      flags: const FeatureFlags(enablePromotions: false),
    );
    await controller.load();
    expect(controller.appliedCode, isNull);
    expect(controller.popupToShow(), isNull);
    final noPopup = PromotionsController(
      repository: ApiPromotionsRepository(api: client(InProcessMockClient())),
      flags: const FeatureFlags(enablePromoPopup: false),
    );
    await noPopup.load();
    expect(noPopup.appliedCode, 'WELCOME30');
    expect(noPopup.popupToShow(), isNull);
  });
}
