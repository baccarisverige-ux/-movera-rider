import 'package:flutter_test/flutter_test.dart';
import 'package:movera_rider/core/payments/mock_payment_gateway.dart';
import 'package:movera_rider/features/wallet/domain/wallet_ledger.dart';

void main() {
  test('successful top-up intent', () async {
    final gw = MockPaymentGateway();
    final intent = await gw.create(
      amountMinor: 10000,
      currency: 'SEK',
      idempotencyKey: 'wallet-1',
    );
    expect(await gw.confirm(intent.id), 'succeeded');
  });

  test('failed top-up is injectable', () async {
    final gw = MockPaymentGateway()..failNext = true;
    expect(
      () => gw.create(
        amountMinor: 10000,
        currency: 'SEK',
        idempotencyKey: 'wallet-fail',
      ),
      throwsA(isA<StateError>()),
    );
  });

  test('duplicate payment key returns same intent family', () async {
    final gw = MockPaymentGateway();
    await gw.create(
      amountMinor: 5000,
      currency: 'SEK',
      idempotencyKey: 'dup',
    );
    final second = await gw.create(
      amountMinor: 5000,
      currency: 'SEK',
      idempotencyKey: 'dup',
    );
    expect(second.amountMinor, 5000);
  });

  test('ledger calculation', () {
    final ledger = WalletLedger();
    ledger.add(
      WalletEntry(
        id: '1',
        kind: WalletEntryKind.credit,
        amountMinor: 20000,
        at: DateTime(2026),
      ),
    );
    ledger.add(
      WalletEntry(
        id: '2',
        kind: WalletEntryKind.ride,
        amountMinor: -5000,
        at: DateTime(2026, 1, 2),
      ),
    );
    expect(ledger.balanceMinor, 15000);
  });
}
