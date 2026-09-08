import 'package:flutter/material.dart';
import 'package:movera/constants/appassets.dart';
import 'package:movera/constants/appcolors.dart';
import 'package:movera/constants/appfontweight.dart';
import 'package:movera/presentation/rider/schedule%20ride/schedule_ride.dart';
import 'package:movera/widgets/custom_text_widget.dart';
import 'package:movera/widgets/navigation_transition.dart';
import 'package:movera/widgets/responsive_size.dart';
import 'package:movera/widgets/sizedbox_extention.dart';

class ScheduleRideAppBar extends StatelessWidget {
  const ScheduleRideAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: Row(
        children: [
          16.width,
          InkWell(
            onTap: () {
              Navigator.pop(context);
            },
            child: Container(
              height: ResSize.h * 30,
              width: ResSize.w * 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColor.border, width: 0.3),
                boxShadow: [
                  BoxShadow(
                    // ignore: deprecated_member_use
                    color: Color(0xff999999).withOpacity(0.1),
                    blurRadius: 40,
                    offset: const Offset(0, 4),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  Icons.arrow_back_ios_rounded,
                  color: AppColor.title,
                  size: ResSize.h * 16,
                ),
              ),
            ),
          ),
        ],
      ),
      title: TextWidget(
        text: "Schedule Rides",
        color: AppColor.title,
        fontSize: 16,
        fontWeight: fwSemiBold,
      ),
      centerTitle: true,
      actions: [
        IconButton(
          onPressed: () {
            Navigator.push(
              context,
              RightToLeftTransition(const ScheduleRide()),
            );
          },
          icon: Image.asset(AppAssets.calender, height: ResSize.h * 28),
        ),
        8.width,
      ],
    );
  }
}
