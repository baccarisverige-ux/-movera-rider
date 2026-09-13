import 'package:movera_rider/features/reservations/domain/reservation.dart';
import 'package:movera_rider/features/reservations/domain/reservation_status.dart';

abstract final class ReservationFormat {
  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static String price(Reservation ride) {
    return 'kr ${ride.price.toStringAsFixed(0)}';
  }

  static String _weekday(DateTime when) => _weekdays[when.weekday - 1];

  static String _month(DateTime when) => _months[when.month - 1];

  static String time(DateTime when) {
    final hour = when.hour.toString().padLeft(2, '0');
    final minute = when.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  static String weekdayDate(DateTime when) {
    return '${_weekday(when)}, ${when.day} ${_month(when)}';
  }

  static String longDate(DateTime when) {
    return '${_weekday(when)}, ${when.day} ${_month(when)} ${when.year}';
  }

  static String reservedHeadline(DateTime when) {
    return 'Your ride is reserved for ${weekdayDate(when)} at ${time(when)}';
  }

  static String scheduledReady(DateTime when) {
    return "We'll keep your reservation ready for ${weekdayDate(when)} at ${time(when)}.";
  }

  static const String notifyWhenAssigned =
      "We'll notify you as soon as a driver is assigned.";

  static String kr(double amount) => 'kr ${amount.toStringAsFixed(0)}';

  static String remainingCompact(DateTime when, {DateTime? now}) {
    final left = when.difference(now ?? DateTime.now());
    if (left.inSeconds < 60) return 'Now';
    final days = left.inDays;
    final hours = left.inHours % 24;
    final minutes = left.inMinutes % 60;
    if (days > 0) {
      return hours > 0 ? '${days}d ${hours}h' : '${days}d';
    }
    if (hours > 0) {
      return minutes > 0 ? '${hours}h ${minutes}m' : '${hours}h';
    }
    return '${minutes}m';
  }

  static ({String primary, String? secondary}) remainingParts(
    DateTime when, {
    DateTime? now,
  }) {
    final left = when.difference(now ?? DateTime.now());
    if (left.inSeconds < 60) {
      return (primary: 'Now', secondary: null);
    }
    final days = left.inDays;
    final hours = left.inHours % 24;
    final minutes = left.inMinutes % 60;
    if (days > 0) {
      return (primary: '${days}d', secondary: hours > 0 ? '${hours}h' : null);
    }
    if (hours > 0) {
      return (
        primary: '${hours}h',
        secondary: minutes > 0 ? '${minutes}m' : null,
      );
    }
    return (primary: '${minutes}m', secondary: null);
  }

  static String shortPlace(String raw) {
    final clean = raw.trim();
    if (clean.isEmpty) return clean;
    final parts = clean
        .split(',')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.length <= 2) return clean;
    return '${parts[0]}, ${parts[1]}';
  }

  static String cardDate(DateTime when) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(when.year, when.month, when.day);
    if (day == today) return 'Today, ${when.day} ${_month(when)}';
    if (day == today.add(const Duration(days: 1))) {
      return 'Tomorrow, ${when.day} ${_month(when)}';
    }
    return weekdayDate(when);
  }

  static String pickupAt(DateTime when) => 'Pickup at ${time(when)}';

  static String dropoffAt(DateTime when) => 'Dropoff around ${time(when)}';

  static String statusTitle(Reservation ride) {
    switch (ride.status) {
      case ReservationStatus.cancelled:
        return 'Reservation cancelled';
      case ReservationStatus.completed:
        return 'Ride completed';
      case ReservationStatus.driverAssigned:
      case ReservationStatus.driverEnRoute:
        return 'Driver assigned';
      case ReservationStatus.driverArrived:
        return 'Driver has arrived';
      case ReservationStatus.inProgress:
        return 'Ride in progress';
      case ReservationStatus.scheduled:
      case ReservationStatus.driverAssignmentPending:
        return 'Reservation confirmed';
    }
  }

  static String statusBody(
    Reservation ride, {
    required String assignmentDisclaimer,
  }) {
    switch (ride.status) {
      case ReservationStatus.cancelled:
        return ride.cancellationReason == null ||
                ride.cancellationReason!.isEmpty
            ? 'This reservation was cancelled. Details stay in your ride history.'
            : 'Cancelled. ${ride.cancellationReason}';
      case ReservationStatus.completed:
        return 'This scheduled ride is complete.';
      case ReservationStatus.driverAssigned:
      case ReservationStatus.driverEnRoute:
      case ReservationStatus.driverArrived:
      case ReservationStatus.inProgress:
        final driver = ride.driver;
        if (driver == null) {
          return 'A driver has been assigned to this reservation.';
        }
        return '${driver.firstName} is assigned to this reservation.';
      case ReservationStatus.scheduled:
      case ReservationStatus.driverAssignmentPending:
        return assignmentDisclaimer;
    }
  }

  static String driverBadge(Reservation ride) {
    if (ride.driverAssigned) return 'Driver assigned';
    return 'Driver pending';
  }

  static String historyWhen(Reservation ride) {
    return '${cardDate(ride.scheduledPickupAt)} · ${time(ride.scheduledPickupAt)}';
  }
}
