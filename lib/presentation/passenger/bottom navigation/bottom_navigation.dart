// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:riding_app/constants/appassets.dart';
import 'package:riding_app/constants/appcolors.dart';
import 'package:riding_app/constants/appfontweight.dart';
import 'package:riding_app/presentation/common/trips/trips.dart';
import 'package:riding_app/presentation/passenger/home/home.dart';
import 'package:riding_app/presentation/passenger/profile/profile.dart';
import 'package:riding_app/presentation/passenger/services/services.dart';
import 'package:riding_app/widgets/custom_text_widget.dart';
import 'package:riding_app/widgets/responsive_size.dart';
import 'package:riding_app/widgets/sizedbox_extention.dart';

class PassengerBottomNavigation extends StatefulWidget {
  const PassengerBottomNavigation({super.key});

  @override
  State<PassengerBottomNavigation> createState() =>
      _PassengerBottomNavigationState();
}

class _PassengerBottomNavigationState extends State<PassengerBottomNavigation> {
  int _currentIndex = 0;

  // Add your actual pages here
  final List<Widget> _pages = [
    const PassengerHomeScreen(),
    PassengerServicesScreen(),
    const TripsScreen(),
    const PassengerProfileScreen(showBackIcon: false),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColor.secondary,
          boxShadow: [
            BoxShadow(
              offset: const Offset(0, -2),
              color: const Color(0xff000000).withOpacity(0.06),
              blurRadius: 10,
              spreadRadius: 0,
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: screenHorizPadding,
              vertical: ResSize.h * 6,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildNavItem(index: 0, icon: AppAssets.home, label: "Home"),
                _buildNavItem(
                  index: 1,
                  icon: AppAssets.services,
                  label: "Services",
                ),
                _buildNavItem(index: 2, icon: AppAssets.trip, label: "Trips"),
                _buildProfileNavItem(index: 3, label: "Profile"),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required String icon,
    required String label,
  }) {
    final bool isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: Container(
        color: Colors.transparent,
        padding: EdgeInsets.symmetric(
          horizontal: ResSize.w * 8,
          vertical: ResSize.h * 8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              icon,
              color: isSelected ? AppColor.primary : AppColor.subtitle,
              height: ResSize.h * 24,
            ),
            2.height,
            TextWidget(
              text: label,
              fontSize: 12,
              fontWeight: fwNormal,
              color: isSelected ? AppColor.primary : AppColor.subtitle,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileNavItem({required int index, required String label}) {
    final bool isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: Container(
        color: Colors.transparent,
        padding: EdgeInsets.symmetric(
          horizontal: ResSize.w * 8,
          vertical: ResSize.h * 8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: ResSize.w * 28,
              height: ResSize.w * 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColor.primary : Colors.transparent,
                  width: 2,
                ),
                image: DecorationImage(
                  image: AssetImage(AppAssets.profile),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SizedBox(height: ResSize.h * 4),
            TextWidget(
              text: label,
              fontSize: 12,
              fontWeight: fwNormal,
              color: isSelected ? AppColor.primary : AppColor.subtitle,
            ),
          ],
        ),
      ),
    );
  }
}
