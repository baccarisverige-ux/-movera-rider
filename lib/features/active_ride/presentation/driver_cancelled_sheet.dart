import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movera_rider/shared/design_system/movera_sheet.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

const Color _ink = Color(0xFF1D252C);
const Color _muted = Color(0xFF5C656C);
const Color _accent = Color(0xFF2D5878);

/// Shown when the assigned driver drops the ride before pickup.
///
/// The rider's trip is not over — dispatch looks again — so this explains what
/// happened and gets out of the way, rather than asking them to rebook.
Future<void> showDriverCancelledSheet(
  BuildContext context, {
  String? driverName,
}) {
  return MoveraSheet.show<void>(
    context: context,
    builder: (_) => DriverCancelledSheet(driverName: driverName),
  );
}

class DriverCancelledSheet extends StatelessWidget {
  const DriverCancelledSheet({super.key, this.driverName});

  final String? driverName;

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.paddingOf(context).bottom;
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
                    color: Color(0xFFF7E7E5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_off_outlined,
                    color: Color(0xFF9B3B34),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    driverName == null
                        ? 'Your driver cancelled'
                        : '$driverName cancelled',
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
              'Your ride is still on. We are finding you another driver now — '
              'your pickup, destination and price stay the same.',
              style: GoogleFonts.poppins(fontSize: 14, color: _muted),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(
                  backgroundColor: _accent,
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'Keep searching',
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
