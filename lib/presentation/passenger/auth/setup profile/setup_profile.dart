import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:movera_rider/constants/appassets.dart';
import 'package:movera_rider/constants/appcolors.dart';
import 'package:movera_rider/constants/appfontweight.dart';
import 'package:movera_rider/presentation/passenger/bottom%20navigation/bottom_navigation.dart';
import 'package:movera_rider/widgets/custom_btn.dart';
import 'package:movera_rider/widgets/custom_text_widget.dart';
import 'package:movera_rider/widgets/custom_textfield.dart';
import 'package:movera_rider/widgets/navigation_transition.dart';
import 'package:movera_rider/widgets/responsive_size.dart';
import 'package:movera_rider/widgets/sizedbox_extention.dart';

class PassengerSetupProfile extends StatefulWidget {
  const PassengerSetupProfile({super.key});

  @override
  State<PassengerSetupProfile> createState() => _PassengerSetupProfileState();
}

class _PassengerSetupProfileState extends State<PassengerSetupProfile> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: screenHorizPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            55.height,
            Center(child: Image.asset(AppAssets.logo, height: ResSize.h * 40)),
            36.height,
            TextWidget(
              text: "Set-Up your profile",
              color: AppColor.primary,
              fontSize: ResSize.setSp(24),
              fontWeight: fwSemiBold,
            ),
            2.height,
            TextWidget(
              text: "Set-up your profile to dive into full experience of app",
              color: AppColor.primary,
              fontSize: ResSize.setSp(14),
              fontWeight: fwNormal,
            ),
            24.height,
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
                              color: Color(0xffE7E7E7),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.camera_alt_rounded,
                                color: Color(0xffAAAAAA),
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
            16.height,
            Center(
              child: TextWidget(
                text: "Upload Profile Photo",
                color: AppColor.primary,
                fontSize: ResSize.setSp(18),
                fontWeight: fwSemiBold,
              ),
            ),
            32.height,
            TextWidget(
              text: "Full Name",
              color: AppColor.primary,
              fontSize: ResSize.setSp(16),
              fontWeight: fwMedium,
            ),
            8.height,
            customTextfield(hint: "Full Name"),
            24.height,
            TextWidget(
              text: "Email Address",
              color: AppColor.primary,
              fontSize: ResSize.setSp(16),
              fontWeight: fwMedium,
            ),
            8.height,
            customTextfield(hint: "example22@gmail.com"),
            42.height,
            CustomButton(
              centerContent: "Continue",
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  BottomToTopTransition(const PassengerBottomNavigation()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
