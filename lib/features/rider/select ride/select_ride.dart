import 'package:dotted_line/dotted_line.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:movera_rider/core/constants/appassets.dart';
import 'package:movera_rider/core/constants/appcolors.dart';
import 'package:movera_rider/core/constants/appfontweight.dart';
import 'package:movera_rider/shared/models/onboarding.dart';
import 'package:movera_rider/features/rider/Finding%20Drivers/finding_drivers.dart';
import 'package:movera_rider/shared/widgets/custom_btn.dart';
import 'package:movera_rider/shared/widgets/custom_google_map.dart';
import 'package:movera_rider/shared/widgets/custom_text_widget.dart';
import 'package:movera_rider/shared/widgets/navigation_transition.dart';
import 'package:movera_rider/shared/widgets/responsive_size.dart';
import 'package:movera_rider/shared/widgets/sizedbox_extention.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

class SelectRide extends StatefulWidget {
  const SelectRide({super.key});

  @override
  State<SelectRide> createState() => _SelectRideState();
}

class _SelectRideState extends State<SelectRide> {
  List<OnBoardingModel> ridesList = [
    OnBoardingModel(
      image: AppAssets.mini,
      title: "Mini Ride",
      subTitle: "\$5.00",
    ),
    OnBoardingModel(
      image: AppAssets.ecoFriendly,
      title: "Eco-Friendy",
      subTitle: "\$7.50",
    ),
    OnBoardingModel(image: AppAssets.xl, title: "XL", subTitle: "\$17.00"),
    OnBoardingModel(
      image: AppAssets.luxury,
      title: "Luxury",
      subTitle: "\$27.00",
    ),
  ];
  int selectedRide = 1;
  double price = 7.50;
  // Add these fields
  void increasePrice() {
    setState(() {
      price = double.parse((price + 0.05).toStringAsFixed(2));
    });
  }

  void decreasePrice() {
    setState(() {
      // Optional: prevent going below 0
      if (price > 0) {
        price = double.parse((price - 0.05).toStringAsFixed(2));
      }
    });
  }

  int selectedMethod = 0;

  List<OnBoardingModel> paymentMethods = [
    OnBoardingModel(
      image: AppAssets.wallet,
      title: "\$7.00",
      subTitle: "Wallet",
    ),
    OnBoardingModel(image: AppAssets.cash, title: "\$7.00", subTitle: "Cash"),
    OnBoardingModel(
      image: AppAssets.mastercard,
      title: "\$7.00",
      subTitle: "Master card",
    ),
    OnBoardingModel(
      image: AppAssets.applepay,
      title: "\$7.00",
      subTitle: "Apple pay",
    ),
    OnBoardingModel(
      image: AppAssets.paypal,
      title: "\$7.00",
      subTitle: "Paypal",
    ),
  ];
  // ignore: unused_field
  GoogleMapController? _mapController;
  // ignore: prefer_final_fields
  Set<Marker> _markers = {};

