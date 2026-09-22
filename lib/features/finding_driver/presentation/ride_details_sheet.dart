import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movera_rider/features/ride_booking/domain/ride_notes.dart';

class RideDetailsSheet extends StatelessWidget {
  const RideDetailsSheet({
    super.key,
    required this.pickupAddress,
    required this.destinationAddress,
    required this.rideType,
    required this.price,
    required this.paymentMethod,
    required this.notes,
    required this.canEditPickup,
    this.canEditDestination = false,
    this.allowCancel = true,
    required this.onEditPickup,
    required this.onEditDestination,
    required this.onCancelTrip,
  });

  final String pickupAddress;
  final String destinationAddress;
  final String rideType;
  final double price;
  final String paymentMethod;
  final RideNotes notes;
  final bool canEditPickup;
  final bool canEditDestination;
  final bool allowCancel;
  final VoidCallback onEditPickup;
  final VoidCallback onEditDestination;
  final VoidCallback onCancelTrip;

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.paddingOf(context).bottom;
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
                      color: const Color(0xFF1D252C),
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
            _Stop(
              pickup: true,
              address: pickupAddress,
              canEdit: canEditPickup,
              onEdit: onEditPickup,
            ),
            Container(
              width: 2,
              height: 18,
              margin: const EdgeInsets.only(left: 10),
              color: const Color(0xFFE7EBEE),
            ),
            _Stop(
              pickup: false,
              address: destinationAddress,
              canEdit: canEditDestination,
              onEdit: onEditDestination,
            ),
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
                          color: const Color(0xFF2D5878),
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

  Widget _kv(String left, String right, {bool muted = false}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            left,
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF1D252C),
            ),
          ),
        ),
        Text(
          right,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: muted ? const Color(0xFF5C656C) : const Color(0xFF1D252C),
          ),
        ),
      ],
    );
  }
}

class _Stop extends StatelessWidget {
  const _Stop({
    required this.pickup,
    required this.address,
    required this.canEdit,
    required this.onEdit,
  });

  final bool pickup;
  final String address;
  final bool canEdit;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          pickup ? Icons.radio_button_checked : Icons.square,
          size: pickup ? 18 : 14,
          color: const Color(0xFF1D252C),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            address,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF1D252C),
            ),
          ),
        ),
        if (canEdit)
          IconButton(
            onPressed: onEdit,
            tooltip: pickup ? 'Edit pickup' : 'Add stop',
            icon: Icon(
              pickup ? Icons.edit_outlined : Icons.add,
              size: 18,
              color: const Color(0xFF1D252C),
            ),
          ),
      ],
    );
  }
}
