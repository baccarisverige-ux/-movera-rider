import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movera_rider/features/ride_booking/domain/entities/matched_driver.dart';
import 'package:movera_rider/shared/design_system/movera_sheet.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

const Color _ink = Color(0xFF1D252C);
const Color _muted = Color(0xFF5C656C);
const Color _line = Color(0xFFE7EBEE);
const Color _accent = Color(0xFF2D5878);

/// Announced once, when the driver reaches the pickup point.
///
/// The rider may have the phone in a pocket, so this has to interrupt rather
/// than quietly change a line of text on the map.
Future<void> showDriverArrivedSheet(
  BuildContext context, {
  MatchedDriver? driver,
  Future<void> Function()? onWay,
}) {
  return MoveraSheet.show<void>(
    context: context,
    builder: (_) => DriverArrivedSheet(
      driver: driver,
      onWay: onWay,
    ),
  );
}

class DriverArrivedSheet extends StatelessWidget {
  const DriverArrivedSheet({
    super.key,
    this.driver,
    this.onWay,
  });

  final MatchedDriver? driver;
  final Future<void> Function()? onWay;

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.paddingOf(context).bottom;
    final name = driver?.firstName;
    final plate = driver?.plate;
    final vehicle = driver?.vehicleLabel;

    return PointerInterceptor(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + inset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8F0F6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.directions_car_filled_outlined,
                    color: _accent,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    name == null
                        ? 'Your driver is here'
                        : '$name is here',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: _ink,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Your driver is waiting at the pickup point.',
              style: GoogleFonts.poppins(fontSize: 14, color: _muted),
            ),
            if (plate != null && plate.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _line),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plate,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: _ink,
                        letterSpacing: 1.5,
                      ),
                    ),
                    if (vehicle != null && vehicle.isNotEmpty)
                      Text(
                        vehicle,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: _muted,
                        ),
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () async {
                  await onWay?.call();
                  if (context.mounted) Navigator.of(context).pop();
                },
                style: FilledButton.styleFrom(
                  backgroundColor: _accent,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  "I'm on the way",
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
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
}
