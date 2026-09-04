// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:riding_app/constants/appcolors.dart';
import 'package:riding_app/constants/appfontweight.dart';
import 'package:riding_app/presentation/driver/auth/additionl%20info/screens/payout_details.dart';
import 'package:riding_app/presentation/driver/auth/additionl%20info/screens/personal_detail.dart';
import 'package:riding_app/presentation/driver/auth/additionl%20info/screens/upload_documents.dart';
import 'package:riding_app/presentation/driver/auth/additionl%20info/screens/vehicle_details.dart';
import 'package:riding_app/presentation/driver/home/home.dart';
import 'package:riding_app/widgets/custom_btn.dart';
import 'package:riding_app/widgets/custom_text_widget.dart';
import 'package:riding_app/widgets/navigation_transition.dart';
import 'package:riding_app/widgets/responsive_size.dart';
import 'package:riding_app/widgets/sizedbox_extention.dart';

class DriverAdditionalInfoNavigationController extends GetxController {
  final RxInt currentPageIndex = 0.obs;
  final PageController pageController = PageController();

  final int totalPages = 4;

  // Replace these with your actual screens
  final List<Widget> pages = [
    AdditionalInfoPersonalDetail(), // Screen 1
    AdditionalInfoVehicleDetail(), // Screen 2
    AdditionalInfoUploadDocument(), // Screen 3
    AdditionalInfoPayoutDetail(), // Screen 4
  ];

  void moveToNextStep(BuildContext context) {
    if (currentPageIndex.value < pages.length - 1) {
      currentPageIndex.value++;
      pageController.animateToPage(
        currentPageIndex.value,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Last step reached - navigate to home
      Navigator.push(context, TopToBottomTransition(DriverHome()));
    }
  }

  void moveToPreviousStep() {
    if (currentPageIndex.value > 0) {
      currentPageIndex.value--;
      pageController.animateToPage(
        currentPageIndex.value,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Get.back();
    }
  }

  double get progressValue => (currentPageIndex.value + 1) / totalPages;

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }
}

class DriverAdditionalInfoNavigation extends StatelessWidget {
  const DriverAdditionalInfoNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(DriverAdditionalInfoNavigationController());

    return Scaffold(
      backgroundColor: AppColor.secondary,
      body: Column(
        children: [
          50.height,

          // Header with back button and step indicator
          Padding(
            padding: EdgeInsets.symmetric(horizontal: ResSize.w * 20),
            child: Row(
              children: [
                GestureDetector(
                  onTap: controller.moveToPreviousStep,
                  child: Icon(
                    Icons.arrow_back,
                    color: AppColor.primary,
                    size: ResSize.h * 24,
                  ),
                ),
                16.width,
                Obx(
                  () => TextWidget(
                    text:
                        "Step ${controller.currentPageIndex.value + 1} of ${controller.totalPages}",
                    fontSize: 18,
                    fontWeight: fwSemiBold,
                    color: AppColor.primary,
                  ),
                ),
              ],
            ),
          ),

          16.height,

          // Linear Progress Bar
          Padding(
            padding: EdgeInsets.symmetric(horizontal: ResSize.w * 20),
            child: Obx(
              () => TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                tween: Tween<double>(begin: 0, end: controller.progressValue),
                builder: (context, value, _) => ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: value,
                    minHeight: ResSize.h * 8,
                    backgroundColor: const Color(0xFFE0E0E0),
                    valueColor: AlwaysStoppedAnimation<Color>(AppColor.primary),
                  ),
                ),
              ),
            ),
          ),

          24.height,

          // PageView Content
          Expanded(
            child: PageView.builder(
              controller: controller.pageController,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: controller.pages.length,
              onPageChanged: (index) {
                controller.currentPageIndex.value = index;
              },
              itemBuilder: (BuildContext context, int index) {
                return controller.pages[index];
              },
            ),
          ),

          // Next Button
          Padding(
            padding: EdgeInsets.symmetric(horizontal: ResSize.w * 20),
            child: Obx(
              () => CustomButton(
                centerContent:
                    controller.currentPageIndex.value ==
                        controller.totalPages - 1
                    ? "Submit"
                    : "Next",
                onPressed: () {
                  controller.moveToNextStep(context);
                },
              ),
            ),
          ),
          24.height,
        ],
      ),
    );
  }
}
