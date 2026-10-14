import 'dart:convert';

import 'package:movera_rider/core/api/api_client.dart';
import 'package:movera_rider/core/api/api_error.dart';
import 'package:movera_rider/core/api/idempotency.dart';
import 'package:movera_rider/core/location/geocoding_repository.dart';
import 'package:movera_rider/core/maps/geo_point.dart';
import 'package:movera_rider/features/fare/domain/fare_rules.dart';
import 'package:movera_rider/features/ride_booking/data/ride_snapshot_store.dart';
import 'package:movera_rider/features/ride_booking/domain/route_stop.dart';

export 'package:movera_rider/features/ride_booking/data/ride_snapshot_store.dart'
    show RideSnapshot;

/// A priced route change the rider has not confirmed yet.
class RouteChangeQuote {
  const RouteChangeQuote({
    required this.pickupAddress,
    required this.pickupPoint,
    required this.destinationAddress,
    required this.destinationPoint,
    required this.stops,
    required this.oldPriceKr,
    required this.newPriceKr,
    this.routeQuoteId,
    this.expiresAt,
    this.newTotalMinor,
    this.differenceMinor,
  });

  final String pickupAddress;
  final GeoPoint pickupPoint;
  final String destinationAddress;
  final GeoPoint destinationPoint;
  final List<RouteStop> stops;
  final double oldPriceKr;
  final double newPriceKr;

  /// ARCH-14 / contract C-7: the server's id for this priced change, when it
  /// sends one. Apply sends it back with the amounts, so the server applies
  /// exactly the price the rider confirmed or refuses (409) and the rider
  /// sees the new price first.
  final String? routeQuoteId;
  final DateTime? expiresAt;
  final int? newTotalMinor;
  final int? differenceMinor;

  /// Positive when the rider pays more, negative when money comes back.
  double get differenceKr => newPriceKr - oldPriceKr;

  Map<String, dynamic> toRequest() => {
    'pickupAddress': pickupAddress,
    'pickupLat': pickupPoint.latitude,
    'pickupLng': pickupPoint.longitude,
    'destinationAddress': destinationAddress,
    'destinationLat': destinationPoint.latitude,
    'destinationLng': destinationPoint.longitude,
    'stops': [for (final stop in stops) stop.toJson()],
  };
}

/// Why a route change could not be priced or applied.
enum RouteChangeFailure {
  pickupLocked,
  rideFinished,
  addressNotFound,
  network,
  priceChanged,
}

class RouteChangeException implements Exception {
  const RouteChangeException(this.failure);
  final RouteChangeFailure failure;

  String get message => switch (failure) {
    RouteChangeFailure.pickupLocked =>
      'The driver is already at your pickup; only the destination and stops can change.',
    RouteChangeFailure.rideFinished => 'This ride can no longer be changed.',
    RouteChangeFailure.addressNotFound =>
      'Could not find that address. Try a more exact one.',
    RouteChangeFailure.network => 'Couldn’t update the route. Try again.',
    RouteChangeFailure.priceChanged =>
      'The price for this route changed. Check the new price and confirm again.',
  };
}

/// Changes the route of a ride that is being searched, waited for or driven:
/// prices the new route first, then applies it and tells the driver.
class RouteChangeController {
  RouteChangeController({required ApiClient api, required GeocodingRepository geocoding})
    : _api = api,
      _geocoding = geocoding;

  final ApiClient _api;
  final GeocodingRepository _geocoding;

  /// The ride as last saved on this device, if any.
  static Future<RideSnapshot?> storedRide() => RideSnapshotStore.read();

  /// Prices the new route. Addresses without a point are geocoded first.
  Future<RouteChangeQuote> preview({
    required RideSnapshot ride,
    String? pickupAddress,
    GeoPoint? pickupPoint,
    required String destinationAddress,
    GeoPoint? destinationPoint,
    List<String> stops = const [],
    List<GeoPoint?> stopPoints = const [],
  }) async {
    final id = ride.rideId;
    if (id == null) throw const RouteChangeException(RouteChangeFailure.network);
    final pickup = pickupAddress?.trim().isNotEmpty == true
        ? pickupAddress!.trim()
        : ride.pickupAddress;
    final pickupAt = pickup == ride.pickupAddress
        ? GeoPoint(ride.pickupLat, ride.pickupLng)
        : pickupPoint ?? await _locate(pickup);
    final destination = destinationAddress.trim();
    final destinationAt = destination == ride.destinationAddress
        ? GeoPoint(ride.destinationLat, ride.destinationLng)
        : destinationPoint ?? await _locate(destination);
    final located = <RouteStop>[];
    for (var i = 0; i < stops.length; i++) {
      final address = stops[i].trim();
      if (address.isEmpty) continue;
      final known = ride.stops.where((s) => s.address == address).firstOrNull;
      final point =
          (i < stopPoints.length ? stopPoints[i] : null) ??
          (known == null ? null : GeoPoint(known.latitude, known.longitude)) ??
          await _locate(address);
      located.add(
        RouteStop(address: address, latitude: point.latitude, longitude: point.longitude),
      );
    }
    final draft = RouteChangeQuote(
      pickupAddress: pickup,
      pickupPoint: pickupAt,
      destinationAddress: destination,
      destinationPoint: destinationAt,
      stops: located,
      oldPriceKr: ride.price,
      newPriceKr: ride.price,
    );
    final response = await _send(
      () => _api.post('/api/v1/rides/$id/route-quote', body: draft.toRequest()),
    );
    final price = response['newPriceKr'];
    final quoteId = response['routeQuoteId'];
    return RouteChangeQuote(
      pickupAddress: draft.pickupAddress,
      pickupPoint: draft.pickupPoint,
      destinationAddress: draft.destinationAddress,
      destinationPoint: draft.destinationPoint,
      stops: draft.stops,
      oldPriceKr: ride.price,
      newPriceKr: price is num ? price.toDouble() : ride.price,
      routeQuoteId:
          quoteId is String && quoteId.trim().isNotEmpty ? quoteId.trim() : null,
      expiresAt: DateTime.tryParse(response['expiresAt'] as String? ?? ''),
      newTotalMinor: (response['newTotalMinor'] as num?)?.round(),
      differenceMinor: (response['differenceMinor'] as num?)?.round(),
    );
  }

