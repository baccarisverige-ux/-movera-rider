import 'package:dotted_line/dotted_line.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:movera/constants/appassets.dart';
import 'package:movera/constants/appcolors.dart';
import 'package:movera/constants/appfontweight.dart';
import 'package:movera/presentation/rider/choose%20route/choose_route.dart';
import 'package:movera/presentation/rider/schedule%20ride/confirm%20booking/confirm_booking.dart';
import 'package:movera/presentation/rider/schedule%20ride/add%20note/add_note.dart';
import 'package:movera/presentation/rider/schedule%20ride/select%20date%20time/select_date_time.dart';
import 'package:movera/presentation/rider/schedule%20ride/select%20ride/select_ride.dart';
import 'package:movera/widgets/custom_google_map.dart';
import 'package:movera/widgets/custom_text_widget.dart';
import 'package:movera/widgets/navigation_transition.dart';
import 'package:movera/widgets/responsive_size.dart';
import 'package:movera/widgets/sizedbox_extention.dart';

class ScheduleRide extends StatefulWidget {
  const ScheduleRide({super.key});

  @override
  State<ScheduleRide> createState() => _ScheduleRideState();
}

class _ScheduleRideState extends State<ScheduleRide> {
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

  int currentStep = 0;

  void goToNextStep() {
    setState(() {
      currentStep = currentStep + 1; // switch to ride selection
    });

    // expand panel after bounds update
  }

  ScrollController sc = ScrollController();

  Widget _buildPanelContent() {
    if (currentStep == 0) {
      return ScheduleDateTimeSelector(onConfirm: goToNextStep, body: body());
    } else if (currentStep == 1) {
      return ScheduleSelectRide(onConfirm: goToNextStep, body: body());
    } else if (currentStep == 2) {
      return ScheduleAddNote(onConfirm: goToNextStep, body: body());
    } else {
      return ScheduleConfirmBooking(body: body());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: _buildPanelContent());
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
          Container(
            height: ResSize.h * 32,
            width: ResSize.w * 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColor.liteBlue,
            ),
            child: Center(
              child: isStop
                  ? TextWidget(
                      text: stopText,
                      fontWeight: fwBold,
                      fontSize: 16,
                      color: AppColor.black,
                    )
                  : Image.asset(icon!, height: ResSize.h * 22),
            ),
          ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextWidget(
          fontSize: 12,
          fontWeight: fwSemiBold,
          text: title,
          color: Color(0xffA3A3A3),
        ),
        Row(
          children: [
            Expanded(
              child: Text(
                location!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: fwSemiBold,
                  color: AppColor.black,
                ),
              ),
            ),
            isStop
                ? Row(
                    children: [
                      10.width,
                      Image.asset(AppAssets.removeStop, height: ResSize.h * 24),
                    ],
                  )
                : SizedBox(),
          ],
        ),
      ],
    );
  }

  Widget body() {
    return SizedBox(
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
                                color: Color(
                                  0xff606060,
                                  // ignore: deprecated_member_use
                                ).withOpacity(0.12),
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
                    ],
                  ),
                  18.height,
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
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
                              SizedBox(
                                height:
                                    ResSize.h * 230, // more height to fit A & B
                                child: Column(
                                  children: [
                                    5.height,
                                    // Pickup Circle
                                    verticleCircle(icon: AppAssets.gps),

                                    2.height,
                                    verticleCircle(isStop: true, stopText: "A"),
                                    2.height,
                                    verticleCircle(isStop: true, stopText: "B"),
                                    2.height,
                                    verticleCircle(
                                      icon: AppAssets.location,
                                      removeDottedLine: true,
                                    ),
                                  ],
                                ),
                              ),
                              12.width,
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          BottomToTopTransition(
                                            const ChooseRoute(),
                                          ),
                                        );
                                      },
                                      child: horizentalLocation(
                                        title: "Pick-Up",
                                        location:
                                            "Club Vista Mare - Dubai - Unit...",
                                      ),
                                    ),
                                    9.height,
                                    Divider(
                                      height: 0,
                                      thickness: 0.2,
                                      color: AppColor.border,
                                    ),
                                    9.height,

                                    horizentalLocation(
                                      title: "Stop Point A",
                                      isStop: true,
                                      location:
                                          "Ab - Dubai - United Arab Emi...",
                                    ),
                                    9.height,
                                    Divider(
                                      height: 0,
                                      thickness: 0.2,
                                      color: AppColor.border,
                                    ),
                                    9.height,

                                    horizentalLocation(
                                      isStop: true,
                                      title: "Stop Point B",
                                      location:
                                          "Club - Dubai - United Arab Emi...",
                                    ),
                                    9.height,
                                    Divider(
                                      height: 0,
                                      thickness: 0.2,
                                      color: AppColor.border,
                                    ),
                                    9.height,

                                    horizentalLocation(
                                      title: "Drop Off",
                                      location:
                                          "JVC - Dubai - United Arab Emi...",
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
    );
  }
}
