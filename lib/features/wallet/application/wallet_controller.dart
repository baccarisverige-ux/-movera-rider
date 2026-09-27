import 'package:movera_rider/app/di.dart';
import 'package:movera_rider/core/analytics/analytics.dart';
import 'package:movera_rider/core/api/idempotency.dart';
import 'package:movera_rider/core/logging/app_log.dart';
import 'package:movera_rider/core/storage/preferences_store.dart';
import 'package:movera_rider/features/ride_booking/data/ride_snapshot_store.dart';
import 'package:movera_rider/features/ride_complete/data/last_completed_ride.dart';
import 'package:movera_rider/features/wallet/data/wallet_repository.dart';
import 'package:movera_rider/features/wallet/domain/wallet_ledger.dart';

export 'package:movera_rider/features/wallet/data/wallet_repository.dart'
    show WalletPaymentSettings;

class WalletController {
  WalletController({WalletStore? store}) : _store = store ?? WalletStore();

  final WalletStore _store;
  final Set<String> _topUpKeys = {};

  Future<WalletPaymentSettings> loadPayments() => _store.loadPayments();

  Future<void> savePayments(WalletPaymentSettings settings) =>
      _store.savePayments(settings);

  Future<double> loadBalance() => _store.loadBalance();

  Future<double?> topUp({
    required double previous,
    required double amount,
    String? idempotencyKey,
  }) async {
    final key = idempotencyKey ?? newIdempotencyKey('wallet');
    if (_topUpKeys.contains(key)) return previous;
    _topUpKeys.add(key);
    try {
      final intent = await AppScope.instance.paymentGateway.create(
        amountMinor: (amount * 100).round(),
        currency: 'SEK',
        idempotencyKey: key,
      );
      final status = await AppScope.instance.paymentGateway.confirm(intent.id);
      if (status != 'succeeded') return null;
      Analytics.track('payment_succeeded', extra: {'intent': intent.id});
    } catch (error, stack) {
      Analytics.paymentFailed();
      AppScope.instance.crashes.record(error, stack, operation: 'wallet.topup');
      return null;
    }
    final next = previous + amount;
    await _store.saveBalance(next);
    AppScope.instance.wallet.add(
      WalletEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        kind: WalletEntryKind.credit,
        amountMinor: (amount * 100).round(),
        at: DateTime.now(),
      ),
    );
    return next;
  }

  /// Ride ids already deducted from the local balance, so a replayed
  /// payment event, a reload of the completion screen or a restored session
  /// can never charge the same ride twice.
  static const chargedRidesKey = 'movera_wallet_charged_rides';
  static const _chargedRidesKept = 50;
  static final Set<String> _chargesInFlight = {};

  /// True when the ride's payment method is the Movera Wallet. Snapshots carry
  /// either the brand id ('wallet') or its display name ('Movera Wallet').
  static bool isWalletPayment(String paymentMethod) =>
      paymentMethod.trim().toLowerCase().contains('wallet');

  /// Resolves the completed ride for [rideId] (the completion screen's
  /// remembered snapshot, else the persisted one) and charges it if it was
  /// paid from the wallet. See [chargeCompletedRide].
  Future<double?> chargeCompletedRideById(String rideId) async {
    final id = rideId.trim();
    final remembered = LastCompletedRide.value;
    final snapshot = remembered?.rideId?.trim() == id
        ? remembered
        : await RideSnapshotStore.readForArchive();
    return chargeCompletedRide(snapshot, rideId: id);
  }

  /// D-022: deducts a wallet-paid ride from the local balance once it has
  /// reached a charged status (paymentFinalized or later).
  ///
  /// [chargeRide] existed but had no callers, so wallet rides never reduced
  /// the balance. This makes the existing local ledger self-consistent; it
  /// does not make it authoritative — the balance is still a client-side
  /// value (R-043) until a server-owned ledger replaces [WalletStore].
  ///
  /// Returns the new balance, or null when nothing was charged (not a wallet
  /// ride, a different ride, no usable price, or already charged).
  Future<double?> chargeCompletedRide(
    RideSnapshot? snapshot, {
    required String rideId,
  }) async {
    final id = rideId.trim();
    if (id.isEmpty || snapshot == null || snapshot.rideId?.trim() != id) {
      return null;
    }
    if (!isWalletPayment(snapshot.paymentMethod)) return null;
    final amount = snapshot.price;
    if (!amount.isFinite || amount <= 0) return null;
    if (!_chargesInFlight.add(id)) return null;
    try {
      final prefs = await PreferencesStore.load();
      final charged = prefs.getStringList(chargedRidesKey) ?? const <String>[];
      if (charged.contains(id)) return null;
      final kept = charged.length >= _chargedRidesKept
          ? charged.sublist(charged.length - _chargedRidesKept + 1)
          : charged;
      // Record first: a crash between the two writes must err towards not
      // charging twice rather than charging again on the next launch.
      await prefs.setStringList(chargedRidesKey, [...kept, id]);
      final previous = await _store.loadBalance();
      final next = await chargeRide(previous: previous, amount: amount);
      AppLog.info(
        'wallet.ride_charged',
        extra: {'rideId': id, 'amount': amount, 'localOnly': true},
      );
      return next;
    } finally {
      _chargesInFlight.remove(id);
    }
  }

  Future<double> chargeRide({
    required double previous,
    required double amount,
  }) async {
    final next = previous - amount;
    await _store.saveBalance(next);
    AppScope.instance.wallet.add(
      WalletEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        kind: WalletEntryKind.ride,
        amountMinor: -(amount * 100).round(),
        at: DateTime.now(),
      ),
    );
    return next;
  }

  Future<double> refund({
    required double previous,
    required double amount,
  }) async {
    final next = previous + amount;
    await _store.saveBalance(next);
    AppScope.instance.wallet.add(
      WalletEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        kind: WalletEntryKind.refund,
        amountMinor: (amount * 100).round(),
        at: DateTime.now(),
      ),
    );
    return next;
  }
}
