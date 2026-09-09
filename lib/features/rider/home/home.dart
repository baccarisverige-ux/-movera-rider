// ignore_for_file: deprecated_member_use

import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:movera_rider/core/constants/appassets.dart';
import 'package:movera_rider/core/constants/appcolors.dart';
import 'package:movera_rider/core/constants/appfontweight.dart';
import 'package:movera_rider/features/rider/choose%20route/choose_route.dart';
import 'package:movera_rider/features/rider/my%20wallet/wallet.dart';
import 'package:movera_rider/features/rider/profile/profile.dart';
import 'package:movera_rider/features/rider/ride%20history/ride_history.dart';
import 'package:movera_rider/features/rider/saved%20places/add%20place/add_place.dart';
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

  static const double _sheetMinHeight = 184;
  static const double _sheetMaxHeight = 294;
  double _sheetHeight = _sheetMinHeight;
  bool _isSheetDragging = false;
  bool _destinationSheetOpen = false;

  // ignore: unused_field
  GoogleMapController? _mapController;
  // ignore: prefer_final_fields
  Set<Marker> _markers = {};

  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(59.3293, 18.0686),
    zoom: 13.0,
  );

  static const Color _premiumInk = Color(0xFF1D252C);
  static const Color _premiumMuted = Color(0xFF778189);
  static const Color _premiumLine = Color(0xFFE7EBEE);
  static const Color _premiumField = Color(0xFFF6F5F1);
  static const Color _premiumAccent = Color(0xFF2D5878);
  static const Color _premiumAccentSoft = Color(0xFFEAF2F8);
  static const Color _premiumSurface = Color(0xFFF7F8F6);

  static const String _premiumMapStyle = '''
[
  {
    "elementType": "geometry",
    "stylers": [{"color": "#eef1e8"}]
  },
  {
    "elementType": "labels.icon",
    "stylers": [{"visibility": "off"}]
  },
  {
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#747974"}]
  },
  {
    "elementType": "labels.text.stroke",
    "stylers": [{"color": "#f7f8f3"}, {"weight": 2}]
  },
  {
    "featureType": "administrative",
    "elementType": "geometry.stroke",
    "stylers": [{"color": "#d9dcd4"}]
  },
  {
    "featureType": "landscape",
    "elementType": "geometry",
    "stylers": [{"color": "#d8edb5"}]
  },
  {
    "featureType": "landscape.man_made",
    "elementType": "geometry",
    "stylers": [{"color": "#f2f2ef"}]
  },
  {
    "featureType": "poi",
    "elementType": "geometry",
    "stylers": [{"color": "#c1e589"}]
  },
  {
    "featureType": "poi.park",
    "elementType": "geometry",
    "stylers": [{"color": "#d8edb5"}]
  },
  {
    "featureType": "road",
    "elementType": "geometry",
    "stylers": [{"color": "#ffffff"}]
  },
  {
    "featureType": "road",
    "elementType": "geometry.stroke",
    "stylers": [{"color": "#d9dcd5"}]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry",
    "stylers": [{"color": "#fffdf5"}]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry.stroke",
    "stylers": [{"color": "#d5d9cf"}]
  },
  {
    "featureType": "transit",
    "elementType": "geometry",
    "stylers": [{"color": "#e6e8e3"}]
  },
  {
    "featureType": "water",
    "elementType": "geometry",
    "stylers": [{"color": "#8fcfe0"}]
  },
  {
    "featureType": "water",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#3f8294"}]
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
        position: const LatLng(59.3293, 18.0686),
        infoWindow: const InfoWindow(title: 'Your Location'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ),
    );
  }

  void _openDestinationSheet() {
    final viewportHeight = MediaQuery.of(context).size.height;
    final topInset = MediaQuery.of(context).padding.top + 8;
    final targetHeight =
        ((viewportHeight - topInset) / ResSize.h).clamp(520.0, 1000.0);
    setState(() {
      _destinationSheetOpen = true;
      _isSheetDragging = false;
      _sheetHeight = targetHeight;
    });
  }

  void _closeDestinationSheet() {
    setState(() {
      _destinationSheetOpen = false;
      _isSheetDragging = false;
      _sheetHeight = _sheetMinHeight;
    });
  }

  void _openRoute() {
    Navigator.push(
      context,
      BottomToTopTransition(ChooseRoute()),
    );
  }

  void _openSchedule() {
    Navigator.push(
      context,
      BottomToTopTransition(const ScheduleRide()),
    );
  }

  void _openRideHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RideHistory()),
    );
  }

  void _openPayment() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const WalletScreen()),
    );
  }

  void _openAddPlace() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddPlace()),
    );
  }

  void _openAccount() {
    if (_panelController.isPanelOpen) {
      _panelController.close();
    }
    _profilePanelController.open();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const RiderSideMenu(),
      drawerScrimColor: Colors.black.withOpacity(0.38),
      body: Stack(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween<double>(end: _sheetHeight),
            duration: _isSheetDragging
                ? Duration.zero
                : const Duration(milliseconds: 340),
            curve: Curves.easeOutCubic,
            builder: (context, sheetHeight, child) {
              final sheetProgress =
                  ((sheetHeight - _sheetMinHeight) /
                          (_sheetMaxHeight - _sheetMinHeight))
                      .clamp(0.0, 1.0);
              return SlidingUpPanel(
            color: AppColor.white,
            backdropColor: Colors.transparent,
            margin: EdgeInsets.zero,
            minHeight: ResSize.h * sheetHeight,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.11),
                blurRadius: 34,
                spreadRadius: 0,
                offset: const Offset(0, -10),
              ),
            ],
            isDraggable: false,
            controller: _panelController,
            defaultPanelState: PanelState.CLOSED,
            maxHeight: ResSize.h * sheetHeight,
            parallaxEnabled: false,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(34),
              topRight: Radius.circular(34),
            ),
            panelBuilder: (_) => const SizedBox.shrink(),
            collapsed: PointerInterceptor(
              child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onVerticalDragStart: (_) {
                if (_destinationSheetOpen) return;
                setState(() => _isSheetDragging = true);
              },
              onVerticalDragUpdate: (details) {
                if (_destinationSheetOpen) return;
                final delta = details.primaryDelta ?? 0;
                setState(() {
                  _sheetHeight =
                      (_sheetHeight - delta).clamp(
                        _sheetMinHeight,
                        _sheetMaxHeight,
                      );
                });
              },
              onVerticalDragEnd: (details) {
                if (_destinationSheetOpen) return;
                final velocity = details.primaryVelocity ?? 0;
                final shouldExpand = velocity < -260 ||
                    (velocity.abs() <= 260 &&
                        _sheetHeight >
                            (_sheetMinHeight + _sheetMaxHeight) / 2);
                setState(() {
                  _isSheetDragging = false;
                  _sheetHeight =
                      shouldExpand ? _sheetMaxHeight : _sheetMinHeight;
                });
              },
              onVerticalDragCancel: () {
                if (_destinationSheetOpen) return;
                setState(() {
                  _isSheetDragging = false;
                  _sheetHeight =
                      _sheetHeight >
                              (_sheetMinHeight + _sheetMaxHeight) / 2
                          ? _sheetMaxHeight
                          : _sheetMinHeight;
                });
              },
              child: _premiumCollapsedSheet(sheetProgress),
            ),
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
                  if (_destinationSheetOpen)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 1.4, sigmaY: 1.4),
                          child: Container(
                            color: AppColor.white.withOpacity(0.05),
                          ),
                        ),
                      ),
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
                              onTap: _openAccount,
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
          );
            },
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

  Widget _premiumCollapsedSheet(double sheetProgress) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFFFFF), Color(0xFFFCFDFD)],
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(34),
          topRight: Radius.circular(34),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                ResSize.w * 18,
                ResSize.h * 11,
                ResSize.w * 18,
                ResSize.h * 7,
              ),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      if (_destinationSheetOpen) {
                        _closeDestinationSheet();
                        return;
                      }
                      setState(() {
                        _isSheetDragging = false;
                        _sheetHeight = _sheetHeight >
                                (_sheetMinHeight + _sheetMaxHeight) / 2
                            ? _sheetMinHeight
                            : _sheetMaxHeight;
                      });
                    },
                    child: Container(
                      width: ResSize.w * 42,
                      height: ResSize.h * 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFCED4D8),
                        borderRadius: BorderRadius.circular(11),
                      ),
                    ),
                  ),
                  15.height,
                  _whereToCard(),
                  IgnorePointer(
                    ignoring: sheetProgress < 0.92,
                    child: ClipRect(
                      child: Align(
                        alignment: Alignment.topCenter,
                        heightFactor: sheetProgress,
                        child: Opacity(
                          opacity: sheetProgress,
                          child: Column(
                            children: [
                              15.height,
                              Row(
                                children: [
                                  Expanded(
                                    child: _quickPlaceCard(
                                      iconAsset: AppAssets.quickHome,
                                      title: 'Home',
                                      subtitle: 'Set location',
                                      onTap: _openRoute,
                                    ),
                                  ),
                                  8.width,
                                  Expanded(
                                    child: _quickPlaceCard(
                                      iconAsset: AppAssets.quickWork,
                                      title: 'Work',
                                      subtitle: 'Set location',
                                      onTap: _openRoute,
                                    ),
                                  ),
                                  8.width,
                                  Expanded(
                                    child: _quickPlaceCard(
                                      iconAsset: AppAssets.quickAdd,
                                      title: 'Add',
                                      subtitle: 'New place',
                                      onTap: _openAddPlace,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 320),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    child: _destinationSheetOpen
                        ? Padding(
                            key: const ValueKey('advance-booking-card'),
                            padding: EdgeInsets.only(top: ResSize.h * 24),
                            child: _advanceBookingCard(),
                          )
                        : const SizedBox.shrink(
                            key: ValueKey('advance-booking-empty'),
                          ),
                  ),

                ],
              ),
            ),
            Positioned(
              left: ResSize.w * 18,
              right: ResSize.w * 18,
              bottom: 0,
              child: Container(
                color: AppColor.white,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Divider(
                      color: Color(0xFFE7EBEE),
                      thickness: 0.8,
                      height: 1,
                    ),
                    9.height,
                    Row(
                      children: [
                        Expanded(
                          child: _premiumBottomNavItem(
                            iconAsset: AppAssets.navMap,
                            label: 'Map',
                            active: true,
                            onTap: () {},
                          ),
                        ),
                        Expanded(
                          child: _premiumBottomNavItem(
                            iconAsset: AppAssets.navPayment,
                            label: 'Payment',
                            onTap: _openPayment,
                          ),
                        ),
                        Expanded(
                          child: _premiumBottomNavItem(
                            iconAsset: AppAssets.navSchedule,
                            label: 'Schedule ride',
                            onTap: _openSchedule,
                          ),
                        ),
                        Expanded(
                          child: _premiumBottomNavItem(
                            iconAsset: AppAssets.navAccount,
                            label: 'Account',
                            onTap: _openAccount,
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
    );
  }

  Widget _advanceBookingCard() {
    return InkWell(
      onTap: _openSchedule,
      borderRadius: BorderRadius.circular(26),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(
          ResSize.w * 12,
          ResSize.h * 12,
          ResSize.w * 12,
          ResSize.h * 15,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFA),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: _premiumLine, width: 0.8),
          boxShadow: [
            BoxShadow(
              color: _premiumAccent.withOpacity(0.06),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: SizedBox(
                width: double.infinity,
                height: ResSize.h * 142,
                child: Image.asset(
                  'assets/images/advance_booking_driver.png',
                  fit: BoxFit.cover,
                  alignment: const Alignment(0, -0.28),
                  filterQuality: FilterQuality.high,
                ),
              ),
            ),
            15.height,
            TextWidget(
              text: 'Plan ahead. Ride on time.',
              color: _premiumInk,
              fontSize: 17,
              fontWeight: fwBold,
            ),
            7.height,
            Padding(
              padding: EdgeInsets.symmetric(horizontal: ResSize.w * 8),
              child: TextWidget(
                text:
                    'Book your ride in advance and we’ll help arrange a driver for the time you choose.',
                color: _premiumMuted,
                fontSize: 11.5,
                fontWeight: fwNormal,
                textAlign: TextAlign.center,
              ),
            ),
            14.height,
            Container(
              height: ResSize.h * 42,
              width: double.infinity,
              decoration: BoxDecoration(
                color: _premiumAccent,
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: TextWidget(
                text: 'Schedule a ride',
                color: AppColor.white,
                fontSize: 12.5,
                fontWeight: fwSemiBold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _whereToCard() {
    return Container(
      height: ResSize.h * 58,
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        ResSize.w * 4,
        0,
        ResSize.w * 7,
        0,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9F9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8EDEF), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF173B4D).withOpacity(0.035),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _openDestinationSheet,
                borderRadius: BorderRadius.circular(18),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: ResSize.w * 13),
                  child: Row(
                    children: [
                      Icon(
                        Icons.search_rounded,
                        size: ResSize.h * 26,
                        color: _premiumInk,
                      ),
                      12.width,
                      Expanded(
                        child: TextWidget(
                          text: 'Where to?',
                          color: _premiumInk.withOpacity(0.72),
                          fontSize: 16.5,
                          fontWeight: fwMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _openSchedule,
              borderRadius: BorderRadius.circular(18),
              child: Container(
                height: ResSize.h * 28.4,
                padding: EdgeInsets.symmetric(horizontal: ResSize.w * 8),
                decoration: BoxDecoration(
                  color: AppColor.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _premiumLine, width: 0.8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.045),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      AppAssets.navSchedule,
                      height: ResSize.h * 20.4,
                      width: ResSize.w * 20.4,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                    ),
                    4.width,
                    TextWidget(
                      text: 'Later',
                      color: _premiumInk,
                      fontSize: 9.2,
                      fontWeight: fwSemiBold,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickPlaceCard({
    required String iconAsset,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: ResSize.h * 44,
          padding: EdgeInsets.symmetric(horizontal: ResSize.w * 9),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFFFFF), Color(0xFFF5F9F9)],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFFDDE7E9),
              width: 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF174E55).withOpacity(0.055),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: AppColor.white.withOpacity(0.9),
                blurRadius: 2,
                offset: const Offset(0, -1),
              ),
            ],
          ),
          child: Row(
            children: [
              Image.asset(
                iconAsset,
                height: ResSize.h * 12.3,
                width: ResSize.w * 12.3,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
              8.width,
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextWidget(
                      text: title,
                      color: _premiumInk,
                      fontSize: 11.5,
                      fontWeight: fwSemiBold,
                    ),
                    2.height,
                    TextWidget(
                      text: subtitle,
                      color: _premiumMuted.withOpacity(0.82),
                      fontSize: 8.25,
                      fontWeight: fwNormal,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _premiumBottomNavItem({
    required String iconAsset,
    required String label,
    required VoidCallback onTap,
    bool active = false,
  }) {
    final color =
        active ? const Color(0xFF2A7A84) : const Color(0xFF899197);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          height: ResSize.h * 52,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: ResSize.h * 30,
                width: ResSize.w * 30,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Opacity(
                  opacity: active ? 1 : 0.86,
                  child: Image.asset(
                    iconAsset,
                    height: ResSize.h * 18.68,
                    width: ResSize.w * 18.68,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  ),
                ),
              ),
              3.height,
              TextWidget(
                text: label,
                color: color,
                fontSize: 9.5,
                fontWeight: active ? fwSemiBold : fwMedium,
              ),
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
