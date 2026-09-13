import 'package:flutter/material.dart';
import 'package:movera_rider/features/reservations/application/reservation_controller.dart';
import 'package:movera_rider/features/reservations/domain/reservation.dart';
import 'package:movera_rider/features/ride_selection/presentation/select_ride.dart';

/// Return-ride booking reuses the shared category selector.
/// A new reservation is created only after the rider confirms.
class PlanReturnRidePage extends StatelessWidget {
  const PlanReturnRidePage({
    super.key,
    required this.origin,
    this.controller,
    this.onScheduled,
  });

  final Reservation origin;
  final ReservationController? controller;
  final Future<void> Function(BuildContext context, String reservationId)?
  onScheduled;

  @override
  Widget build(BuildContext context) {
    return SelectRide.forReturnRide(
      origin,
      reservations: controller,
      onScheduled: onScheduled,
    );
  }
}
