import 'package:movera_rider/features/reservations/domain/reservation_status.dart';
import 'package:movera_rider/features/trips/domain/trip.dart';

class ReservationPlace {
  const ReservationPlace({
    required this.label,
    this.subtitle,
    this.lat,
    this.lng,
  });

  final String label;
  final String? subtitle;
  final double? lat;
  final double? lng;

  ReservationPlace copyWith({
    String? label,
    String? subtitle,
    double? lat,
    double? lng,
  }) {
    return ReservationPlace(
      label: label ?? this.label,
      subtitle: subtitle ?? this.subtitle,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
    );
  }

  Map<String, dynamic> toJson() => {
    'label': label,
    if (subtitle != null) 'subtitle': subtitle,
    if (lat != null) 'lat': lat,
    if (lng != null) 'lng': lng,
  };

  static ReservationPlace? tryParse(dynamic raw) {
    if (raw is String && raw.trim().isNotEmpty) {
      return ReservationPlace(label: raw.trim());
    }
    if (raw is! Map) return null;
    final map = Map<String, dynamic>.from(raw);
    final label = (map['label'] as String?)?.trim() ?? '';
    if (label.isEmpty) return null;
    return ReservationPlace(
      label: label,
      subtitle: map['subtitle'] as String?,
      lat: (map['lat'] as num?)?.toDouble(),
      lng: (map['lng'] as num?)?.toDouble(),
    );
  }
}

class ReservationDriver {
  const ReservationDriver({
    required this.firstName,
    this.rating,
    this.vehicle,
    this.plate,
    this.photoAsset,
  });

  final String firstName;
  final double? rating;
  final String? vehicle;
  final String? plate;
  final String? photoAsset;

  Map<String, dynamic> toJson() => {
    'firstName': firstName,
    if (rating != null) 'rating': rating,
    if (vehicle != null) 'vehicle': vehicle,
    if (plate != null) 'plate': plate,
    if (photoAsset != null) 'photoAsset': photoAsset,
  };

  static ReservationDriver? tryParse(dynamic raw) {
    if (raw is! Map) return null;
    final map = Map<String, dynamic>.from(raw);
    final name = (map['firstName'] as String?)?.trim() ?? '';
    if (name.isEmpty) return null;
    return ReservationDriver(
      firstName: name,
      rating: (map['rating'] as num?)?.toDouble(),
      vehicle: map['vehicle'] as String?,
      plate: map['plate'] as String?,
      photoAsset: map['photoAsset'] as String?,
    );
  }
}

class ReservationDraft {
  const ReservationDraft({
    required this.scheduledPickupAt,
    required this.pickup,
    required this.destination,
    required this.categoryId,
    required this.categoryName,
    required this.categoryImage,
    required this.price,
    required this.paymentMethod,
    this.passengerCount = 4,
    this.currency = 'SEK',
    this.estimatedDropoffAt,
    this.note,
    this.parentReservationId,
  });

  final DateTime scheduledPickupAt;
  final ReservationPlace pickup;
  final ReservationPlace destination;
  final String categoryId;
  final String categoryName;
  final String categoryImage;
  final int passengerCount;
  final double price;
  final String currency;
  final String paymentMethod;
  final DateTime? estimatedDropoffAt;
  final String? note;
  final String? parentReservationId;
}

class ReservationPriceChange {
  const ReservationPriceChange({required this.previous, required this.next});

  final double previous;
  final double next;

  double get delta => next - previous;

  bool get unchanged => delta.abs() < 0.5;

  String get summary {
    if (unchanged) return 'Price unchanged';
    final amount = delta.abs().toStringAsFixed(0);
    if (delta > 0) return 'Your updated ride costs $amount kr more.';
    return 'Your updated ride costs $amount kr less.';
  }
}

class ReservationPatch {
  const ReservationPatch({
    this.scheduledPickupAt,
    this.estimatedDropoffAt,
    this.pickup,
    this.destination,
    this.categoryId,
    this.categoryName,
    this.categoryImage,
    this.passengerCount,
    this.paymentMethod,
    this.price,
    this.note,
    this.status,
    this.driver,
    this.clearDriver = false,
  });

  final DateTime? scheduledPickupAt;
  final DateTime? estimatedDropoffAt;
  final ReservationPlace? pickup;
  final ReservationPlace? destination;
  final String? categoryId;
  final String? categoryName;
  final String? categoryImage;
  final int? passengerCount;
  final String? paymentMethod;
  final double? price;
  final String? note;
  final ReservationStatus? status;
  final ReservationDriver? driver;
  final bool clearDriver;
}

class Reservation {
  const Reservation({
    required this.reservationId,
    required this.createdAt,
    required this.scheduledPickupAt,
    required this.pickup,
    required this.destination,
    required this.categoryId,
    required this.categoryName,
    required this.categoryImage,
    required this.price,
    required this.paymentMethod,
    required this.status,
    this.passengerCount = 4,
    this.currency = 'SEK',
    this.estimatedDropoffAt,
    this.driver,
    this.note,
    this.cancellationReason,
    this.cancellationActor,
    this.cancelledAt,
    this.policyVersion,
    this.parentReservationId,
  });

  final String reservationId;
  final DateTime createdAt;
  final DateTime scheduledPickupAt;
  final DateTime? estimatedDropoffAt;
  final ReservationPlace pickup;
  final ReservationPlace destination;
  final String categoryId;
  final String categoryName;
  final String categoryImage;
  final int passengerCount;
  final double price;
  final String currency;
  final String paymentMethod;
  final ReservationStatus status;
  final ReservationDriver? driver;
  final String? note;
  final String? cancellationReason;
  final TripCancellationActor? cancellationActor;
  final DateTime? cancelledAt;
  final String? policyVersion;
  final String? parentReservationId;

