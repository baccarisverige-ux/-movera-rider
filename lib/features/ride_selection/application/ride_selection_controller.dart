import 'dart:async';

import 'package:movera_rider/app/di.dart';
import 'package:movera_rider/core/feature_flags/feature_flags.dart';
import 'package:movera_rider/features/fare/application/fare_controller.dart';
import 'package:movera_rider/features/payments/data/default_payment_store.dart';
import 'package:movera_rider/features/ride_booking/data/mock_quote_repository.dart';
import 'package:movera_rider/features/ride_selection/data/ride_selection_repository.dart';
import 'package:movera_rider/features/ride_selection/domain/booking_mode.dart';
import 'package:movera_rider/features/ride_selection/domain/ride_selection.dart';

class RideSelectionController {
  RideSelectionController({
    RideSelectionRepository? store,
    QuoteRepository? quotes,
    FareController? fare,
    FeatureFlags? flags,
    DefaultPaymentStore? paymentStore,
    this.bookingMode = BookingMode.now,
    this.lockBookingMode = false,
  }) : _store = store ?? RideSelectionRepository(),
       _quotes = quotes ?? AppScope.instance.quotes,
       _fare = fare ?? FareController(),
       _flags = flags ?? AppScope.instance.flags,
       _paymentStore = paymentStore;

  final RideSelectionRepository _store;
  final QuoteRepository _quotes;
  final FareController _fare;
  final FeatureFlags _flags;
  final DefaultPaymentStore? _paymentStore;

  final Map<String, double> offeredPrices = {};
  final Map<String, String> quoteIds = {};
  final Map<String, DateTime> quoteExpiresAt = {};
  int _quoteGeneration = 0;
  bool usedFallback = false;
  String selectedRideId = 'movera';
  int selectedPayment = 1;
  DateTime? scheduledFor;
  BookingMode bookingMode;
  bool lockBookingMode;

  bool get isScheduled =>
      bookingMode == BookingMode.scheduled && scheduledFor != null;

  bool get entersFindingDriver => bookingMode.entersFindingDriver;

  bool get createsReservation => bookingMode.createsReservation;

  List<RideCatalogItem> rides() => _store.rides();

  RideCatalogItem rideById(String id) {
    return rides().firstWhere(
      (ride) => ride.id == id,
      orElse: () => rides().first,
    );
  }

  List<RidePaymentItem> payments() {
    return _store.payments().where((item) {
      if (item.brand == 'cash') return _flags.enableCash;
      if (item.brand == 'apple') return _flags.enableApplePay;
      if (item.brand == 'wallet') return _flags.enableWallet;
      if (item.brand == 'google') return _flags.enableGooglePay;
      if (item.brand == 'swish') return _flags.enableSwish;
      return true;
    }).toList();
  }

  int beginQuotes() => ++_quoteGeneration;

  Future<void> loadQuotes({
    required int generation,
    required String pickup,
    required String destination,
    int distanceMeters = 3000,
  }) async {
    usedFallback = false;
    for (final ride in rides()) {
      if (generation != _quoteGeneration) return;
      final quote = await _quotes.quote(
        rideType: ride.id,
        distanceMeters: distanceMeters,
        pickup: pickup,
        destination: destination,
      );
      if (generation != _quoteGeneration) return;
      offeredPrices[ride.id] = quote.totalMinor / 100;
      quoteIds[ride.id] = quote.id;
      quoteExpiresAt[ride.id] = quote.expiresAt;
      if (quote.signedPayload == 'fallback') usedFallback = true;
    }
  }

  bool quoteIsFresh(String id, {DateTime? now}) {
    final expiresAt = quoteExpiresAt[id];
    if (expiresAt == null) return quoteIds[id] == null;
    return expiresAt.isAfter(now ?? DateTime.now());
  }

  void _discardExpiredQuote(String id, {DateTime? now}) {
    final expiresAt = quoteExpiresAt[id];
    if (expiresAt == null || expiresAt.isAfter(now ?? DateTime.now())) return;
    offeredPrices.remove(id);
    quoteIds.remove(id);
    quoteExpiresAt.remove(id);
  }

  double priceFor(String id, double catalog, {DateTime? now}) {
    _discardExpiredQuote(id, now: now);
    return offeredPrices[id] ?? catalog;
  }

  void selectRide(String id, double catalog) {
    selectedRideId = id;
    offeredPrices.putIfAbsent(id, () => catalog);
  }

  void selectPayment(int index) {
    selectedPayment = index;
    _persistSelectedBrand();
  }

  void selectPaymentNamed(String? name) {
    final needle = name?.trim();
    if (needle == null || needle.isEmpty) return;
    final list = payments();
    final i = list.indexWhere(
      (item) => item.name.toLowerCase() == needle.toLowerCase(),
    );
    if (i >= 0) selectedPayment = i;
  }

  void selectPaymentByBrand(String? brand) {
    final needle = brand?.trim();
    if (needle == null || needle.isEmpty) return;
    final list = payments();
    final i = list.indexWhere((item) => item.brand == needle);
    if (i >= 0) selectedPayment = i;
  }

  Future<void> restoreDefaultPayment() async {
    final store = _paymentStore;
    if (store == null) return;
    selectPaymentByBrand(await store.read());
  }

  void _persistSelectedBrand() {
    final store = _paymentStore;
    if (store == null) return;
    final list = payments();
    if (selectedPayment < 0 || selectedPayment >= list.length) return;
    unawaited(store.save(list[selectedPayment].brand));
  }

  void setBookingMode(BookingMode mode) {
    if (lockBookingMode && mode != BookingMode.scheduled) return;
    bookingMode = mode;
    if (mode == BookingMode.now) {
      scheduledFor = null;
    }
  }

  void scheduleFor(DateTime? at) {
    scheduledFor = at;
    if (at == null) {
      if (!lockBookingMode) bookingMode = BookingMode.now;
      return;
    }
    bookingMode = BookingMode.scheduled;
  }

  String? quoteIdFor(String id, {DateTime? now}) {
    _discardExpiredQuote(id, now: now);
    return quoteIds[id];
  }

  DateTime? expiryFor(String id) => quoteExpiresAt[id];

  double changeOffer({
    required String id,
    required double catalog,
    required int delta,
  }) {
    final current = priceFor(id, catalog);
    final next = _fare.nudge(current: current, catalog: catalog, delta: delta);
    offeredPrices[id] = next;
    return next;
  }
}
