import 'package:dotted_line/dotted_line.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:movera_rider/app/di.dart';
import 'package:movera_rider/core/constants/appassets.dart';
import 'package:movera_rider/core/constants/appcolors.dart';
import 'package:movera_rider/core/constants/appfontweight.dart';
import 'package:movera_rider/features/active_ride/application/active_ride_controller.dart';
import 'package:movera_rider/features/driver_arriving/application/driver_arriving_controller.dart';
import 'package:movera_rider/features/safety/application/safety_controller.dart';
import 'package:movera_rider/features/safety/domain/safety_event.dart';
import 'package:movera_rider/features/messages/presentation/chat.dart';
import 'package:movera_rider/features/ride_complete/presentation/ride_completed.dart';
import 'package:movera_rider/shared/widgets/custom_google_map.dart';
import 'package:movera_rider/shared/widgets/custom_text_widget.dart';
import 'package:movera_rider/shared/widgets/navigation_transition.dart';
import 'package:movera_rider/shared/widgets/responsive_size.dart';
import 'package:movera_rider/shared/widgets/sizedbox_extention.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

class WaitingForDriver extends StatefulWidget {
  const WaitingForDriver({
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
  State<WaitingForDriver> createState() => _WaitingForDriverState();
}

class _WaitingForDriverState extends State<WaitingForDriver> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  final ActiveRideController _ride = ActiveRideController();

  late final CameraPosition _initialPosition;

  @override
  void initState() {
    super.initState();
    _initialPosition = CameraPosition(
      target: widget.pickupPosition,
      zoom: 14.0,
    );
    _loadMarkers();
    _ride.markArriving();
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
  Widget build(BuildContext context) {
    return Scaffold(
      body: SlidingUpPanel(
        color: AppColor.white,
        backdropColor: Colors.transparent,
        margin: EdgeInsets.all(0),
        minHeight: ResSize.h * 130,
        padding: EdgeInsets.symmetric(
          // horizontal: screenHorizPadding,
          // vertical: ResSize.h * 16,
        ),
        boxShadow: [],
        isDraggable: true,
        defaultPanelState: PanelState.CLOSED,
        maxHeight: ResSize.h * 520,
        parallaxEnabled: false,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(22),
          topRight: Radius.circular(22),
        ),
        panelBuilder: (ScrollController sc) => Container(
          decoration: ShapeDecoration(
            color: AppColor.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(21.0),
                topRight: Radius.circular(21.0),
              ),
            ),
          ),
          child: Column(
            children: [
              12.height,
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: screenHorizPadding + ResSize.w * 5,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Image.asset(
                          AppAssets.hourglass,
                          height: ResSize.h * 20,
                        ),
                        12.width,
                        TextWidget(
                          text: "The Driver will arrive in ",
                          fontSize: 14,
                          fontWeight: fwMedium,
                          color: AppColor.whiteText,
                        ),
                      ],
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: ResSize.w * 8,
                        vertical: ResSize.h * 2,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Color(0xff3B617E),
                      ),
                      child: Center(
                        child: TextWidget(
                          text: "5 mins",
                          fontSize: 14,
                          fontWeight: fwMedium,
                          color: AppColor.whiteText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              8.height,
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenHorizPadding,
                    vertical: ResSize.h * 16,
                  ),
                  decoration: ShapeDecoration(
                    color: AppColor.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(23.0),
                        topRight: Radius.circular(23.0),
                      ),
                    ),
                  ),
                  child: panelColumn(sc),
                ),
              ),
            ],
          ),
        ),

        // panelBuilder: (ScrollController sc) => panelColumn(sc, context),
        body: SizedBox(
          child: Stack(
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
                  AppScope.instance.maps.attach(controller);
                },
                onTap: (LatLng position) {
                  // Handle map tap events
                },
              ),
              SizedBox(
                width: double.infinity,
                child: Column(
                  children: [
                    70.height,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: ResSize.w * 28,
                            vertical: ResSize.h * 5,
                          ),

                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            color: AppColor.white,
                          ),
                          child: Center(
                            child: TextWidget(
                              text: "Get ready driver will  come soon",
                              fontSize: 12,
                              fontWeight: fwMedium,
                              color: AppColor.title,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: EdgeInsets.only(bottom: ResSize.h * 190),
                  child: Transform.rotate(
                    angle: -0.42 / 1,
                    child: Transform.translate(
                      offset: const Offset(-13, -17),
                      child: Image.asset(
                        AppAssets.w8Driver,
                        height: ResSize.h * 180,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget panelColumn(ScrollController sc) {
    return SingleChildScrollView(
      controller: sc,
      child: Column(
        children: [
          16.height,
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Color(0xffF2F5F7),
              border: Border.all(color: AppColor.border, width: 0.3),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: ResSize.w * 22,
              vertical: ResSize.h * 12,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextWidget(
                      fontSize: 20,
                      fontWeight: fwSemiBold,
                      text: "L - 2323 F",
                      color: AppColor.black,
                    ),
                    2.height,
                    TextWidget(
                      fontSize: 14,
                      fontWeight: fwMedium,
                      text: widget.rideType,
                      color: AppColor.black,
                    ),
                  ],
                ),
                Image.asset(AppAssets.comfortRide, height: ResSize.h * 43),
              ],
            ),
          ),
          12.height,
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: ResSize.h * 62,
                width: ResSize.w * 58,
                child: Stack(
                  children: [
                    Container(
                      height: ResSize.h * 54,
                      width: ResSize.w * 58,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: AssetImage(AppAssets.profileImg),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        margin: EdgeInsets.symmetric(horizontal: ResSize.w * 3),
                        height: ResSize.h * 17,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(32),
                          color: AppColor.green,
                        ),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.star,
                                color: AppColor.white,
                                size: ResSize.h * 14,
                              ),
                              5.width,
                              TextWidget(
                                fontSize: 11,
                                fontWeight: fwSemiBold,
                                text: DriverArrivingController().driver().ratingLabel,
                                color: AppColor.whiteText,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              8.width,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextWidget(
                      fontSize: 14,
                      fontWeight: fwSemiBold,
                      text: DriverArrivingController().driver().name,
                      color: AppColor.title,
                    ),
                    TextWidget(
                      fontSize: 14,
                      fontWeight: fwMedium,
                      text: DriverArrivingController().driver().tagline,
                      color: AppColor.subtitle,
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  InkWell(
                    onTap: () {
                      SafetyController().record(SafetyKind.maskedCall);
                    },
                    child: Container(
                      height: ResSize.h * 40,
                      width: ResSize.w * 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(
                          0xff215277,
                          // ignore: deprecated_member_use
                        ).withOpacity(0.10),
                      ),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Image.asset(AppAssets.phone),
                        ),
                      ),
                    ),
                  ),
                  15.width,
                  InkWell(
                    onTap: () {
                      Navigator.push(context, BottomToTopTransition(Chat()));
                    },
                    child: Container(
                      height: ResSize.h * 40,
                      width: ResSize.w * 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(
                          0xff215277,
                          // ignore: deprecated_member_use
                        ).withOpacity(0.10),
                      ),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Image.asset(AppAssets.message),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          16.height,
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColor.border, width: 0.3),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: ResSize.w * 22,
              vertical: ResSize.h * 12,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: ResSize.h * 80,
                  child: Column(
                    children: [
                      Image.asset(AppAssets.gps, height: ResSize.h * 24),
                      2.height,
                      Expanded(
                        child: DottedLine(
                          dashLength: 3,
                          dashGapLength: 3,
                          lineThickness: 1.4,
                          dashRadius: 0,
                          dashColor: AppColor.black,
                          direction: Axis.vertical,
                        ),
                      ),
                      2.height,
                      Image.asset(AppAssets.location, height: ResSize.h * 24),
                    ],
                  ),
                ),
                12.width,
                Expanded(
                  child: Column(
                    children: [
                      InkWell(
                        onTap: () {
                          // Navigator.push(
                          //   context,
                          //   BottomToTopTransition(legacy route removed),
                          // );
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TextWidget(
                                    fontSize: 12,
                                    fontWeight: fwMedium,
                                    text: "Pickup location",
                                    color: AppColor.subtitle,
                                  ),
                                  2.height,
                                  TextWidget(
                                    fontSize: 14,
                                    fontWeight: fwMedium,
                                    text: widget.pickupAddress,
                                    color: AppColor.title,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      10.height,
                      InkWell(
                        onTap: () {
                          // Navigator.push(
                          //   context,
                          //   BottomToTopTransition(legacy route removed),
                          // );
                        },
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TextWidget(
                                    fontSize: 12,
                                    fontWeight: fwMedium,
                                    text: "Your destination",
                                    color: AppColor.subtitle,
                                  ),
                                  2.height,
                                  TextWidget(
                                    fontSize: 14,
                                    fontWeight: fwMedium,
                                    text: widget.destinationAddress,
                                    color: AppColor.title,
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                Icon(
                                  Icons.edit_outlined,
                                  size: ResSize.h * 14,
                                  color: AppColor.title,
                                ),
                                5.width,
                                TextWidget(
                                  fontSize: 10,
                                  fontWeight: fwMedium,
                                  text: "Change",
                                  color: AppColor.title,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          8.height,
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColor.border, width: 0.3),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: ResSize.w * 22,
              vertical: ResSize.h * 12,
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextWidget(
                      text: "Total Payment",
                      color: AppColor.black,
                      fontSize: 14,
                      fontWeight: fwMedium,
                    ),
                    TextWidget(
                      text: '\$${widget.price.toStringAsFixed(2)}',
                      color: AppColor.black,
                      fontSize: 14,
                      fontWeight: fwMedium,
                    ),
                  ],
                ),
                8.height,

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextWidget(
                      text: "Payment method",
                      color: AppColor.black,
                      fontSize: 14,
                      fontWeight: fwMedium,
                    ),
                    TextWidget(
                      text: widget.paymentMethod,
                      color: AppColor.black,
                      fontSize: 14,
                      fontWeight: fwMedium,
                    ),
                  ],
                ),
                8.height,

                InkWell(
                  onTap: () {
                    _ride.markCancelled();
                    Navigator.push(
                      context,
                      BottomToTopTransition(RideCompleted()),
                    );
                  },
                  child: Row(
                    children: [
                      Icon(
                        Icons.block_flipped,
                        color: AppColor.red,
                        size: ResSize.h * 18,
                      ),
                      5.width,
                      TextWidget(
                        text: "Cancel ride",
                        color: AppColor.red,
                        fontSize: 14,
                        fontWeight: fwMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
