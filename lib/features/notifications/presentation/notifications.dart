// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:movera_rider/core/constants/appassets.dart';
import 'package:movera_rider/core/constants/appcolors.dart';
import 'package:movera_rider/core/constants/appfontweight.dart';
import 'package:movera_rider/features/notifications/application/notifications_controller.dart';
import 'package:movera_rider/features/notifications/domain/notifications.dart';
import 'package:movera_rider/shared/design_system/movera_empty_state.dart';
import 'package:movera_rider/shared/widgets/custom_text_widget.dart';
import 'package:movera_rider/shared/widgets/responsive_size.dart';
import 'package:movera_rider/shared/widgets/sizedbox_extention.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = NotificationsController();

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
                  onPressed: () => Navigator.pop(context),
                  tooltip: 'Back',
                  icon: Icon(
                    Icons.arrow_back_rounded,
                    size: ResSize.h * 20,
                    color: AppColor.primary,
                  ),
                ),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: TextWidget(
                      text: 'Notification',
                      color: AppColor.primary,
                      fontSize: 18,
                      fontWeight: fwSemiBold,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(width: 48, height: 48),
              ],
            ),
            12.height,
            Expanded(
              child: StreamBuilder<List<AppNotification>>(
                stream: controller.watch(),
                initialData: controller.feed(),
                builder: (context, snapshot) {
                  final notifications = snapshot.data ?? const <AppNotification>[];
                  if (notifications.isEmpty) {
                    return const MoveraEmptyState(
                      icon: Icons.notifications_none_rounded,
                      title: "You're all caught up.",
                      message:
                          'Ride and account updates will appear here when they arrive.',
                    );
                  }
                  return ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: screenHorizPadding),
                    itemCount: notifications.length,
                    itemBuilder: (context, index) {
                      final notification = notifications[index];
                      return Padding(
                        padding: EdgeInsets.only(bottom: ResSize.h * 16),
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => controller.markRead(notification.messageId),
                          child: _buildNotificationCard(notification),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(AppNotification notification) {
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
            color: const Color(0xff000000).withValues(alpha: 0.08),
            blurRadius: 20,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
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
          Row(
            children: [
              TextWidget(
                text: notification.time,
                fontSize: 12,
                fontWeight: fwNormal,
                color: AppColor.subtitle,
              ),
              if (!notification.read) ...[
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
    );
  }
}