  /// Applies a previewed change and returns the updated, saved snapshot.
  Future<RideSnapshot> apply({
    required RideSnapshot ride,
    required RouteChangeQuote quote,
    Object? refundTo,
  }) async {
    final id = ride.rideId;
    if (id == null) throw const RouteChangeException(RouteChangeFailure.network);
    final refund = refundTo?.toString().split('.').last;
    final body = <String, dynamic>{
      ...quote.toRequest(),
      'routeChange': true,
      // ARCH-14: the change and the price the rider confirmed, together.
      if (quote.routeQuoteId != null) 'routeQuoteId': quote.routeQuoteId,
      'expectedTotalMinor': quote.newTotalMinor ?? (quote.newPriceKr * 100).round(),
      if (quote.differenceMinor != null)
        'expectedDifferenceMinor': quote.differenceMinor,
      // ARCH-9: the method by id. The label stays until the backend
      // contract is agreed.
      if (ride.paymentMethodId != null) 'paymentMethodId': ride.paymentMethodId,
      'paymentMethod': ride.paymentMethod,
      if (refund != null) 'refundTo': refund,
    };
    // ARCH-4: one key per confirmed change, the same on every send of it
    // (a retry after a timeout, a new controller, a reload), so the server
    // never charges or refunds the difference twice.
    final key = stableIdempotencyKey(
      'route-change',
      jsonEncode({'rideId': id, 'version': ride.version, ...body}),
    );
    final response = await _send(
      () => _api.patch('/api/v1/rides/$id', body: body, idempotencyKey: key),
    );
    final price = response['newPriceKr'];
    final newPrice = price is num ? price.toDouble() : quote.newPriceKr;
    final serverRide = response['ride'];
    final serverMax = serverRide is Map ? serverRide['maxOfferMinor'] : null;
    final updated = ride.copyWith(
      savedAt: DateTime.now(),
      pickupAddress: quote.pickupAddress,
      pickupLat: quote.pickupPoint.latitude,
      pickupLng: quote.pickupPoint.longitude,
      destinationAddress: quote.destinationAddress,
      destinationLat: quote.destinationPoint.latitude,
      destinationLng: quote.destinationPoint.longitude,
      stops: quote.stops,
      price: newPrice,
      // ARCH-20: a new route has a new offer ceiling.
      maxOfferMinor: serverMax is num && serverMax > 0
          ? serverMax.round()
          : ride.maxOfferMinor == null
          ? null
          : (FareRules.maximum(newPrice) * 100).round(),
    );
    await RideSnapshotStore.save(updated);
    return updated;
  }

  Future<GeoPoint> _locate(String address) async {
    final PlaceResult? found;
    try {
      found = await _geocoding.forward(address);
    } catch (_) {
      throw const RouteChangeException(RouteChangeFailure.network);
    }
    if (found == null) {
      throw const RouteChangeException(RouteChangeFailure.addressNotFound);
    }
    return found.point;
  }

  Future<Map<String, dynamic>> _send(
    Future<Map<String, dynamic>> Function() call,
  ) async {
    try {
      return await call();
    } on ApiError catch (error) {
      throw RouteChangeException(switch (error.code) {
        'PICKUP_LOCKED' => RouteChangeFailure.pickupLocked,
        'RIDE_FINISHED' => RouteChangeFailure.rideFinished,
        'ROUTE_QUOTE_EXPIRED' ||
        'ROUTE_QUOTE_NOT_FOUND' ||
        'ROUTE_QUOTE_MISMATCH' ||
        'ROUTE_QUOTE_PRICE_CHANGED' => RouteChangeFailure.priceChanged,
        _ => RouteChangeFailure.network,
      });
    } catch (_) {
      throw const RouteChangeException(RouteChangeFailure.network);
    }
  }
}
