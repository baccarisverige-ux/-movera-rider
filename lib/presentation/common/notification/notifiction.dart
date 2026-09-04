// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:riding_app/constants/appassets.dart';
import 'package:riding_app/constants/appcolors.dart';
import 'package:riding_app/constants/appfontweight.dart';
import 'package:riding_app/widgets/custom_text_widget.dart';
import 'package:riding_app/widgets/responsive_size.dart';
import 'package:riding_app/widgets/sizedbox_extention.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Sample notification data
    final List<NotificationItem> notifications = [
      NotificationItem(
        icon: Icons.directions_car,
        title: "Driver assigned",
        subtitle: "mac is on the way",
        time: "2min ago",
        isRead: false,
      ),
      NotificationItem(
        icon: Icons.directions_car,
        title: "Your Ride has started",
        subtitle: "Have a safe trip",
        time: "2min ago",
        isRead: false,
      ),
      NotificationItem(
        icon: Icons.check_circle_outline,
        title: "Trip Completed",
        subtitle: "\$10.00 Paid",
        time: "2min ago",
        isRead: false,
      ),
      NotificationItem(
        icon: Icons.directions_car,
        title: "Driver assigned",
        subtitle: "mac is on the way",
        time: "2min ago",
        isRead: true,
      ),
      NotificationItem(
        icon: Icons.directions_car,
        title: "Driver assigned",
        subtitle: "mac is on the way",
        time: "2min ago",
        isRead: true,
      ),
      NotificationItem(
        icon: Icons.directions_car,
        title: "Driver assigned",
        subtitle: "mac is on the way",
        time: "2min ago",
        isRead: true,
      ),
      NotificationItem(
        icon: Icons.directions_car,
        title: "Driver assigned",
        subtitle: "mac is on the way",
        time: "2min ago",
        isRead: true,
      ),
      NotificationItem(
        icon: Icons.directions_car,
        title: "Driver assigned",
        subtitle: "mac is on the way",
        time: "2min ago",
        isRead: true,
      ),
      NotificationItem(
        icon: Icons.directions_car,
        title: "Driver assigned",
        subtitle: "mac is on the way",
        time: "2min ago",
        isRead: true,
      ),
    ];

    return Scaffold(
      backgroundColor: AppColor.secondary,
      body: SizedBox(
        child: Column(
          children: [
            50.height,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: Icon(
                    Icons.arrow_back_rounded,
                    size: ResSize.h * 20,
                    color: AppColor.primary,
                  ),
                ),
                TextWidget(
                  text: "Notification",
                  color: AppColor.primary,
                  fontSize: 18,
                  fontWeight: fwSemiBold,
                ),
                IconButton(
                  onPressed: () {},
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  icon: SizedBox(),
                ),
              ],
            ),

            12.height,

            // Notifications List
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: screenHorizPadding),
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: ResSize.h * 16),
                    child: _buildNotificationCard(notifications[index]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(NotificationItem notification) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ResSize.w * 4,
        vertical: ResSize.h * 4,
      ),
      decoration: BoxDecoration(
        color: AppColor.secondary,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, 5),
            color: const Color(0xff000000).withOpacity(0.08),
            blurRadius: 20,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon Container
          Container(
            width: ResSize.w * 52,
            height: ResSize.w * 52,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Image.asset(
                AppAssets.standard,
                color: AppColor.subtitle,
                height: ResSize.h * 24,
              ),
            ),
          ),

          8.width,

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextWidget(
                  text: notification.title,
                  fontSize: 16,
                  fontWeight: fwMedium,
                  color: AppColor.primary,
                ),
                2.height,
                TextWidget(
                  text: notification.subtitle,
                  fontSize: 14,
                  fontWeight: fwNormal,
                  color: AppColor.subtitle,
                ),
              ],
            ),
          ),

          8.width,

          // Time and Read Indicator
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  TextWidget(
                    text: notification.time,
                    fontSize: 12,
                    fontWeight: fwNormal,
                    color: AppColor.subtitle,
                  ),
                  if (!notification.isRead) ...[
                    4.width,
                    Container(
                      width: ResSize.w * 8,
                      height: ResSize.w * 8,
                      decoration: BoxDecoration(
                        color: AppColor.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class NotificationItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final String time;
  final bool isRead;

  NotificationItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.isRead,
  });
}
