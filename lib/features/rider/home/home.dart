// ignore_for_file: deprecated_member_use

import 'package:dotted_line/dotted_line.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:movera_rider/core/constants/appassets.dart';
import 'package:movera_rider/core/constants/appcolors.dart';
import 'package:movera_rider/core/constants/appfontweight.dart';
import 'package:movera_rider/features/rider/choose%20route/choose_route.dart';
import 'package:movera_rider/features/rider/profile/profile.dart';
import 'package:movera_rider/features/rider/schedule%20ride/schedule_ride.dart';
import 'package:movera_rider/features/rider/side%20menu/side_menu.dart';
import 'package:movera_rider/shared/widgets/custom_google_map.dart';
import 'package:movera_rider/shared/widgets/custom_text_widget.dart';
import 'package:movera_rider/shared/widgets/navigation_transition.dart';
import 'package:movera_rider/shared/widgets/responsive_size.dart';
import 'package:movera_rider/shared/widgets/sizedbox_extention.dart';
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

  // ignore: unused_field
  GoogleMapController? _mapController;
  // ignore: prefer_final_fields
  Set<Marker> _markers = {};

  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(33.6844, 73.0479),
    zoom: 14.0,
  );

  static const Color _premiumInk = Color(0xFF1D252C);
  static const Color _premiumMuted = Color(0xFF778189);
  static const Color _premiumLine = Color(0xFFE7EBEE);
  static const Color _premiumField = Color(0xFFF6F5F1);

  static const String _premiumMapStyle = '''
[
  {
    "featureType": "all",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#4F565C"}]
  },
  {
    "featureType": "all",
    "elementType": "labels.text.stroke",
    "stylers": [{"color": "#FAF8F2"}, {"weight": 2}]
  },
  {
    "featureType": "landscape",
    "elementType": "geometry",
    "stylers": [{"color": "#F4F0E5"}]
  },
  {
    "featureType": "landscape.natural",
    "elementType": "geometry",
    "stylers": [{"color": "#E8EEDB"}]
  },
  {
    "featureType": "poi",
    "elementType": "geometry",
    "stylers": [{"color": "#E9EBDD"}]
  },
  {
    "featureType": "poi.park",
    "elementType": "geometry",
    "stylers": [{"color": "#D4ECC3"}]
  },
  {
    "featureType": "poi.business",
    "elementType": "labels",
    "stylers": [{"visibility": "simplified"}]
  },
  {
    "featureType": "road",
    "elementType": "geometry",
    "stylers": [{"color": "#FFFFFF"}]
  },
  {
    "featureType": "road",
    "elementType": "geometry.stroke",
    "stylers": [{"color": "#D8DEE3"}, {"weight": 0.8}]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry",
    "stylers": [{"color": "#DDE5EC"}]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry.stroke",
    "stylers": [{"color": "#AEBECC"}, {"weight": 1.1}]
  },
  {
    "featureType": "road.arterial",
    "elementType": "geometry",
    "stylers": [{"color": "#F9FAFA"}]
  },
  {
    "featureType": "administrative",
    "elementType": "geometry.stroke",
    "stylers": [{"color": "#C9D2D8"}, {"weight": 0.7}]
  },
  {
    "featureType": "transit",
    "elementType": "geometry",
    "stylers": [{"color": "#E5E9EC"}]
  },
  {
    "featureType": "water",
    "elementType": "geometry",
    "stylers": [{"color": "#BDE3F0"}]
  },
  {
    "featureType": "water",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#607A83"}]
  }
]
''';

  @override
  void initState() {
    super.initState();
    _loadMarkers();
  }

  void _loadMarkers() {
    _markers.add(
      Marker(
        markerId: const MarkerId('driver_location'),
        position: const LatLng(33.6844, 73.0479),
        infoWindow: const InfoWindow(title: 'Your Location'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const RiderSideMenu(),
      drawerScrimColor: Colors.black.withOpacity(0.38),
      body: Stack(
        children: [
          SlidingUpPanel(
            color: AppColor.white,
            backdropColor: Colors.transparent,
            margin: EdgeInsets.zero,
            minHeight: ResSize.h * 215,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.10),
                blurRadius: 28,
                spreadRadius: 0,
                offset: const Offset(0, -8),
              ),
            ],
            isDraggable: true,
            controller: _panelController,
            defaultPanelState: PanelState.CLOSED,
            maxHeight: ResSize.h * 480,
            parallaxEnabled: false,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
            panelBuilder: (ScrollController sc) => panelColumn(sc),
            collapsed: InkWell(
              onTap: () {
                _panelController.open();
              },
              child: const SizedBox(height: 50, width: double.infinity),
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
                    customMapStyle: _premiumMapStyle,
                    onMapCreated: (GoogleMapController controller) {
                      _mapController = controller;
                    },
                    onTap: (LatLng position) {},
                  ),
                  Positioned.fill(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        screenHorizPadding,
                        ResSize.h * 60,
                        screenHorizPadding,
                        0,
                      ),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Builder(
                              builder: (drawerContext) => _premiumFloatingButton(
                                onTap: () {
                                  Scaffold.of(drawerContext).openDrawer();
                                },
                                child: Icon(
                                  Icons.menu_rounded,
                                  size: ResSize.h * 21,
                                  color: _premiumInk,
                                ),
                              ),
                            ),
                            _premiumFloatingButton(
                              onTap: () {
                                if (_panelController.isPanelOpen) {
                                  _panelController.close();
                                }
                                _profilePanelController.open();
                              },
                              child: Icon(
                                Icons.person_outline_rounded,
                                size: ResSize.h * 22,
                                color: _premiumInk,
                              ),
                            ),
                          ],
                        ),
                      ),
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

  Widget _premiumFloatingButton({
    required Widget child,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          height: ResSize.h * 44,
          width: ResSize.w * 44,
          decoration: BoxDecoration(
            color: AppColor.white.withOpacity(0.96),
            shape: BoxShape.circle,
            border: Border.all(color: _premiumLine, width: 0.8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.10),
                blurRadius: 18,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: child,
        ),
      ),
    );
  }

  Widget panelColumn(ScrollController sc) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        screenHorizPadding,
        ResSize.h * 10,
        screenHorizPadding,
        ResSize.h * 20,
      ),
      controller: sc,
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          Container(
            width: ResSize.w * 38,
            height: ResSize.h * 4,
            decoration: BoxDecoration(
              color: const Color(0xFFD6DBDE),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          10.height,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    TextWidget(
                      text: "Plan now with ",
                      fontSize: 17,
                      fontWeight: fwVeryExtraBold,
                      color: _premiumInk,
                    ),
                    Flexible(
                      child: Image.asset(
                        AppAssets.logo,
                        height: ResSize.h * 21,
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    BottomToTopTransition(const ScheduleRide()),
                  );
                },
                borderRadius: BorderRadius.circular(22),
                child: Container(
                  height: ResSize.h * 38,
                  padding: EdgeInsets.symmetric(horizontal: ResSize.w * 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    color: const Color(0xFFF3F4F5),
                    border: Border.all(color: _premiumLine, width: 0.8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        AppAssets.calendar,
                        height: ResSize.h * 17,
                        color: _premiumInk,
                      ),
                      7.width,
                      TextWidget(
                        text: "Later",
                        fontSize: 12.5,
                        fontWeight: fwMedium,
                        color: _premiumInk,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          12.height,
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                height: ResSize.h * 126,
                child: Column(
                  children: [
                    _routePoint(
                      child: Image.asset(
                        AppAssets.gps,
                        height: ResSize.h * 19,
                        color: const Color(0xFF365F57),
                      ),
                    ),
                    Expanded(
                      child: DottedLine(
                        dashLength: 3,
                        dashGapLength: 4,
                        lineThickness: 1.25,
                        dashRadius: 2,
                        dashColor: const Color(0xFF394248),
                        direction: Axis.vertical,
                      ),
                    ),
                    _routePoint(
                      child: Image.asset(
                        AppAssets.location,
                        height: ResSize.h * 19,
                        color: const Color(0xFF365F57),
                      ),
                    ),
                  ],
                ),
              ),
              12.width,
              Expanded(
                child: Column(
                  children: [
                    _routeField(
                      onTap: () {
                        Navigator.push(
                          context,
                          BottomToTopTransition(ChooseRoute()),
                        );
                      },
                      text: "Central Park, DHA",
                    ),
                    12.height,
                    _routeField(
                      onTap: () {
                        Navigator.push(
                          context,
                          BottomToTopTransition(ChooseRoute()),
                        );
                      },
                      text: "Your destination",
                      trailing: Image.asset(
                        AppAssets.mic,
                        color: _premiumMuted,
                        height: ResSize.h * 20,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          18.height,
          const Divider(color: _premiumLine, thickness: 0.8, height: 0),
          16.height,
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: ResSize.w * 12,
              vertical: ResSize.h * 14,
            ),
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: const Color(0xFFF7F9FA),
              border: Border.all(color: _premiumLine, width: 0.8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextWidget(
                  text: "Your Last Trip",
                  color: _premiumInk,
                  fontSize: 16,
                  fontWeight: fwSemiBold,
                ),
                10.height,
                ...List.generate(trips.length, (index) {
                  return Padding(
                    padding: EdgeInsets.only(
                      top: index == 0 ? 0 : ResSize.h * 7,
                    ),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: ResSize.w * 11,
                        vertical: ResSize.h * 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColor.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _premiumLine, width: 0.8),
                      ),
                      child: Row(
                        children: [
                          Container(
                            height: ResSize.h * 36,
                            width: ResSize.w * 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F6F5),
                              borderRadius: BorderRadius.circular(11),
                            ),
                            alignment: Alignment.center,
                            child: Image.asset(
                              AppAssets.location,
                              color: const Color(0xFF365F57),
                              height: ResSize.h * 20,
                            ),
                          ),
                          11.width,
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextWidget(
                                  text: "30 Main Street",
                                  color: _premiumInk,
                                  fontSize: 12,
                                  fontWeight: fwSemiBold,
                                ),
                                3.height,
                                TextWidget(
                                  text: "5.9km|30 Main Street, London",
                                  color: _premiumMuted,
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
                            borderRadius: BorderRadius.circular(20),
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: trips[index]
                                  ? Image.asset(
                                      AppAssets.starFill,
                                      height: ResSize.h * 21,
                                    )
                                  : Image.asset(
                                      AppAssets.star,
                                      color: const Color(0xFF365F57),
                                      height: ResSize.h * 21,
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

  Widget _routePoint({required Widget child}) {
    return Container(
      height: ResSize.h * 38,
      width: ResSize.w * 38,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFF6F8F8),
        border: Border.all(color: _premiumLine, width: 0.8),
      ),
      alignment: Alignment.center,
      child: child,
    );
  }

  Widget _routeField({
    required VoidCallback onTap,
    required String text,
    Widget? trailing,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          height: ResSize.h * 57,
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: ResSize.w * 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: _premiumField,
            border: Border.all(color: const Color(0xFFECEAE5), width: 0.8),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextWidget(
                  fontSize: 16,
                  fontWeight: fwNormal,
                  text: text,
                  color: _premiumMuted,
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
        ),
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
          Container(
            width: ResSize.w * 40,
            height: ResSize.h * 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          20.height,
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
          _buildProfileOption(
            icon: Icons.account_circle_outlined,
            title: "Edit Profile",
            onTap: () {},
          ),
          _buildProfileOption(
            icon: Icons.history,
            title: "Ride History",
            onTap: () {},
          ),
          _buildProfileOption(
            icon: Icons.payment_outlined,
            title: "Payment Methods",
            onTap: () {},
          ),
          _buildProfileOption(
            icon: Icons.notifications_outlined,
            title: "Notifications",
            onTap: () {},
          ),
          _buildProfileOption(
            icon: Icons.help_outline,
            title: "Help & Support",
            onTap: () {},
          ),
          _buildProfileOption(
            icon: Icons.settings_outlined,
            title: "Settings",
            onTap: () {},
          ),
          16.height,
          Divider(color: AppColor.border, thickness: 0.4),
          16.height,
          _buildProfileOption(
            icon: Icons.logout,
            title: "Sign Out",
            onTap: () {},
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
