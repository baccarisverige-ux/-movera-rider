import 'package:flutter_test/flutter_test.dart';
import 'package:movera_rider/core/observability/observability.dart';
import 'package:movera_rider/features/wallet/application/wallet_controller.dart';
import 'package:movera_rider/features/wallet/data/wallet_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _BrokenStore extends WalletStore {
  @override
  Future<void> savePayments(WalletPaymentSettings settings) async {
    throw StateError('disk full');
  }
}

class _Logger implements LoggerSink {
  final events = <String>[];

  @override
  void log(
    TelemetryLevel level,
    String event, {
    Map<String, Object?> extra = const {},
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (level == TelemetryLevel.warning) events.add(event);
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues(<String, Object>{}));
  tearDown(Observability.reset);

  test(
    'CODE-16: a use-wallet-first save failure is reported, not swallowed',
    () async {
      final logger = _Logger();
      Observability.configure(loggerSink: logger);
      final wallet = WalletController(store: _BrokenStore());

      // The caller (Select Ride) puts its toggle back on false.
      expect(await wallet.saveUseWalletFirst(true), isFalse);
      expect(logger.events, contains('wallet.use_wallet_first_save_failed'));

      expect(await WalletController().saveUseWalletFirst(false), isTrue);
      expect(await WalletController().loadUseWalletFirst(), isFalse);
    },
  );
}
