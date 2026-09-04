// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:riding_app/constants/appassets.dart';
import 'package:riding_app/constants/appcolors.dart';
import 'package:riding_app/constants/appfontweight.dart';
import 'package:riding_app/presentation/passenger/ride%20booking/bottom%20sheets/driver_onthe_way.dart';
import 'package:riding_app/presentation/passenger/ride%20booking/bottom%20sheets/finding_driver.dart';
import 'package:riding_app/presentation/passenger/ride%20booking/bottom%20sheets/location_selection.dart';
import 'package:riding_app/presentation/passenger/ride%20booking/bottom%20sheets/location_shortcut.dart';
import 'package:riding_app/presentation/passenger/ride%20booking/bottom%20sheets/payment_method.dart';
import 'package:riding_app/presentation/passenger/ride%20booking/bottom%20sheets/ride_options.dart';
import 'package:riding_app/presentation/passenger/ride%20booking/bottom%20sheets/trip_in_progress.dart';
import 'package:riding_app/presentation/passenger/ride%20booking/ride%20completed/ride_completed.dart';
import 'package:riding_app/presentation/passenger/side%20menu/side_menu.dart';
import 'package:riding_app/services/location_services.dart';
import 'package:riding_app/widgets/custom_text_widget.dart';
import 'package:riding_app/widgets/responsive_size.dart';
import 'package:riding_app/widgets/sizedbox_extention.dart';

class RideBookingScreen extends StatefulWidget {
  const RideBookingScreen({super.key});

  @override
  State<RideBookingScreen> createState() => _RideBookingScreenState();
}

class _RideBookingScreenState extends State<RideBookingScreen> {
  String _currentAddress = "Fetching location...";
  bool _isLoading = true;
  bool _locationServiceDisabled = false;
  bool _permissionDenied = false;

  @override
  void initState() {
    super.initState();
    _checkLocationAndFetch();
  }

  Future<void> _checkLocationAndFetch() async {
    setState(() {
      _isLoading = true;
      _locationServiceDisabled = false;
      _permissionDenied = false;
    });

    // Check if location service is enabled
    bool serviceEnabled = await LocationService.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _isLoading = false;
        _locationServiceDisabled = true;
        _currentAddress = "Location service is disabled";
      });
      _showLocationServiceDialog();
      return;
    }

    // Check and request permission
    LocationPermission permission = await LocationService.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await LocationService.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _isLoading = false;
          _permissionDenied = true;
          _currentAddress = "Location permission denied";
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _isLoading = false;
        _permissionDenied = true;
        _currentAddress = "Location permission permanently denied";
      });
      _showPermissionDialog();
      return;
    }

    // Get current position
    await _fetchCurrentLocation();
  }

  Future<void> _fetchCurrentLocation() async {
    Position? position = await LocationService.getCurrentPosition();

    if (position != null) {
      String address = await LocationService.getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );

      setState(() {
        _currentAddress = address;
        _isLoading = false;
      });
    } else {
      setState(() {
        _currentAddress = "Unable to get location";
        _isLoading = false;
      });
    }
  }

  void _showLocationServiceDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Location Service Disabled',
            style: GoogleFonts.poppins(fontWeight: fwSemiBold, fontSize: 18),
          ),
          content: Text(
            'Please enable location services to use this feature.',
            style: GoogleFonts.poppins(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await LocationService.openLocationSettings();
                // Wait a bit and check again
                await Future.delayed(Duration(seconds: 2));
                _checkLocationAndFetch();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.primary,
              ),
              child: Text(
                'Enable',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Location Permission Required',
            style: GoogleFonts.poppins(fontWeight: fwSemiBold, fontSize: 18),
          ),
          content: Text(
            'This app needs location permission to show your current location. Please grant permission in settings.',
            style: GoogleFonts.poppins(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await LocationService.openAppSettings();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.primary,
              ),
              child: Text(
                'Open Settings',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  RideBookingStep _currentStep = RideBookingStep.locationShortcuts;

  void _changeStep(RideBookingStep step) {
    setState(() {
      _currentStep = step;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const PassengerSideMenu(),
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
                      child: Row(
                        children: [
                          Container(
                            height: ResSize.h * 44,
                            width: ResSize.w * 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xffF8F8F8),
                            ),
                            child: Center(
                              child: _isLoading
                                  ? SizedBox(
                                      height: ResSize.h * 20,
                                      width: ResSize.w * 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              AppColor.primary,
                                            ),
                                      ),
                                    )
                                  : Image.asset(
                                      AppAssets.location,
                                      height: ResSize.h * 24,
                                      color: AppColor.primary,
                                    ),
                            ),
                          ),
                          12.width,
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextWidget(
                                  text: "Your Current Location",
                                  color: AppColor.primary,
                                  fontSize: 18,
                                  fontWeight: fwSemiBold,
                                ),
                                5.height,
                                Text(
                                  _currentAddress,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  style: GoogleFonts.poppins(
                                    color: AppColor.primary,
                                    fontSize: 14,
                                    fontWeight: fwNormal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_locationServiceDisabled || _permissionDenied)
                            IconButton(
                              icon: Icon(
                                Icons.refresh,
                                color: AppColor.primary,
                              ),
                              onPressed: _checkLocationAndFetch,
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
                    // BookRideTripInProgress(),
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
      case RideBookingStep.locationShortcuts:
        return BookRideLocationShortcuts(
          key: const ValueKey('locationShortcuts'),
          onNext: () => _changeStep(RideBookingStep.locationSelection),
        );

      case RideBookingStep.locationSelection:
        return BookRideLocationSelection(
          key: const ValueKey('locationSelection'),
          onNext: () => _changeStep(RideBookingStep.rideOptions),
        );

      case RideBookingStep.rideOptions:
        return BookRideRideOptions(
          key: const ValueKey('rideOptions'),
          onNext: () => _changeStep(RideBookingStep.payment),
        );

      case RideBookingStep.payment:
        return BookRidePaymentMethods(
          key: const ValueKey('payment'),
          onNext: () => _changeStep(RideBookingStep.findingDriver),
        );

      case RideBookingStep.findingDriver:
        return BookRideFindingDrivers(
          key: const ValueKey('findingDriver'),
          onNext: () => _changeStep(RideBookingStep.driverOnTheWay),
        );

      case RideBookingStep.driverOnTheWay:
        return BookRideDriverOnTheWay(
          key: const ValueKey('driverOnTheWay'),
          onNext: () => _changeStep(RideBookingStep.tripInProgress),
        );

      case RideBookingStep.tripInProgress:
        return BookRideTripInProgress(
          key: const ValueKey('tripInProgress'),
          onNext: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const PassengerRideCompleted()),
            );
          },
        );
    }
  }
}

enum RideBookingStep {
  locationShortcuts,
  locationSelection,
  rideOptions,
  payment,
  findingDriver,
  driverOnTheWay,
  tripInProgress,
}
