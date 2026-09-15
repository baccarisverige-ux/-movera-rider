import 'package:flutter/material.dart';
import 'package:movera_rider/core/constants/appcolors.dart';
import 'package:movera_rider/core/constants/appfontweight.dart';
import 'package:movera_rider/features/ride_complete/application/ride_complete_controller.dart';
import 'package:movera_rider/shared/widgets/custom_text_widget.dart';
import 'package:movera_rider/shared/widgets/responsive_size.dart';
import 'package:movera_rider/shared/widgets/sizedbox_extention.dart';

class RideCompletedTripDetail extends StatelessWidget {
  const RideCompletedTripDetail({super.key, this.controller});

  final RideCompleteController? controller;

  @override
  Widget build(BuildContext context) {
    final trip = (controller ?? RideCompleteController()).receipt();
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenHorizPadding),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: ResSize.w * 20,
              vertical: ResSize.h * 9,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: const Color(0xffFAFAFA),
              border: Border.all(color: AppColor.border, width: 0.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextWidget(
                  text: 'Trip Details',
                  color: AppColor.title,
                  fontSize: 16,
                  fontWeight: fwSemiBold,
                ),
                12.height,
                if (trip == null) ...[
                  TextWidget(
                    text: 'Trip details unavailable',
                    color: AppColor.title,
                    fontSize: 14,
                    fontWeight: fwMedium,
                  ),
                  5.height,
                  TextWidget(
                    text: 'Receipt details will appear here when available.',
                    color: AppColor.subtitle,
                    fontSize: 13,
                    fontWeight: fwNormal,
                  ),
                  8.height,
                ] else ...[
                  _detailRow('Pickup location', trip.pickup),
                  8.height,
                  _detailRow('Destination', trip.destination),
                  8.height,
                  _detailRow('Total Payment', trip.total),
                  8.height,
                  _detailRow('Payment method', trip.method),
                  8.height,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: TextWidget(
            text: label,
            color: AppColor.title,
            fontSize: 14,
            fontWeight: fwMedium,
          ),
        ),
        12.width,
        Expanded(
          flex: 6,
          child: TextWidget(
            text: value,
            color: AppColor.subtitle,
            fontSize: 14,
            fontWeight: fwMedium,
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
