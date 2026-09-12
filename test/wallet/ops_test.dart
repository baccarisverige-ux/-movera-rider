import 'package:flutter_test/flutter_test.dart';
import 'package:movera_rider/core/payments/mock_payment_gateway.dart';
import 'package:movera_rider/features/wallet/data/voucher_catalog.dart';

void main() {
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
}
