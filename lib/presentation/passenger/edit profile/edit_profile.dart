// ignore_for_file: deprecated_member_use

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:movera_rider/constants/appassets.dart';
import 'package:movera_rider/constants/appcolors.dart';
import 'package:movera_rider/constants/appfontweight.dart';
import 'package:movera_rider/widgets/custom_btn.dart';
import 'package:movera_rider/widgets/custom_text_widget.dart';
import 'package:movera_rider/widgets/responsive_size.dart';
import 'package:movera_rider/widgets/sizedbox_extention.dart';
import 'package:riff_switch/riff_switch.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    // Show bottom sheet with options
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextWidget(
              text: "Choose Profile Photo",
              color: AppColor.primary,
              fontSize: ResSize.setSp(18),
              fontWeight: fwSemiBold,
            ),
            24.height,
            ListTile(
              leading: Icon(Icons.camera_alt, color: AppColor.primary),
              title: TextWidget(
                text: "Take Photo",
                color: AppColor.primary,
                fontSize: ResSize.setSp(16),
                fontWeight: fwMedium,
              ),
              onTap: () async {
                Navigator.pop(context);
                await _getImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library, color: AppColor.primary),
              title: TextWidget(
                text: "Choose from Gallery",
                color: AppColor.primary,
                fontSize: ResSize.setSp(16),
                fontWeight: fwMedium,
              ),
              onTap: () async {
                Navigator.pop(context);
                await _getImage(ImageSource.gallery);
              },
            ),
            if (_selectedImage != null)
              ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: TextWidget(
                  text: "Remove Photo",
                  color: Colors.red,
                  fontSize: ResSize.setSp(16),
                  fontWeight: fwMedium,
                ),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _selectedImage = null;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _getImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      // Handle error
      ScaffoldMessenger.of(
        // ignore: use_build_context_synchronously
        context,
      ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
    }
  }

  bool isPushNotificationsEnabled = true;
  bool val1 = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.secondary,
      body: SingleChildScrollView(
        child: Column(
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
                  text: "Profile",
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

            40.height,

            Center(
              child: SizedBox(
                width: ResSize.w * 100,
                height: ResSize.h * 100,
                child: Stack(
                  children: [
                    Center(
                      child: Container(
                        height: ResSize.h * 100,
                        width: ResSize.w * 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          image: DecorationImage(
                            image: _selectedImage != null
                                ? FileImage(_selectedImage!) as ImageProvider
                                : AssetImage(AppAssets.profile),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Transform.translate(
                        offset: const Offset(10, 0),
                        child: InkWell(
                          onTap: _pickImage,
                          child: Container(
                            height: ResSize.h * 40,
                            width: ResSize.w * 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColor.secondary,
                                width: 2,
                              ),
                              color: AppColor.primary,
                            ),
                            child: Center(
                              child: Icon(
                                Icons.camera_alt_rounded,
                                color: AppColor.secondary,
                                size: ResSize.h * 25,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            10.height,

            // Name
            TextWidget(
              text: "Mac Mort",
              fontSize: 18,
              fontWeight: fwSemiBold,
              color: AppColor.primary,
            ),

            3.height,

            // Email
            TextWidget(
              text: "example2@gmail.com",
              fontSize: 14,
              fontWeight: fwNormal,
              color: AppColor.subtitle,
            ),

            40.height,

            // Settings Options
            Padding(
              padding: EdgeInsets.symmetric(horizontal: ResSize.w * 20),
              child: Column(
                children: [
                  // Username
                  _buildSettingsCard(
                    icon: AppAssets.editUser,
                    title: "username",
                    onTap: () {
                      // Handle username tap
                    },
                  ),
                  16.height,
                  // Language
                  _buildSettingsCard(
                    icon: AppAssets.language,
                    title: "Language",
                    showArrow: true,
                    onTap: () {
                      // Handle language tap
                    },
                  ),
                  16.height,
                  // Push Notifications
                  _buildSettingsCard(
                    icon: AppAssets.notification,
                    title: "Push Notifications",
                    isNotifi: true,
                    trailing: Transform.scale(
                      scale: 0.8,
                      child: RiffSwitch(
                        trackColor: WidgetStatePropertyAll(Color(0xffBEBEBE)),
                        activeTrackColor: Color(0xff0DC216).withOpacity(0.2),
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
                  ),

                  32.height,

                  // Save Button
                  CustomButton(
                    centerContent: "Save",
                    onPressed: () {
                      Navigator.pop(context);
                      // Handle save
                    },
                  ),

                  24.height,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCard({
    required String icon,
    required String title,
    bool showArrow = false,
    Widget? trailing,
    VoidCallback? onTap,
    bool isNotifi = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: ResSize.w * 14,
          vertical: isNotifi ? ResSize.h * 10 : ResSize.h * 16,
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
            Image.asset(icon, color: AppColor.subtitle, height: ResSize.h * 24),
            12.width,
            Expanded(
              child: TextWidget(
                text: title,
                fontSize: 16,
                fontWeight: fwMedium,
                color: AppColor.subtitle,
              ),
            ),
            if (trailing != null)
              trailing
            else if (showArrow)
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
