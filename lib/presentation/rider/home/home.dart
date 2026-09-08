// ignore_for_file: deprecated_member_use

import 'package:dotted_line/dotted_line.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:movera/constants/appassets.dart';
import 'package:movera/constants/appcolors.dart';
import 'package:movera/constants/appfontweight.dart';
import 'package:movera/presentation/rider/choose%20route/choose_route.dart';
import 'package:movera/presentation/rider/profile/profile.dart';
import 'package:movera/presentation/rider/schedule%20ride/schedule_ride.dart';
import 'package:movera/presentation/rider/side%20menu/side_menu.dart';
import 'package:movera/widgets/custom_google_map.dart';
import 'package:movera/widgets/custom_text_widget.dart';
import 'package:movera/widgets/navigation_transition.dart';
import 'package:movera/widgets/responsive_size.dart';
import 'package:movera/widgets/sizedbox_extention.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final PanelController _panelController = PanelController();
  final PanelController _profilePanelController = PanelController();

  List<bool> trips = List.generate(3, (index) {
    return false;
  });
  // To track if profile panel is open or not
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
      drawer: const RiderSideMenu(),
      body: Stack(
        children: [
          // Main Panel (Ride Panel)
          SlidingUpPanel(
            color: AppColor.white,
            backdropColor: Colors.transparent,
            margin: EdgeInsets.all(0),
            minHeight: ResSize.h * 205,
            boxShadow: [],
            isDraggable: true,
            controller: _panelController,
            defaultPanelState: PanelState.CLOSED,
            maxHeight: ResSize.h * 480,
            parallaxEnabled: false,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            panelBuilder: (ScrollController sc) => panelColumn(sc),
            collapsed: InkWell(
              onTap: () {
                _panelController.open();
              },
              child: SizedBox(height: 50, width: double.infinity),
            ),
            body: SizedBox(
              height: MediaQuery.of(context).size.height,
              width: double.infinity,
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
                    height: MediaQuery.of(context).size.height,
                    width: double.infinity,

                    child: Stack(
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: ResSize.h * 60,
                            horizontal: screenHorizPadding,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                height: ResSize.h * 30,
                                width: ResSize.w * 30,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColor.white,
                                ),
                                child: Builder(
                                  builder: (context) => GestureDetector(
                                    onTap: () {
                                      Scaffold.of(context).openDrawer();
                                    },
                                    child: Center(
                                      child: Icon(
                                        Icons.menu_rounded,
                                        size: ResSize.h * 20,
                                        color: AppColor.black,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  // Close main panel if open
                                  if (_panelController.isPanelOpen) {
                                    _panelController.close();
                                  }
                                  // Open profile panel
                                  _profilePanelController.open();
                                },
                                child: Container(
                                  height: ResSize.h * 30,
                                  width: ResSize.w * 30,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColor.white,
                                  ),
                                  child: Center(
                                    child: Icon(
                                      Icons.person_outline_rounded,
                                      size: ResSize.h * 22,
                                      color: AppColor.black,
                                    ),
                                  ),
                                ),
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
          ),

          RiderProfile(
            controller: _profilePanelController,
            onClose: () {
              _profilePanelController.close();
            },
          ),
        ],
      ),
    );
  }

  Widget panelColumn(ScrollController sc) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: screenHorizPadding),
      controller: sc,
      child: Column(
        children: [
          6.height,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  TextWidget(
                    text: "Plan now with ",
                    fontSize: 16,
                    fontWeight: fwVeryExtraBold,
                    color: AppColor.title,
                  ),
                  Image.asset(AppAssets.logo, height: ResSize.h * 22),
                ],
              ),
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    BottomToTopTransition(const ScheduleRide()),
                  );
                },
                icon: Container(
                  height: ResSize.h * 30,
                  padding: EdgeInsets.symmetric(horizontal: ResSize.w * 9),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                    color: Color(0xff233C8E).withOpacity(0.10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Image.asset(AppAssets.calendar, height: ResSize.h * 18),
                      7.width,
                      TextWidget(
                        text: "Later",
                        fontSize: 12,
                        fontWeight: fwMedium,
                        color: AppColor.title,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          6.height,
          Row(
            children: [
              SizedBox(
                height: ResSize.h * 102,
                child: Column(
                  children: [
                    Container(
                      height: ResSize.h * 34,
                      width: ResSize.w * 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColor.liteBlue,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(6.0),
                        child: Image.asset(AppAssets.gps),
                      ),
                    ),
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
                    Container(
                      height: ResSize.h * 34,
                      width: ResSize.w * 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColor.liteBlue,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(6.0),
                        child: Image.asset(AppAssets.location),
                      ),
                    ),
                  ],
                ),
              ),
              12.width,
              Expanded(
                child: Column(
                  children: [
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          BottomToTopTransition(ChooseRoute()),
                        );
                      },
                      child: Container(
                        height: ResSize.h * 53,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: AppColor.liteGrey,
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: ResSize.w * 16,
                          ),
                          child: Row(
                            children: [
                              TextWidget(
                                fontSize: 16,
                                fontWeight: fwNormal,
                                text: "Central Park, DHA",
                                color: AppColor.subtitle,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    16.height,
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          BottomToTopTransition(ChooseRoute()),
                        );
                      },
                      child: Container(
                        height: ResSize.h * 53,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: AppColor.liteGrey,
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: ResSize.w * 16,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextWidget(
                                  fontSize: 16,
                                  fontWeight: fwNormal,
                                  text: "Your destination",
                                  color: AppColor.subtitle,
                                ),
                              ),
                              Image.asset(
                                AppAssets.mic,
                                color: AppColor.subtitle,
                                height: ResSize.h * 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          16.height,
          Divider(color: AppColor.border, thickness: 0.4, height: 0),
          16.height,
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: ResSize.w * 10,
              vertical: ResSize.h * 14,
            ),
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: AppColor.liteBlue,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextWidget(
                  text: "Your Last Trip",
                  color: AppColor.black,
                  fontSize: 16,
                  fontWeight: fwSemiBold,
                ),
                10.height,
                ...List.generate(trips.length, (index) {
                  return Padding(
                    padding: EdgeInsets.only(
                      top: index == 0 ? 0 : ResSize.h * 5,
                    ),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: ResSize.w * 10,
                        vertical: ResSize.h * 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColor.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColor.border, width: 0.5),
                      ),
                      child: Row(
                        children: [
                          Image.asset(
                            AppAssets.location,
                            height: ResSize.h * 24,
                          ),
                          12.width,
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextWidget(
                                  text: "30 Main Street",
                                  color: AppColor.black,
                                  fontSize: 12,
                                  fontWeight: fwSemiBold,
                                ),
                                2.height,
                                TextWidget(
                                  text: "5.9km|30 Main Street, London",
                                  color: Color(0xff5E5E5E),
                                  fontSize: 10,
                                  fontWeight: fwNormal,
                                ),
                              ],
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              setState(() {
                                trips[index] = !trips[index];
                              });
                            },
                            child: Container(
                              child: trips[index]
                                  ? Image.asset(
                                      AppAssets.starFill,
                                      height: ResSize.h * 22,
                                    )
                                  : Image.asset(
                                      AppAssets.star,
                                      color: Color(0xff083321),
                                      height: ResSize.h * 22,
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget profilePanelColumn(ScrollController sc) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: screenHorizPadding,
        vertical: ResSize.h * 20,
      ),
      controller: sc,
      child: Column(
        children: [
          // Handle bar
          Container(
            width: ResSize.w * 40,
            height: ResSize.h * 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          20.height,

          // Profile Header
          Row(
            children: [
              Container(
                height: ResSize.h * 60,
                width: ResSize.w * 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColor.liteBlue,
                ),
                child: Center(
                  child: Icon(
                    Icons.person,
                    size: ResSize.h * 35,
                    color: Colors.white,
                  ),
                ),
              ),
              16.width,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextWidget(
                      text: "John Doe",
                      fontSize: 18,
                      fontWeight: fwBold,
                      color: AppColor.title,
                    ),
                    4.height,
                    TextWidget(
                      text: "john.doe@email.com",
                      fontSize: 14,
                      fontWeight: fwNormal,
                      color: AppColor.subtitle,
                    ),
                    4.height,
                    Row(
                      children: [
                        Icon(
                          Icons.star,
                          size: ResSize.h * 16,
                          color: Colors.amber,
                        ),
                        4.width,
                        TextWidget(
                          text: "4.8 (125 rides)",
                          fontSize: 12,
                          fontWeight: fwMedium,
                          color: AppColor.subtitle,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  _profilePanelController.close();
                },
                child: Container(
                  height: ResSize.h * 30,
                  width: ResSize.w * 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey[100],
                  ),
                  child: Center(
                    child: Icon(
                      Icons.close,
                      size: ResSize.h * 20,
                      color: AppColor.title,
                    ),
                  ),
                ),
              ),
            ],
          ),

          24.height,
          // Profile Options
          _buildProfileOption(
            icon: Icons.account_circle_outlined,
            title: "Edit Profile",
            onTap: () {
              // Handle edit profile
            },
          ),
          _buildProfileOption(
            icon: Icons.history,
            title: "Ride History",
            onTap: () {
              // Handle ride history
            },
          ),
          _buildProfileOption(
            icon: Icons.payment_outlined,
            title: "Payment Methods",
            onTap: () {
              // Handle payment methods
            },
          ),
          _buildProfileOption(
            icon: Icons.notifications_outlined,
            title: "Notifications",
            onTap: () {
              // Handle notifications
            },
          ),
          _buildProfileOption(
            icon: Icons.help_outline,
            title: "Help & Support",
            onTap: () {
              // Handle help
            },
          ),
          _buildProfileOption(
            icon: Icons.settings_outlined,
            title: "Settings",
            onTap: () {
              // Handle settings
            },
          ),
          16.height,
          Divider(color: AppColor.border, thickness: 0.4),
          16.height,
          _buildProfileOption(
            icon: Icons.logout,
            title: "Sign Out",
            onTap: () {
              // Handle sign out
            },
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: ResSize.h * 16,
          horizontal: ResSize.w * 4,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: ResSize.h * 24,
              color: isDestructive ? Colors.red : AppColor.title,
            ),
            16.width,
            Expanded(
              child: TextWidget(
                text: title,
                fontSize: 16,
                fontWeight: fwMedium,
                color: isDestructive ? Colors.red : AppColor.title,
              ),
            ),
            if (!isDestructive)
              Icon(
                Icons.arrow_forward_ios,
                size: ResSize.h * 16,
                color: AppColor.subtitle,
              ),
          ],
        ),
      ),
    );
  }
}
