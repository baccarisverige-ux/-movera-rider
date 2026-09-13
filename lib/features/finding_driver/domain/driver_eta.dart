import 'dart:math';

import 'package:movera_rider/features/ride_booking/domain/ride_status.dart';

class DriverEta {
  const DriverEta({
    this.seconds,
    this.distanceMeters,
    this.locationAt,
    this.latitude,
    this.longitude,
    this.stale = false,
  });

  final int? seconds;
  final double? distanceMeters;
  final DateTime? locationAt;
  final double? latitude;
  final double? longitude;
  final bool stale;

  static const staleAfter = Duration(seconds: 25);

  static double metersBetween(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const radius = 6371000.0;
    final p1 = lat1 * pi / 180;
    final p2 = lat2 * pi / 180;
    final dLat = (lat2 - lat1) * pi / 180;
    final dLng = (lng2 - lng1) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(p1) * cos(p2) * sin(dLng / 2) * sin(dLng / 2);
    return 2 * radius * atan2(sqrt(a), sqrt(1 - a));
  }

  static int secondsForDistance(double meters) {
    const urbanMetersPerSecond = 8.3;
    return (meters / urbanMetersPerSecond).round().clamp(20, 1800);
  }

  factory DriverEta.fromFix({
    required double latitude,
    required double longitude,
    required double pickupLat,
    required double pickupLng,
    required DateTime locationAt,
    int? etaSeconds,
    DateTime? now,
    RideStatus? status,
  }) {
    final clock = now ?? DateTime.now();
    final distance = metersBetween(latitude, longitude, pickupLat, pickupLng);
    final stale = clock.difference(locationAt) > staleAfter;
    final seconds = etaSeconds ?? secondsForDistance(distance);
    return DriverEta(
      seconds: seconds,
      distanceMeters: distance,
      locationAt: locationAt,
      latitude: latitude,
      longitude: longitude,
      stale: stale,
    );
  }

  String headline({RideStatus status = RideStatus.driverAssigned}) {
    if (status == RideStatus.driverWaiting) return 'Driver has arrived';
    if (stale) return 'Updating driver location…';
    final distance = distanceMeters;
    if (distance != null && distance < 50) return 'Driver has arrived';
    if (distance != null && distance < 180) return 'Driver is almost there';
    final eta = seconds;
    if (eta == null) return 'Driver is on the way';
    if (eta < 60) return 'Driver is almost there';
    final minutes = (eta / 60).ceil();
    return 'Pickup in $minutes min';
  }

  String? subtitle({
    String? firstName,
    RideStatus status = RideStatus.driverAssigned,
  }) {
    if (stale) return 'Waiting for a fresh location update.';
    if (headline(status: status).contains('arrived')) {
      return firstName == null ? 'Your driver is at the pickup.' : '$firstName is at the pickup.';
    }
    if (firstName == null || firstName.isEmpty) return 'Leave now to meet your driver.';
    return 'Leave now to meet $firstName';
  }
}
