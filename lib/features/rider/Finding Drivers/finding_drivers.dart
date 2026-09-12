import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:movera_rider/app/di.dart';
import 'package:movera_rider/core/constants/appassets.dart';
import 'package:movera_rider/core/constants/appcolors.dart';
import 'package:movera_rider/core/constants/appfontweight.dart';
import 'package:movera_rider/features/ride_booking/data/ride_snapshot_store.dart';
import 'package:movera_rider/features/ride_booking/domain/ride_status.dart';
import 'package:movera_rider/features/rider/Finding%20Drivers/components/cancel_ride.dart';
import 'package:movera_rider/features/rider/waiting%20for%20driver/waiting_for_driver.dart';
import 'package:movera_rider/shared/widgets/custom_btn.dart';
import 'package:movera_rider/shared/widgets/custom_google_map.dart';
import 'package:movera_rider/shared/widgets/custom_text_widget.dart';
import 'package:movera_rider/shared/widgets/navigation_transition.dart';
import 'package:movera_rider/shared/widgets/responsive_size.dart';
import 'package:movera_rider/shared/widgets/sizedbox_extention.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

class FindingDrivers extends StatefulWidget {
  const FindingDrivers({
    super.key,
    required this.pickupAddress,
    required this.destinationAddress,
    required this.pickupPosition,
    required this.destinationPosition,
    required this.rideType,
    required this.price,
    required this.paymentMethod,
  });

  final String pickupAddress;
  final String destinationAddress;
  final LatLng pickupPosition;
  final LatLng destinationPosition;
  final String rideType;
  final double price;
  final String paymentMethod;

  @override
  State<FindingDrivers> createState() => _FindingDriversState();
}

