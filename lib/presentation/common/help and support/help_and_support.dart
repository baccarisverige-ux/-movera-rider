// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:movera_rider/constants/appassets.dart';
import 'package:movera_rider/constants/appcolors.dart';
import 'package:movera_rider/constants/appfontweight.dart';
import 'package:movera_rider/widgets/custom_text_widget.dart';
import 'package:movera_rider/widgets/responsive_size.dart';
import 'package:movera_rider/widgets/sizedbox_extention.dart';

class HelpAndSupportScreen extends StatelessWidget {
  const HelpAndSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.secondary,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            55.height,
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
                  text: "Help & Support",
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

            32.height,

            // Issues List
            Container(
              margin: EdgeInsets.symmetric(horizontal: screenHorizPadding),
              padding: EdgeInsets.symmetric(horizontal: ResSize.w * 16),
              decoration: BoxDecoration(
                color: AppColor.secondary,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    offset: const Offset(0, 5),
                    color: Color(0xff000000).withOpacity(0.08),
                    blurRadius: 20,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildIssueItem(
                    "I was overcharged",
                    onTap: () {
                      // Handle tap
                    },
                  ),
                  _buildIssueItem(
                    "I left an item in the car",
                    onTap: () {
                      // Handle tap
                    },
                  ),
                  _buildIssueItem(
                    "Driver was late",
                    onTap: () {
                      // Handle tap
                    },
                  ),
                  _buildIssueItem(
                    "Cancelation fee charged",
                    onTap: () {
                      // Handle tap
                    },
                  ),
                  _buildIssueItem(
                    "Payment issue",
                    onTap: () {
                      // Handle tap
                    },
                    showDivider: false,
                  ),
                ],
              ),
            ),

            24.height,

            // Contact Options Section
            Padding(
              padding: EdgeInsets.symmetric(horizontal: screenHorizPadding),
              child: TextWidget(
                text: "Contact options",
                fontSize: 20,
                fontWeight: fwSemiBold,
                color: AppColor.primary,
              ),
            ),

            16.height,

            // Contact Cards
            Padding(
              padding: EdgeInsets.symmetric(horizontal: ResSize.w * 20),
              child: Column(
                children: [
                  _buildContactCard(
                    icon: AppAssets.chatOutl,
                    title: "Chat with support",
                    onTap: () {
                      // Handle chat
                    },
                  ),

                  16.height,

                  _buildContactCard(
                    icon: AppAssets.email,
                    title: "Email Support",
                    onTap: () {
                      // Handle email
                    },
                  ),

                  16.height,

                  _buildContactCard(
                    icon: AppAssets.callOutl,
                    title: "Call with support",
                    onTap: () {
                      // Handle call
                    },
                  ),
                ],
              ),
            ),

            40.height,
          ],
        ),
      ),
    );
  }

  Widget _buildIssueItem(
    String title, {
    required VoidCallback onTap,
    bool showDivider = true,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            color: Colors.transparent,
            padding: EdgeInsets.symmetric(vertical: ResSize.h * 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: TextWidget(
                    text: title,
                    fontSize: 16,
                    fontWeight: fwNormal,
                    color: AppColor.subtitle,
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: AppColor.subtitle,
                  size: ResSize.h * 24,
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(color: const Color(0xFFE0E0E0), thickness: 1, height: 1),
      ],
    );
  }

  Widget _buildContactCard({
    required String icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: ResSize.w * 14,
          vertical: ResSize.h * 16,
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
            Image.asset(icon, color: AppColor.subtitle, height: ResSize.h * 22),
            16.width,
            Expanded(
              child: TextWidget(
                text: title,
                fontSize: 16,
                fontWeight: fwNormal,
                color: AppColor.subtitle,
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppColor.subtitle,
              size: ResSize.h * 24,
            ),
          ],
        ),
      ),
    );
  }
}
