import 'package:flutter/material.dart';
import 'package:movera_rider/core/constants/appcolors.dart';
import 'package:movera_rider/core/constants/appfontweight.dart';
import 'package:movera_rider/features/ride_complete/application/ride_complete_controller.dart';
import 'package:movera_rider/shared/design_system/movera_empty_state.dart';
import 'package:movera_rider/shared/widgets/custom_text_widget.dart';
import 'package:movera_rider/shared/widgets/responsive_size.dart';
import 'package:movera_rider/shared/widgets/sizedbox_extention.dart';

/// Riders recognise a trip by when it happened, not by a database key. Keep a
/// short tail so support can still match it to the full id.
String _reference(String rideId) {
  final trimmed = rideId.trim();
  if (trimmed.isEmpty) return '';
  final tail = trimmed.length <= 6
      ? trimmed
      : trimmed.substring(trimmed.length - 6);
  return '#${tail.toUpperCase()}';
}

class RideCompletedDriverInfo extends StatelessWidget {
  const RideCompletedDriverInfo({super.key});

  @override
  Widget build(BuildContext context) {
    final driver = RideCompleteController().driver();
    if (driver == null) {
      return const MoveraEmptyState(
        icon: Icons.person_search_outlined,
        title: 'Driver details unavailable',
        message:
            'Verified driver and vehicle information will appear here when it is available for this ride.',
        compact: true,
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenHorizPadding),
      child: Column(
        children: [
          Container(
            height: ResSize.h * 74,
            width: ResSize.h * 74,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xFFE8F0F6),
              shape: BoxShape.circle,
            ),
            child: TextWidget(
              text: driver.name.trim().isEmpty
                  ? '?'
                  : driver.name.trim().substring(0, 1).toUpperCase(),
              color: const Color(0xFF2D5878),
              fontSize: 28,
              fontWeight: fwSemiBold,
            ),
          ),
          14.height,
          Center(
            child: TextWidget(
              text: driver.name,
              color: AppColor.title,
              fontSize: 20,
              fontWeight: fwSemiBold,
            ),
          ),
          2.height,
          Center(
            child: TextWidget(
              text: driver.vehicle,
              color: AppColor.title,
              fontSize: 14,
              fontWeight: fwMedium,
            ),
          ),
          24.height,
          Row(
            children: [
              Expanded(
                child: TextWidget(
                  text: 'Trip completed',
                  color: AppColor.title,
                  fontSize: 14,
                  fontWeight: fwMedium,
                ),
              ),
              const SizedBox(width: 12),
              // A raw ride id is for support, not for the rider, and a full
              // one ran straight through its own label. Show a short reference.
              Flexible(
                child: TextWidget(
                  text: _reference(driver.rideNumber),
                  color: AppColor.subtitle,
                  fontSize: 14,
                  fontWeight: fwMedium,
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
          8.height,
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextWidget(
                  text: 'Date & Time',
                  color: AppColor.title,
                  fontSize: 14,
                  fontWeight: fwMedium,
                ),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: TextWidget(
                  text: driver.completedAt,
                  color: AppColor.subtitle,
                  fontSize: 14,
                  fontWeight: fwMedium,
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
          8.height,
        ],
      ),
    );
  }
}
