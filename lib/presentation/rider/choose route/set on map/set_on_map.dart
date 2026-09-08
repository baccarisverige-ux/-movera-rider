import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:movera/constants/appassets.dart';
import 'package:movera/constants/appcolors.dart';
import 'package:movera/constants/appfontweight.dart';
import 'package:movera/presentation/rider/select%20ride/select_ride.dart';
import 'package:movera/widgets/custom_btn.dart';
import 'package:movera/widgets/custom_google_map.dart';
import 'package:movera/widgets/custom_text_widget.dart';
import 'package:movera/widgets/navigation_transition.dart';
import 'package:movera/widgets/responsive_size.dart';
import 'package:movera/widgets/sizedbox_extention.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

class ChooseRouteOnMap extends StatefulWidget {
  const ChooseRouteOnMap({super.key});

  @override
  State<ChooseRouteOnMap> createState() => _ChooseRouteOnMapState();
}

class _ChooseRouteOnMapState extends State<ChooseRouteOnMap> {
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
        minHeight: ResSize.h * 164,
        padding: EdgeInsets.symmetric(
          horizontal: screenHorizPadding,
          vertical: ResSize.h * 16,
        ),
        boxShadow: [],
        isDraggable: true,
        defaultPanelState: PanelState.CLOSED,
        maxHeight: ResSize.h * 164,
        parallaxEnabled: false,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
        panelBuilder: (ScrollController sc) => panelColumn(sc, context),
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
      ),
    );
  }

  Widget panelColumn(ScrollController sc, BuildContext context) {
    return Column(
      children: [
        Container(
          height: ResSize.h * 53,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: AppColor.liteGrey,
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: ResSize.w * 16),
            child: Row(
              children: [
                Image.asset(AppAssets.locationFill, height: ResSize.h * 22),
                8.width,
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
        19.height,
        CustomButton(
          centerContent: "Confirm pickup",
          onPressed: () {
            Navigator.push(context, RightToLeftTransition(SelectRide()));
          },
        ),
      ],
    );
  }
}
