// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:riding_app/constants/appcolors.dart';
import 'package:riding_app/constants/appfontweight.dart';
import 'package:riding_app/widgets/custom_text_widget.dart';
import 'package:riding_app/widgets/responsive_size.dart';
import 'package:riding_app/widgets/sizedbox_extention.dart';
import 'package:riff_switch/riff_switch.dart';

class DriverSettingsScreen extends StatefulWidget {
  const DriverSettingsScreen({super.key});

  @override
  State<DriverSettingsScreen> createState() => _DriverSettingsScreenState();
}

class _DriverSettingsScreenState extends State<DriverSettingsScreen> {
  bool isAutoAcceptEnabled = false;
  bool val1 = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.secondary,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                  text: "Settings",
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

            // Availability Section
            Padding(
              padding: EdgeInsets.symmetric(horizontal: screenHorizPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextWidget(
                    text: "Avaliablity",
                    fontSize: 18,
                    fontWeight: fwSemiBold,
                    color: AppColor.primary,
                  ),
                  12.height,

                  // Auto Accept Rides Card
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: ResSize.w * 14,
                      vertical: ResSize.h * 10,
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextWidget(
                          text: "Auto accept rides",
                          fontSize: 16,
                          fontWeight: fwMedium,
                          color: AppColor.primary,
                        ),
                        Transform.scale(
                          scale: 0.8,
                          child: RiffSwitch(
                            trackColor: WidgetStatePropertyAll(
                              Color(0xffBEBEBE),
                            ),
                            activeTrackColor: Color(
                              0xff0DC216,
                            ).withOpacity(0.2),
                            value: val1,
                            onChanged: (value) => setState(() {
                              val1 = value;
                            }),
                            type: RiffSwitchType.cupertino,
                            inactiveThumbColor: Colors.white,
                            inactiveTrackColor: Color(0xffBEBEBE),
                            activeColor: Color(0xff0DC216),
                          ),
                        ),
                      ],
                    ),
                  ),

                  24.height,

                  // Preferences Section
                  TextWidget(
                    text: "Preferences",
                    fontSize: 18,
                    fontWeight: fwSemiBold,
                    color: AppColor.primary,
                  ),

                  12.height,

                  // Preferences Card
                  Container(
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
                    child: Column(
                      children: [
                        // Preferred Area
                        _buildPreferenceItem(
                          title: "Preferred area",
                          onTap: () {
                            // Handle tap
                          },
                          showDivider: true,
                        ),

                        // Language
                        _buildPreferenceItem(
                          title: "Language",
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextWidget(
                                text: "English (US)",
                                fontSize: 14,
                                fontWeight: fwNormal,
                                color: AppColor.subtitle,
                              ),
                              8.width,
                              Icon(
                                Icons.chevron_right,
                                color: AppColor.subtitle,
                                size: ResSize.h * 24,
                              ),
                            ],
                          ),
                          onTap: () {
                            // Handle tap
                          },
                          showDivider: false,
                        ),
                      ],
                    ),
                  ),

                  24.height,

                  // Logout Card
                  GestureDetector(
                    onTap: () {
                      // Handle logout
                    },
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
                          Icon(
                            Icons.logout,
                            color: AppColor.red,
                            size: ResSize.h * 24,
                          ),
                          16.width,
                          TextWidget(
                            text: "Logout",
                            fontSize: 16,
                            fontWeight: fwMedium,
                            color: AppColor.red,
                          ),
                        ],
                      ),
                    ),
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

  Widget _buildPreferenceItem({
    required String title,
    Widget? trailing,
    required VoidCallback onTap,
    required bool showDivider,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: ResSize.w * 14,
              vertical: ResSize.h * 16,
            ),
            color: Colors.transparent,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextWidget(
                  text: title,
                  fontSize: 16,
                  fontWeight: fwMedium,
                  color: AppColor.primary,
                ),
                trailing ??
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
          Padding(
            padding: EdgeInsets.symmetric(horizontal: ResSize.w * 14),
            child: Divider(
              color: const Color(0xFFE0E0E0),
              thickness: 1,
              height: 1,
            ),
          ),
      ],
    );
  }
}
