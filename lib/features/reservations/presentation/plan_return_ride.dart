import 'package:flutter/material.dart';
import 'package:movera_rider/app/di.dart';
import 'package:movera_rider/features/reservations/application/reservation_controller.dart';
import 'package:movera_rider/features/reservations/domain/reservation.dart';
import 'package:movera_rider/features/reservations/presentation/reservation_edit_sheets.dart';
import 'package:movera_rider/features/reservations/presentation/reservation_format.dart';
import 'package:movera_rider/features/reservations/presentation/reservation_widgets.dart';

class PlanReturnRidePage extends StatefulWidget {
  const PlanReturnRidePage({super.key, required this.origin, this.controller});

  final Reservation origin;
  final ReservationController? controller;

  @override
  State<PlanReturnRidePage> createState() => _PlanReturnRidePageState();
}

class _PlanReturnRidePageState extends State<PlanReturnRidePage> {
  late DateTime _when;
  late ReservationPlace _pickup;
  late ReservationPlace _destination;
  late String _payment;
  bool _saving = false;

  ReservationController get _reservations =>
      widget.controller ?? AppScope.instance.reservations;

  @override
  void initState() {
    super.initState();
    _when = widget.origin.scheduledPickupAt.add(const Duration(hours: 3));
    _pickup = widget.origin.destination;
    _destination = widget.origin.pickup;
    _payment = widget.origin.paymentMethod;
  }

  Future<void> _confirm() async {
    if (_saving) return;
    setState(() => _saving = true);
    final created = await _reservations.planReturn(
      widget.origin,
      scheduledPickupAt: _when,
      estimatedDropoffAt: widget.origin.estimatedDropoffAt == null
          ? null
          : _when.add(
              widget.origin.estimatedDropoffAt!.difference(
                widget.origin.scheduledPickupAt,
              ),
            ),
      pickup: _pickup,
      destination: _destination,
      paymentMethod: _payment,
    );
    if (!mounted) return;
    Navigator.pop(context, created);
  }

  @override
  Widget build(BuildContext context) {
    final origin = widget.origin;
    final top = MediaQuery.paddingOf(context).top;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          SizedBox(height: top + 4),
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded, color: kReservationInk),
              ),
            ],
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(22, 4, 22, 28),
              children: [
                Text(
                  'Plan a return ride',
                  style: reservationText(
                    30,
                    weight: FontWeight.w700,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'The reverse route is filled in. Confirm only when you are ready to create a new reservation.',
                  style: reservationText(
                    14,
                    color: kReservationMuted,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 22),
                ReservationRoutePreview(
                  pickup: _pickup.label,
                  destination: _destination.label,
                ),
                const SizedBox(height: 18),
                _row(
                  label: 'Pickup',
                  value: _pickup.label,
                  onEdit: () async {
                    final next = await showReservationPlaceSheet(
                      context,
                      title: 'Return pickup',
                      current: _pickup,
                    );
                    if (next != null) setState(() => _pickup = next);
                  },
                ),
                _row(
                  label: 'Destination',
                  value: _destination.label,
                  onEdit: () async {
                    final next = await showReservationPlaceSheet(
                      context,
                      title: 'Return destination',
                      current: _destination,
                    );
                    if (next != null) setState(() => _destination = next);
                  },
                ),
                _row(
                  label: 'Date and time',
                  value:
                      '${ReservationFormat.longDate(_when)} · ${ReservationFormat.time(_when)}',
                  onEdit: () async {
                    final next = await showReservationTimeSheet(
                      context,
                      initial: _when,
                    );
                    if (next != null) setState(() => _when = next);
                  },
                ),
                _row(label: 'Category', value: origin.categoryName),
                _row(
                  label: 'Payment',
                  value: _payment,
                  onEdit: () async {
                    final next = await showReservationPaymentSheet(
                      context,
                      current: _payment,
                    );
                    if (next != null) setState(() => _payment = next);
                  },
                ),
                _row(
                  label: 'Reserved price',
                  value: ReservationFormat.price(origin),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              8,
              20,
              16 + MediaQuery.paddingOf(context).bottom,
            ),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton(
                onPressed: _saving ? null : _confirm,
                style: FilledButton.styleFrom(
                  backgroundColor: kReservationCta,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: Text(
                  _saving ? 'Saving…' : 'Confirm return ride',
                  style: reservationText(
                    16,
                    weight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row({
    required String label,
    required String value,
    VoidCallback? onEdit,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: reservationText(12.5, color: kReservationMuted),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: reservationText(15.5, weight: FontWeight.w600),
                ),
              ],
            ),
          ),
          if (onEdit != null) ReservationEditChip(onTap: onEdit),
        ],
      ),
    );
  }
}