  bool get driverAssigned => status.hasDriver && driver != null;

  bool get isSearchingDriver => status.isSearchingDriver;

  bool get revealsDriver => status.isDriverOnTheWay && driver != null;

  bool get hasPreferences => note != null && note!.trim().isNotEmpty;

  Reservation copyWith({
    DateTime? scheduledPickupAt,
    DateTime? estimatedDropoffAt,
    ReservationPlace? pickup,
    ReservationPlace? destination,
    String? categoryId,
    String? categoryName,
    String? categoryImage,
    int? passengerCount,
    double? price,
    String? currency,
    String? paymentMethod,
    ReservationStatus? status,
    ReservationDriver? driver,
    String? note,
    String? cancellationReason,
    TripCancellationActor? cancellationActor,
    DateTime? cancelledAt,
    String? policyVersion,
    String? parentReservationId,
    bool clearDriver = false,
  }) {
    return Reservation(
      reservationId: reservationId,
      createdAt: createdAt,
      scheduledPickupAt: scheduledPickupAt ?? this.scheduledPickupAt,
      estimatedDropoffAt: estimatedDropoffAt ?? this.estimatedDropoffAt,
      pickup: pickup ?? this.pickup,
      destination: destination ?? this.destination,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      categoryImage: categoryImage ?? this.categoryImage,
      passengerCount: passengerCount ?? this.passengerCount,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      driver: clearDriver ? null : (driver ?? this.driver),
      note: note ?? this.note,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      cancellationActor: cancellationActor ?? this.cancellationActor,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      policyVersion: policyVersion ?? this.policyVersion,
      parentReservationId: parentReservationId ?? this.parentReservationId,
    );
  }

  Map<String, dynamic> toJson() => {
    'reservationId': reservationId,
    'createdAt': createdAt.toIso8601String(),
    'scheduledPickupAt': scheduledPickupAt.toIso8601String(),
    if (estimatedDropoffAt != null)
      'estimatedDropoffAt': estimatedDropoffAt!.toIso8601String(),
    'pickup': pickup.toJson(),
    'destination': destination.toJson(),
    'categoryId': categoryId,
    'categoryName': categoryName,
    'categoryImage': categoryImage,
    'passengerCount': passengerCount,
    'price': price,
    'currency': currency,
    'paymentMethod': paymentMethod,
    'status': status.name,
    if (driver != null) 'driver': driver!.toJson(),
    if (note != null) 'note': note,
    if (cancellationReason != null) 'cancellationReason': cancellationReason,
    if (cancellationActor != null) 'cancellationActor': cancellationActor!.name,
    if (cancelledAt != null) 'cancelledAt': cancelledAt!.toIso8601String(),
    if (policyVersion != null) 'policyVersion': policyVersion,
    if (parentReservationId != null) 'parentReservationId': parentReservationId,
  };

  static Reservation? tryParse(dynamic raw) {
    if (raw is! Map) return null;
    try {
      final map = Map<String, dynamic>.from(raw);
      final id =
          (map['reservationId'] as String?)?.trim() ??
          (map['id'] as String?)?.trim() ??
          '';
      if (id.isEmpty) return null;
      final pickup = ReservationPlace.tryParse(map['pickup']);
      final destination = ReservationPlace.tryParse(map['destination']);
      if (pickup == null || destination == null) return null;
      final created = DateTime.tryParse(map['createdAt'] as String? ?? '');
      final pickupAt = DateTime.tryParse(
        map['scheduledPickupAt'] as String? ?? map['pickupAt'] as String? ?? '',
      );
      if (created == null || pickupAt == null) return null;
      return Reservation(
        reservationId: id,
        createdAt: created,
        scheduledPickupAt: pickupAt,
        estimatedDropoffAt: DateTime.tryParse(
          map['estimatedDropoffAt'] as String? ?? '',
        ),
        pickup: pickup,
        destination: destination,
        categoryId: (map['categoryId'] as String?) ?? 'movera',
        categoryName: (map['categoryName'] as String?) ?? 'Movera',
        categoryImage:
            (map['categoryImage'] as String?) ??
            'assets/images/rides/movera.webp',
        passengerCount: (map['passengerCount'] as num?)?.toInt() ?? 4,
        price: (map['price'] as num?)?.toDouble() ?? 0,
        currency: (map['currency'] as String?) ?? 'SEK',
        paymentMethod: (map['paymentMethod'] as String?) ?? 'Apple Pay',
        status: ReservationStatus.parse(map['status'] as String?),
        driver: ReservationDriver.tryParse(map['driver']),
        note: map['note'] as String?,
        cancellationReason: map['cancellationReason'] as String?,
        cancellationActor: _parseCancellationActor(
          map['cancellationActor'] as String?,
        ),
        cancelledAt: DateTime.tryParse(map['cancelledAt'] as String? ?? ''),
        policyVersion: map['policyVersion'] as String?,
        parentReservationId: map['parentReservationId'] as String?,
      );
    } catch (_) {
      return null;
    }
  }
}


TripCancellationActor? _parseCancellationActor(String? name) {
  if (name == null) return null;
  for (final actor in TripCancellationActor.values) {
    if (actor.name == name) return actor;
  }
  return null;
}