  // Default location
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(33.6844, 73.0479), // Islamabad coordinates
    zoom: 14.0,
  );

  @override
  void initState() {
    super.initState();
    _loadMarkers();
  }

  void _loadMarkers() {
    // Add any initial markers if needed
    // Example: driver location marker
    _markers.add(
      Marker(
        markerId: MarkerId('driver_location'),
        position: LatLng(33.6844, 73.0479),
        infoWindow: InfoWindow(title: 'Your Location'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SlidingUpPanel(
        color: AppColor.white,
        backdropColor: Colors.transparent,
        margin: EdgeInsets.all(0),
        minHeight: ResSize.h * 360,
        padding: EdgeInsets.symmetric(
          horizontal: screenHorizPadding,
          vertical: ResSize.h * 16,
        ),
        boxShadow: [],
        isDraggable: true,
        defaultPanelState: PanelState.CLOSED,
        maxHeight: MediaQuery.of(context).size.height * 0.85,
        parallaxEnabled: false,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
        panelBuilder: (ScrollController sc) => panelColumn(sc),
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
                  // Any additional map setup can be done here
                },
                onTap: (LatLng position) {
                  // Handle map tap events
                },
              ),
              SizedBox(
                width: double.infinity,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenHorizPadding),
                  child: Column(
                    children: [
                      50.height,
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          InkWell(
                            onTap: () {
                              Navigator.pop(context);
                            },
                            child: Container(
                              height: ResSize.h * 24,
                              width: ResSize.w * 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColor.white,
                                boxShadow: [
                                  BoxShadow(
                                    offset: const Offset(0, 4),
                                    // ignore: deprecated_member_use
                                    color: Color(0xff606060).withOpacity(0.12),
                                    spreadRadius: 6,
                                    blurRadius: 40,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.arrow_back_ios_rounded,
                                  color: AppColor.black,
                                  size: ResSize.h * 18,
                                ),
                              ),
                            ),
                          ),
                          TextWidget(
                            text: "Select Ride",
                            color: AppColor.black,
                            fontSize: 16,
                            fontWeight: fwSemiBold,
                          ),

                          SizedBox(
                            height: ResSize.h * 24,
                            width: ResSize.w * 24,
                          ),
                        ],
                      ),
                      18.height,
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: AppColor.white,
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: ResSize.w * 16,
                            vertical: ResSize.h * 16,
                          ),
                          child: Column(
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Transform.translate(
                                    offset: const Offset(0, 10),
                                    child: SizedBox(
                                      height: ResSize.h * 100,
                                      child: Column(
                                        children: [
                                          verticleCircle(icon: AppAssets.gps),

                                          2.height,
                                          verticleCircle(
                                            icon: AppAssets.location,
                                            removeDottedLine: true,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  12.width,
                                  Expanded(
                                    child: Column(
                                      children: [
                                        horizentalLocation(
                                          title: "Pickup location",
                                          location:
                                              "Sector i11 Street 15, h340",
                                        ),
                                        9.height,
                                        Divider(
                                          height: 0,
                                          thickness: 0.2,
                                          color: AppColor.border,
                                        ),
                                        9.height,
                                        horizentalLocation(
                                          title: "Your destination",
                                          location: "Skypulse solution",
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextWidget(
            fontSize: 14,
            fontWeight: fwMedium,
            text: "Available options",
            color: AppColor.title,
          ),
          8.height,
          SizedBox(
            height: ResSize.h * 75,
            child: ListView.builder(
              itemCount: ridesList.length,
              shrinkWrap: true,
              clipBehavior: Clip.none,
              padding: EdgeInsets.all(0),
              scrollDirection: Axis.horizontal,
              physics: BouncingScrollPhysics(),
              itemBuilder: (BuildContext context, int index) {
                return InkWell(
                  onTap: () {
                    setState(() {
                      selectedRide = index;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: selectedRide == index
                          ? Color(
                              0xff215277,
                              // ignore: deprecated_member_use
                            ).withOpacity(0.10)
                          : Colors.transparent,
                    ),
                    height: ResSize.h * 75,
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: ResSize.w * 13,
                        right: ResSize.w * 13,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Transform.scale(
                              scale:
                                  ridesList[index].image ==
                                      AppAssets.ecoFriendly
                                  ? 1.45
                                  : ridesList[index].image == AppAssets.xl
                                  ? 1
                                  : 1.2,
                              child: Transform.translate(
                                offset: ridesList[index].image == AppAssets.xl
                                    ? Offset(-5, 5)
                                    : ridesList[index].image ==
                                          AppAssets.ecoFriendly
                                    ? Offset(3, 0)
                                    : Offset(0, 0),
                                child: Image.asset(ridesList[index].image),
                              ),
                            ),
                          ),
                          TextWidget(
                            fontSize: 12,
                            fontWeight: fwSemiBold,
                            text: ridesList[index].title,
                            color: AppColor.black,
                          ),
                          TextWidget(
                            fontSize: 12,
                            fontWeight: fwNormal,
                            text: ridesList[index].subTitle,
                            color: AppColor.black,
                          ),
                          4.height,
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          15.height,
          Container(
            height: ResSize.h * 51,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Color(0xffF3F6FB),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: ResSize.w * 12),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: decreasePrice,
                      child: Container(
                        height: ResSize.h * 27,
                        width: ResSize.w * 27,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColor.white,
                        ),
                        child: Center(
                          child: Container(
                            width: ResSize.w * 14,
                            height: ResSize.h * 2,
                            color: AppColor.black,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: increasePrice,
                      child: Container(
                        height: ResSize.h * 27,
                        width: ResSize.w * 27,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColor.white,
                        ),
                        child: Center(
                          child: Icon(Icons.add, color: AppColor.black),
                        ),
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      50.width,
                      TextWidget(
                        text: "\$${price.toStringAsFixed(2)}",
                        color: AppColor.black,
                        fontSize: 20,
                        fontWeight: fwSemiBold,
                      ),
                      7.width,
                      TextWidget(
                        text: "recommend fare",
                        color: AppColor.black,
                        fontSize: 12,
                        fontWeight: fwNormal,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          8.height,
          TextWidget(
            fontSize: 14,
            fontWeight: fwMedium,
            text: "Payment methods",
            color: AppColor.title,
          ),
          14.height,
          ...List.generate(paymentMethods.length, (index) {
            return Padding(
              padding: EdgeInsets.only(top: index == 0 ? 0 : ResSize.h * 8),
              child: InkWell(
                onTap: () {
                  setState(() {
                    selectedMethod = index;
                  });
                },

                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: ResSize.w * 10,
                    vertical: ResSize.h * 8,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: selectedMethod == index
                        ? Border.all(color: Colors.transparent, width: 0)
                        : Border.all(color: AppColor.border, width: 0.4),
                    color: selectedMethod == index
                        ? AppColor.title
                        : Colors.transparent,
                  ),
                  child: Row(
                    children: [
                      index > 1
                          ? Image.asset(
                              paymentMethods[index].image,
                              height: ResSize.h * 25,
                            )
                          : Image.asset(
                              paymentMethods[index].image,
                              height: ResSize.h * 25,
                              color: selectedMethod == index
                                  ? AppColor.white
                                  : AppColor.title,
                            ),
                      12.width,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextWidget(
                              fontSize: 18,
                              fontWeight: fwSemiBold,
                              text: paymentMethods[index].title,
                              color: selectedMethod == index
                                  ? AppColor.whiteText
                                  : AppColor.title,
                            ),
                            TextWidget(
                              fontSize: 12,
                              fontWeight: fwNormal,
                              text: paymentMethods[index].subTitle,
                              color: selectedMethod == index
                                  ? Color(0xffE2E2E2)
                                  : AppColor.subtitle,
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: ResSize.h * 18,
                        color: selectedMethod == index
                            ? AppColor.white
                            : AppColor.subtitle,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),

          19.height,
          CustomButton(
            centerContent: "Confirm",
            onPressed: () {
              Navigator.push(context, BottomToTopTransition(FindingDrivers()));
            },
          ),
        ],
      ),
    );
  }

  Widget verticleCircle({
    String? icon,
    bool isStop = false,
    String? stopText,
    bool removeDottedLine = false,
  }) {
    return Expanded(
      child: Column(
        children: [
          Center(child: Image.asset(icon!, height: ResSize.h * 22)),

          removeDottedLine
              ? 0.height
              : Expanded(
                  child: DottedLine(
                    dashLength: 3,
                    dashGapLength: 3,
                    lineThickness: 1.4,
                    dashColor: AppColor.black,
                    direction: Axis.vertical,
                  ),
                ),
        ],
      ),
    );
  }

  Widget horizentalLocation({String? title, location, bool isStop = false}) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextWidget(
                fontSize: 12,
                fontWeight: fwSemiBold,
                text: title,
                color: Color(0xffA3A3A3),
              ),
              Text(
                location!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: ResSize.setSp(15),
                  fontWeight: fwSemiBold,
                  color: AppColor.black,
                ),
              ),
            ],
          ),
        ),
        TextWidget(
          fontSize: 12,
          fontWeight: fwNormal,
          text: "Edit",
          color: AppColor.primary,
        ),
      ],
    );
  }
}
