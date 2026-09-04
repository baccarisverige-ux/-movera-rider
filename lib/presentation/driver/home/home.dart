// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:riding_app/constants/appassets.dart';
import 'package:riding_app/constants/appcolors.dart';
import 'package:riding_app/constants/appfontweight.dart';
import 'package:riding_app/presentation/driver/home/bottom%20sheets/accepted.dart';
import 'package:riding_app/presentation/driver/home/bottom%20sheets/arrived.dart';
import 'package:riding_app/presentation/driver/home/bottom%20sheets/in_ride.dart';
import 'package:riding_app/presentation/driver/home/bottom%20sheets/ride_request.dart';
import 'package:riding_app/presentation/driver/home/ride%20completed/ride_completed.dart';
import 'package:riding_app/presentation/driver/side%20menu/side_menu.dart';
import 'package:riding_app/widgets/custom_text_widget.dart';
import 'package:riding_app/widgets/navigation_transition.dart';
import 'package:riding_app/widgets/responsive_size.dart';
import 'package:riding_app/widgets/sizedbox_extention.dart';

class DriverHome extends StatefulWidget {
  const DriverHome({super.key});

  @override
  State<DriverHome> createState() => _DriverHomeState();
}

class _DriverHomeState extends State<DriverHome> {
  DriverRideStep _currentStep = DriverRideStep.offline;

  void _changeStep(DriverRideStep step) {
    setState(() {
      _currentStep = step;
    });
  }

  void _goOnline() {
    _changeStep(DriverRideStep.rideRequest);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const DriverSideMenu(),
      body: Container(
        height: double.infinity,
        width: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(AppAssets.map),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: screenHorizPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  50.height,
                  Builder(
                    builder: (context) => GestureDetector(
                      onTap: () {
                        Scaffold.of(context).openDrawer();
                      },
                      child: Container(
                        height: ResSize.h * 52,
                        width: ResSize.w * 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColor.secondary,
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xff000000).withOpacity(0.14),
                              blurRadius: 20,
                              offset: const Offset(0, 5),
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            Icons.menu_rounded,
                            size: ResSize.h * 24,
                            color: AppColor.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  12.height,
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: AppColor.secondary,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xff000000).withOpacity(0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 5),
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: ResSize.w * 16,
                        vertical: ResSize.h * 18,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                height: ResSize.h * 13,
                                width: ResSize.w * 13,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: statusDotColor,
                                ),
                              ),

                              8.width,
                              TextWidget(
                                text: headerTitle,
                                color: AppColor.primary,
                                fontSize: 18,
                                fontWeight: fwSemiBold,
                              ),
                            ],
                          ),
                          2.height,
                          Padding(
                            padding: EdgeInsets.only(left: ResSize.w * 21),
                            child: TextWidget(
                              text: headerSubtitle,
                              color: AppColor.subtitle,
                              fontSize: 14,
                              fontWeight: fwNormal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: ResSize.h * 30,
                  left: screenHorizPadding,
                  right: screenHorizPadding,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      transitionBuilder: (child, animation) {
                        return SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.25),
                            end: Offset.zero,
                          ).animate(animation),
                          child: FadeTransition(
                            opacity: animation,
                            child: child,
                          ),
                        );
                      },
                      child: _buildBottomSheet(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSheet() {
    switch (_currentStep) {
      // 1️⃣ OFFLINE
      case DriverRideStep.offline:
        return GoOnlineSheet(
          key: const ValueKey('offline'),
          onGoOnline: _goOnline,
        );

      // 2️⃣ RIDE REQUEST (15s timer)
      case DriverRideStep.rideRequest:
        return DriverRideRequestSheet(
          key: const ValueKey('rideRequest'),
          onAccept: () => _changeStep(DriverRideStep.accepted),
          onDecline: () => _changeStep(DriverRideStep.offline),
          onTimeout: () => _changeStep(DriverRideStep.offline),
        );

      // 3️⃣ ACCEPTED → ON THE WAY
      case DriverRideStep.accepted:
        return DriverRideAcceptedSheet(
          key: const ValueKey('accepted'),
          onArrived: () => _changeStep(DriverRideStep.arrived),
        );

      // 4️⃣ ARRIVED AT PICKUP
      case DriverRideStep.arrived:
        return DriverArrivedSheet(
          key: const ValueKey('arrived'),
          onStartRide: () => _changeStep(DriverRideStep.inRide),
          onCancel: () => _changeStep(DriverRideStep.offline),
        );

      // 5️⃣ IN RIDE
      case DriverRideStep.inRide:
        return DriverInRideSheet(
          key: const ValueKey('inRide'),
          onEndRide: () {
            _changeStep(DriverRideStep.offline);
            Navigator.pushReplacement(
              context,
              TopToBottomTransition(const DriverRideCompleted()),
            );
          },
        );
    }
  }

  bool get isOnline {
    return _currentStep != DriverRideStep.offline;
  }

  Color get statusDotColor {
    return isOnline ? AppColor.green : Colors.grey;
  }

  String get headerTitle {
    switch (_currentStep) {
      case DriverRideStep.offline:
        return "You are offline";
      case DriverRideStep.rideRequest:
        return "New ride request";
      case DriverRideStep.accepted:
        return "On the way to pickup";
      case DriverRideStep.arrived:
        return "Arrived at pickup";
      case DriverRideStep.inRide:
        return "Ride in progress";
    }
  }

  String get headerSubtitle {
    switch (_currentStep) {
      case DriverRideStep.offline:
        return "Go online to start receiving ride requests";
      case DriverRideStep.rideRequest:
        return "Respond within 15 seconds";
      case DriverRideStep.accepted:
        return "Navigate to the pickup location";
      case DriverRideStep.arrived:
        return "Confirm when the passenger is on board";
      case DriverRideStep.inRide:
        return "Drive safely to the destination";
    }
  }
}

enum DriverRideStep { offline, rideRequest, accepted, arrived, inRide }

class GoOnlineSheet extends StatelessWidget {
  final VoidCallback onGoOnline;

  const GoOnlineSheet({super.key, required this.onGoOnline});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onGoOnline,
      child: Container(
        height: 100,
        width: 100,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColor.primary,
          border: Border.all(color: AppColor.secondary, width: 4),
        ),
        child: Center(
          child: TextWidget(
            textAlign: TextAlign.center,
            text: "Go\nOnline",
            fontSize: 16,
            fontWeight: fwSemiBold,
            color: AppColor.secondary,
          ),
        ),
      ),
    );
  }
}
