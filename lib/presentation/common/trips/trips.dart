// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:riding_app/constants/appcolors.dart';
import 'package:riding_app/constants/appfontweight.dart';
import 'package:riding_app/presentation/common/trips/trip%20detail/trip_detail.dart';
import 'package:riding_app/widgets/custom_text_widget.dart';
import 'package:riding_app/widgets/navigation_transition.dart';
import 'package:riding_app/widgets/responsive_size.dart';
import 'package:riding_app/widgets/sizedbox_extention.dart';

class TripsScreen extends StatelessWidget {
  final bool showBackIcon;
  const TripsScreen({super.key, this.showBackIcon = false});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            50.height,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                showBackIcon
                    ? IconButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: Icon(
                          Icons.arrow_back_rounded,
                          size: ResSize.h * 20,
                          color: AppColor.primary,
                        ),
                      )
                    : IconButton(
                        onPressed: () {},
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        icon: SizedBox(),
                      ),
                TextWidget(
                  text: "Your Trips",
                  fontSize: 18,
                  fontWeight: fwSemiBold,
                  color: AppColor.primary,
                ),
                IconButton(
                  onPressed: () {},
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  icon: SizedBox(),
                ),
              ],
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: screenHorizPadding),
              child: Column(
                children: [
                  32.height,
                  _buildTripCard(
                    date: "12 Aug, 7:45 PM",
                    price: "\$40.00",
                    location: "1901 Thorn St → 1901 Thorn...",
                    status: TripStatus.completed,
                    onTap: () {
                      Navigator.push(
                        context,
                        BottomToTopTransition(TripDetail()),
                      );
                    },
                  ),
                  12.height,
                  _buildTripCard(
                    date: "12 Aug, 7:45 PM",
                    price: "\$40.00",
                    location: "1901 Thorn St → 1901 Thorn...",
                    status: TripStatus.completed,
                    onTap: () {
                      Navigator.push(
                        context,
                        BottomToTopTransition(TripDetail()),
                      );
                    },
                  ),
                  12.height,
                  _buildTripCard(
                    date: "12 Aug, 7:45 PM",
                    price: "\$40.00",
                    location: "1901 Thorn St → 1901 Thorn...",
                    status: TripStatus.cancelled,
                    onTap: () {
                      Navigator.push(
                        context,
                        BottomToTopTransition(TripDetail()),
                      );
                    },
                  ),
                  12.height,
                  _buildTripCard(
                    date: "12 Aug, 7:45 PM",
                    price: "\$40.00",
                    location: "1901 Thorn St → 1901 Thorn...",
                    status: TripStatus.completed,
                    onTap: () {
                      Navigator.push(
                        context,
                        BottomToTopTransition(TripDetail()),
                      );
                    },
                  ),
                  12.height,
                  _buildTripCard(
                    date: "12 Aug, 7:45 PM",
                    price: "\$40.00",
                    location: "1901 Thorn St → 1901 Thorn...",
                    status: TripStatus.completedRed,
                    onTap: () {
                      Navigator.push(
                        context,
                        BottomToTopTransition(TripDetail()),
                      );
                    },
                  ),
                  12.height,
                  _buildTripCard(
                    date: "12 Aug, 7:45 PM",
                    price: "\$40.00",
                    location: "1901 Thorn St → 1901 Thorn...",
                    status: TripStatus.completed,
                    onTap: () {
                      Navigator.push(
                        context,
                        BottomToTopTransition(TripDetail()),
                      );
                    },
                  ),
                  50.height,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripCard({
    required String date,
    required String price,
    required String location,
    required TripStatus status,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: ResSize.w * 12,
          vertical: ResSize.h * 12,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColor.border, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextWidget(
                  text: date,
                  fontSize: 16,
                  fontWeight: fwMedium,
                  color: AppColor.primary,
                ),
                TextWidget(
                  text: price,
                  fontSize: 18,
                  fontWeight: fwSemiBold,
                  color: AppColor.primary,
                ),
              ],
            ),
            6.height,
            TextWidget(
              text: location,
              fontSize: 16,
              fontWeight: fwNormal,
              color: AppColor.subtitle,
            ),
            10.height,
            _buildStatusBadge(status),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(TripStatus status) {
    Color backgroundColor;
    Color textColor;
    String text;

    switch (status) {
      case TripStatus.completed:
        backgroundColor = AppColor.green.withOpacity(0.05);
        textColor = AppColor.green;
        text = "Completed";
        break;
      case TripStatus.cancelled:
        backgroundColor = AppColor.red.withOpacity(0.05);
        textColor = AppColor.red;
        text = "Cancelled";
        break;
      case TripStatus.completedRed:
        backgroundColor = AppColor.red.withOpacity(0.05);
        textColor = AppColor.red;
        text = "Completed";
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ResSize.w * 12,
        vertical: ResSize.h * 6,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(ResSize.w * 6),
      ),
      child: TextWidget(
        text: text,
        fontSize: 13,
        fontWeight: fwMedium,
        color: textColor,
      ),
    );
  }
}

enum TripStatus { completed, cancelled, completedRed }