class _FindingDriversState extends State<FindingDrivers> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};

  // Countdown variables
  int remainingSeconds = 12; // set duration here (30 seconds)
  Timer? _timer;

  late final CameraPosition _initialPosition;

  @override
  void initState() {
    super.initState();
    _initialPosition = CameraPosition(
      target: widget.pickupPosition,
      zoom: 14.0,
    );
    _loadMarkers();
    _startCountdown();
    AppScope.instance.ride.restoreFromBackend(RideStatus.findingDriver);

    Future.delayed(Duration(seconds: 12), () {
      if (mounted) {
        AppScope.instance.ride.restoreFromBackend(RideStatus.driverAssigned);
        RideSnapshotStore.save(
          RideSnapshot(
            status: RideStatus.driverAssigned,
            savedAt: DateTime.now(),
            pickupAddress: widget.pickupAddress,
            destinationAddress: widget.destinationAddress,
            pickupLat: widget.pickupPosition.latitude,
            pickupLng: widget.pickupPosition.longitude,
            destinationLat: widget.destinationPosition.latitude,
            destinationLng: widget.destinationPosition.longitude,
            rideType: widget.rideType,
            price: widget.price,
            paymentMethod: widget.paymentMethod,
            rideId: AppScope.instance.ride.rideId,
          ),
        );
        Navigator.push(
          context,
          BottomToTopTransition(
            WaitingForDriver(
              pickupAddress: widget.pickupAddress,
              destinationAddress: widget.destinationAddress,
              pickupPosition: widget.pickupPosition,
              destinationPosition: widget.destinationPosition,
              rideType: widget.rideType,
              price: widget.price,
              paymentMethod: widget.paymentMethod,
            ),
          ),
        );
      }
    });
  }

  void _startCountdown() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (remainingSeconds > 0) {
        setState(() {
          remainingSeconds--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int secs = seconds % 60;
    String minStr = minutes.toString().padLeft(2, '0');
    String secStr = secs.toString().padLeft(2, '0');
    return "$minStr:$secStr";
  }

  void _loadMarkers() {
    _markers = {
      Marker(
        markerId: const MarkerId('pickup'),
        position: widget.pickupPosition,
        infoWindow: InfoWindow(title: widget.pickupAddress),
        icon: BitmapDescriptor.defaultMarker,
      ),
      Marker(
        markerId: const MarkerId('destination'),
        position: widget.destinationPosition,
        infoWindow: InfoWindow(title: widget.destinationAddress),
        icon: BitmapDescriptor.defaultMarker,
      ),
    };
  }

  @override
  void dispose() {
    _timer?.cancel(); // stop timer when screen closes
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SlidingUpPanel(
        color: AppColor.white,
        backdropColor: Colors.transparent,
        margin: EdgeInsets.all(0),
        minHeight: ResSize.h * 80,
        padding: EdgeInsets.symmetric(vertical: ResSize.h * 16),
        boxShadow: [],
        isDraggable: true,
        defaultPanelState: PanelState.CLOSED,
        maxHeight: ResSize.h * 454,
        parallaxEnabled: false,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
        panelBuilder: (ScrollController sc) => panelColumn(sc, context),
        body: Stack(
          children: [
            CustomGoogleMap(
              initialPosition: _initialPosition,
              markers: _markers,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              compassEnabled: false,
              trafficEnabled: false,
              buildingsEnabled: true,
              indoorViewEnabled: false,
              mapType: MapType.normal,
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
              },
              onTap: (LatLng position) {},
            ),
            Align(
              alignment: Alignment.center,
              child: Image.asset(
                AppAssets.selectedLocation,
                height: ResSize.h * 167,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget panelColumn(ScrollController sc, BuildContext context) {
    return SingleChildScrollView(
      controller: sc,
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: screenHorizPadding),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextWidget(
                          color: AppColor.title,
                          fontSize: 16,
                          fontWeight: fwSemiBold,
                          text: "5+ cars nearby",
                        ),
                        TextWidget(
                          color: AppColor.title,
                          fontSize: 12,
                          fontWeight: fwNormal,
                          text: "Finding a driver for you",
                        ),
                      ],
                    ),
                    10.width,
                    Image.asset(
                      AppAssets.driversImages,
                      height: ResSize.h * 25,
                    ),
                  ],
                ),

                // ⏱ Dynamic timer text here
                TextWidget(
                  color: AppColor.title,
                  fontSize: 16,
                  fontWeight: fwNormal,
                  text: _formatTime(remainingSeconds),
                ),
              ],
            ),
          ),
          3.height,
          Container(
            height: ResSize.h * 4,
            width: double.infinity,
            color: const Color(0xffFAFAFA),
          ),
          16.height,
          Padding(
            padding: EdgeInsets.symmetric(horizontal: screenHorizPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextWidget(
                  color: AppColor.subtitle,
                  fontSize: 12,
                  fontWeight: fwSemiBold,
                  text: "Pickup from  ",
                ),
                TextWidget(
                  color: AppColor.title,
                  fontSize: 14,
                  fontWeight: fwSemiBold,
                  text: widget.pickupAddress,
                ),
                16.height,
                Divider(color: AppColor.border, thickness: 0.3, height: 0),
                16.height,
                TextWidget(
                  color: AppColor.subtitle,
                  fontSize: 12,
                  fontWeight: fwSemiBold,
                  text: "Drop off location",
                ),
                TextWidget(
                  color: AppColor.title,
                  fontSize: 14,
                  fontWeight: fwSemiBold,
                  text: widget.destinationAddress,
                ),
                16.height,
                Divider(color: AppColor.border, thickness: 0.3, height: 0),
                16.height,
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextWidget(
                      color: AppColor.title,
                      fontSize: 16,
                      fontWeight: fwBold,
                      text: "Ride Cost",
                    ),
                    TextWidget(
                      color: AppColor.title,
                      fontSize: 16,
                      fontWeight: fwBold,
                      text: 'kr ${widget.price.toStringAsFixed(0)}',
                    ),
                  ],
                ),
                16.height,
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextWidget(
                      color: AppColor.title,
                      fontSize: 16,
                      fontWeight: fwBold,
                      text: "Payment Method",
                    ),
                    Row(
                      children: [
                        Transform.scale(
                          scale: 1.2,
                          child: Image.asset(
                            AppAssets.wallet2,
                            color: AppColor.title,
                            height: ResSize.h * 22,
                          ),
                        ),
                        6.width,
                        TextWidget(
                          color: AppColor.title,
                          fontSize: 16,
                          fontWeight: fwBold,
                          text: widget.paymentMethod,
                        ),
                      ],
                    ),
                  ],
                ),
                16.height,
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextWidget(
                      color: AppColor.title,
                      fontSize: 16,
                      fontWeight: fwBold,
                      text: "Ride Type",
                    ),
                    TextWidget(
                      color: AppColor.title,
                      fontSize: 16,
                      fontWeight: fwBold,
                      text: widget.rideType,
                    ),
                  ],
                ),
                36.height,

                // Cancel Request Button
                CustomButton(
                  textColor: AppColor.black,
                  btncolor: const Color(0xffE0E0E0),
                  centerContent: "Cancel request",
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => RideCancellationDialog(),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
