import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movera_rider/features/ride_booking/domain/ride_notes.dart';
import 'package:movera_rider/features/ride_booking/domain/route_stop.dart';

/// The route and the money of the current ride, with a Change link on
/// every part the rider may still change at this stage.
class RideDetailsSheet extends StatelessWidget {
  const RideDetailsSheet({
    super.key,
    required this.pickupAddress,
    required this.destinationAddress,
    this.stops = const <RouteStop>[],
    required this.rideType,
    required this.price,
    required this.paymentMethod,
    required this.notes,
    required this.canEditPickup,
    this.canEditDestination = false,
    this.canAddStop = false,
    this.maxStops = 3,
    this.allowCancel = true,
    required this.onEditPickup,
    required this.onEditDestination,
    this.onAddStop,
    this.onRemoveStop,
    required this.onCancelTrip,
  });

  final String pickupAddress;
  final String destinationAddress;
  final List<RouteStop> stops;
  final String rideType;
  final double price;
  final String paymentMethod;
  final RideNotes notes;
  final bool canEditPickup;
  final bool canEditDestination;
  final bool canAddStop;
  final int maxStops;
  final bool allowCancel;
  final VoidCallback onEditPickup;
  final VoidCallback onEditDestination;
  final VoidCallback? onAddStop;
  final void Function(int index)? onRemoveStop;
  final VoidCallback onCancelTrip;

  static const Color _ink = Color(0xFF1D252C);
  static const Color _muted = Color(0xFF5C656C);
  static const Color _accent = Color(0xFF2D5878);
  static const Color _line = Color(0xFFE7EBEE);

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.paddingOf(context).bottom;
    final stopsLeft = canAddStop && stops.length < maxStops;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 8, 20, 16 + inset),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const SizedBox(width: 48),
                Expanded(
                  child: Text(
                    'Ride details',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _ink,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                  tooltip: 'Close',
                ),
              ],
            ),
            _RouteRow(
              key: const ValueKey('ride-details-pickup'),
              kind: _RowKind.pickup,
              address: pickupAddress,
              action: canEditPickup ? 'Change' : null,
              onAction: onEditPickup,
            ),
            for (var i = 0; i < stops.length; i++) ...[
              _connector(),
              _RouteRow(
                key: ValueKey('ride-details-stop-$i'),
                kind: _RowKind.stop,
                label: 'Stop ${i + 1}',
                address: stops[i].address,
                action: canEditDestination ? 'Remove' : null,
                onAction: () => onRemoveStop?.call(i),
              ),
            ],
            _connector(),
            _RouteRow(
              key: const ValueKey('ride-details-destination'),
              kind: _RowKind.destination,
              address: destinationAddress,
              action: canEditDestination ? 'Change' : null,
              onAction: onEditDestination,
            ),
            if (stopsLeft) ...[
              const SizedBox(height: 10),
              TextButton.icon(
                key: const ValueKey('ride-details-add-stop'),
                onPressed: onAddStop,
                style: TextButton.styleFrom(
                  foregroundColor: _accent,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(Icons.add_rounded, size: 20),
                label: Text(
                  'Add stop',
                  style: GoogleFonts.poppins(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            if (!canEditPickup && canEditDestination) ...[
              const SizedBox(height: 6),
              Text(
                'Your driver is told about every change.',
                style: GoogleFonts.poppins(fontSize: 12.5, color: _muted),
              ),
            ],
            const SizedBox(height: 16),
            _kv(rideType, '${price.toStringAsFixed(0)} kr'),
            const SizedBox(height: 8),
            _kv('Payment', paymentMethod),
            if (!notes.isEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final label in notes.selected)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F6FB),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        label,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _accent,
                        ),
                      ),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            if (allowCancel) ...[
              SizedBox(
                width: double.infinity,
                height: 52,
                child: TextButton(
                  onPressed: onCancelTrip,
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFFF4F5F6),
                    foregroundColor: const Color(0xFFB42318),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Cancel trip',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
            SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF11181D),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Close',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _connector() => Container(
    width: 2,
    height: 16,
    margin: const EdgeInsets.only(left: 10),
    color: _line,
  );

  Widget _kv(String left, String right, {bool muted = false}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            left,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: _ink,
            ),
          ),
        ),
        Text(
          right,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: muted ? _muted : _ink,
          ),
        ),
      ],
    );
  }
}

enum _RowKind { pickup, stop, destination }

class _RouteRow extends StatelessWidget {
  const _RouteRow({
    super.key,
    required this.kind,
    required this.address,
    this.label,
    this.action,
    required this.onAction,
  });

  final _RowKind kind;
  final String address;
  final String? label;
  final String? action;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final icon = switch (kind) {
      _RowKind.pickup => const Icon(
        Icons.radio_button_checked,
        size: 18,
        color: Color(0xFF079A60),
      ),
      _RowKind.stop => Container(
        width: 14,
        height: 14,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: RideDetailsSheet._ink, width: 2),
        ),
      ),
      _RowKind.destination => const Icon(
        Icons.square,
        size: 14,
        color: Color(0xFF1769E8),
      ),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 22, child: Center(child: icon)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (label != null)
                  Text(
                    label!,
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: RideDetailsSheet._muted,
                    ),
                  ),
                Text(
                  address,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: RideDetailsSheet._ink,
                  ),
                ),
              ],
            ),
          ),
          if (action != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: RideDetailsSheet._accent,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 36),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                action!,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
