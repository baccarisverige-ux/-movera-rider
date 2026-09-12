import 'package:flutter_test/flutter_test.dart';
import 'package:movera_rider/core/payments/mock_payment_gateway.dart';
import 'package:movera_rider/features/wallet/application/wallet_controller.dart';
import 'package:movera_rider/features/wallet/data/voucher_catalog.dart';
import 'package:movera_rider/features/wallet/data/wallet_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MemWallet extends WalletStore {
  double balance = 0;

  @override
  Future<double> loadBalance() async => balance;

  @override
  Future<void> saveBalance(double value) async {
    balance = value;
  }

  @override
  Future<void> saveVoucher({
    required String code,
    required int amountKr,
    required DateTime expires,
  }) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('voucher lookup and expiry', () {
    final catalog = VoucherCatalog();
    expect(catalog.lookup('MOVERA100')?.amountKr, 100);
    expect(catalog.lookup('SUMMER75')?.expired, isTrue);
    expect(catalog.lookup('nope'), isNull);
  });

  test('top-up idempotency key reused', () async {
    final gw = MockPaymentGateway();
    final a = await gw.create(
      amountMinor: 20000,
      currency: 'SEK',
      idempotencyKey: 'same',
    );
    final b = await gw.create(
      amountMinor: 20000,
      currency: 'SEK',
      idempotencyKey: 'same',
    );
    expect(a.id, b.id);
  });

  test('wallet ops are separate', () async {
    final store = _MemWallet()..balance = 50;
    final wallet = WalletController(store: store);
    final topped = await wallet.topUp(previous: 50, amount: 200);
    expect(topped, 250);
    final voucher = await wallet.redeemVoucher(
      previous: 250,
      offer: VoucherOffer(
        code: 'MOVERA100',
        amountKr: 100,
        expires: DateTime(2026, 12, 31),
      ),
    );
    expect(voucher, 350);
    final charged = await wallet.chargeRide(previous: 350, amount: 80);
    expect(charged, 270);
    final refunded = await wallet.refund(previous: 270, amount: 80);
    expect(refunded, 350);
  });

  test('top-up same idempotency key does not double credit', () async {
    final store = _MemWallet();
    final wallet = WalletController(store: store);
    final a = await wallet.topUp(
      previous: 0,
      amount: 100,
      idempotencyKey: 'top-1',
    );
    final b = await wallet.topUp(
      previous: a ?? 0,
      amount: 100,
      idempotencyKey: 'top-1',
    );
    expect(a, 100);
    expect(b, 100);
  });
}
