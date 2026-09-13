import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:movera_rider/app/di.dart';
import 'package:movera_rider/app/router/ride_navigator.dart';
import 'package:movera_rider/core/maps/map_owners.dart';
import 'package:movera_rider/features/active_ride/presentation/waiting_for_driver.dart';
import 'package:movera_rider/features/finding_driver/application/finding_driver_controller.dart';
import 'package:movera_rider/features/finding_driver/presentation/cancel_ride_sheet.dart';
import 'package:movera_rider/features/finding_driver/presentation/ride_details_sheet.dart';
import 'package:movera_rider/features/pickup/presentation/confirm_pickup_spot.dart';
import 'package:movera_rider/features/ride_booking/domain/ride_notes.dart';
import 'package:movera_rider/features/safety/presentation/ride_safety_kit.dart';
import 'package:movera_rider/shared/widgets/custom_google_map.dart';
import 'package:movera_rider/shared/widgets/navigation_transition.dart';
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
    this.notes = RideNotes.empty,
  });

  final String pickupAddress;
  final String destinationAddress;
  final LatLng pickupPosition;
  final LatLng destinationPosition;
  final String rideType;
  final double price;
  final String paymentMethod;
  final RideNotes notes;

  @override
  State<FindingDrivers> createState() => _FindingDriversState();
}

class _FindingDriversState extends State<FindingDrivers> {
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  int remainingSeconds = 12;
  final FindingDriverController _match = FindingDriverController();
  final PanelController _panel = PanelController();
  bool _mapParked = false;

  late String _pickupAddress;
  late LatLng _pickupPosition;
  late final CameraPosition _initialPosition;

  @override
  void initState() {
    super.initState();
    _pickupAddress = widget.pickupAddress;
    _pickupPosition = widget.pickupPosition;
    _initialPosition = CameraPosition(target: _pickupPosition, zoom: 14.0);
    _loadMapBits();
    _match.startFrom(
      pickupAddress: _pickupAddress,
      destinationAddress: widget.destinationAddress,
      pickupLat: _pickupPosition.latitude,
      pickupLng: _pickupPosition.longitude,
      destinationLat: widget.destinationPosition.latitude,
      destinationLng: widget.destinationPosition.longitude,
      rideType: widget.rideType,
      price: widget.price,
      paymentMethod: widget.paymentMethod,
      notes: widget.notes,
      onTick: (remaining) {
        if (mounted) setState(() => remainingSeconds = remaining);
      },
      onMatched: () {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          BottomToTopTransition(
            WaitingForDriver(
              pickupAddress: _pickupAddress,
              destinationAddress: widget.destinationAddress,
              pickupPosition: _pickupPosition,
              destinationPosition: widget.destinationPosition,
              rideType: widget.rideType,
              price: widget.price,
              paymentMethod: widget.paymentMethod,
              notes: widget.notes,
            ),
          ),
        );
      },
    );
  }

  void _loadMapBits() {
    _markers = {
      Marker(
        markerId: const MarkerId('pickup'),
        position: _pickupPosition,
        infoWindow: InfoWindow(title: _pickupAddress),
      ),
      Marker(
        markerId: const MarkerId('destination'),
        position: widget.destinationPosition,
        infoWindow: InfoWindow(title: widget.destinationAddress),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ),
      Marker(
        markerId: const MarkerId('car-a'),
        position: LatLng(_pickupPosition.latitude + 0.0021, _pickupPosition.longitude - 0.0014),
        rotation: 42,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
      ),
      Marker(
        markerId: const MarkerId('car-b'),
        position: LatLng(_pickupPosition.latitude - 0.0016, _pickupPosition.longitude + 0.0022),
        rotation: 210,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
      ),
      Marker(
        markerId: const MarkerId('car-c'),
        position: LatLng(_pickupPosition.latitude + 0.0008, _pickupPosition.longitude + 0.0018),
        rotation: 128,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
      ),
    };
    _polylines = {
      Polyline(
        polylineId: const PolylineId('route'),
        points: [_pickupPosition, widget.destinationPosition],
        color: const Color(0xFF1D252C),
        width: 4,
      ),
    };
  }

  Future<void> _confirmCancel() async {
    final keep = await showCancelRideSheet(
      context,
      takingLonger: remainingSeconds <= 4,
    );
    if (!keep && mounted) {
      _match.cancelSearch();
      RideNavigator.home(context);
    }
  }

  Future<void> _openDetails() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) => RideDetailsSheet(
        pickupAddress: _pickupAddress,
        destinationAddress: widget.destinationAddress,
        rideType: widget.rideType,
        price: widget.price,
        paymentMethod: widget.paymentMethod,
        notes: widget.notes,
        canEditPickup: true,
        onEditPickup: () async {
          Navigator.pop(sheetContext);
          AppScope.instance.maps.detach(owner: MapOwners.finding);
          setState(() => _mapParked = true);
          await Future<void>.delayed(const Duration(milliseconds: 90));
          if (!mounted) return;
          final result = await Navigator.push(
            context,
            RightToLeftTransition(
              ConfirmPickupSpot(
                initialPosition: _pickupPosition,
                initialAddress: _pickupAddress,
              ),
            ),
          );
          if (!mounted) return;
          setState(() {
            _mapParked = false;
            if (result is ConfirmPickupResult) {
              _pickupAddress = result.address;
              _pickupPosition = result.position;
              _loadMapBits();
            }
          });
        },
        onEditDestination: () => Navigator.pop(sheetContext),
        onCancelTrip: () {
          Navigator.pop(sheetContext);
          _confirmCancel();
        },
      ),
    );
  }

  @override
  void dispose() {
    _match.dispose();
    AppScope.instance.maps.detach(owner: MapOwners.finding);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = remainingSeconds <= 0 ? 1.0 : 1 - (remainingSeconds / 12);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmCancel();
      },
      child: Scaffold(
        body: SlidingUpPanel(
          controller: _panel,
          color: Colors.white,
          backdropColor: Colors.transparent,
          minHeight: 292,
          maxHeight: 460,
          isDraggable: true,
          defaultPanelState: PanelState.CLOSED,
          parallaxEnabled: false,
          boxShadow: const [],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          panelBuilder: (sc) => _panelBody(sc, progress),
          body: Stack(
            children: [
              if (!_mapParked)
                CustomGoogleMap(
                  initialPosition: _initialPosition,
                  markers: _markers,
                  polylines: _polylines,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                  compassEnabled: false,
                  trafficEnabled: false,
                  buildingsEnabled: true,
                  indoorViewEnabled: false,
                  mapType: MapType.normal,
                  padding: const EdgeInsets.only(bottom: 292),
                  onMapCreated: (controller) {
                    AppScope.instance.maps.attach(
                      controller,
                      owner: MapOwners.finding,
                    );
                  },
                ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                  child: Row(
                    children: [
                      _roundBtn(Icons.keyboard_arrow_down_rounded, () {
                        if (_panel.isAttached && _panel.isPanelOpen) {
                          _panel.close();
                        } else {
                          _confirmCancel();
                        }
                      }),
                      const Spacer(),
                      SafetyKitMapButton(rideId: _match.ride.rideId),
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

  Widget _panelBody(ScrollController sc, double progress) {
    return SingleChildScrollView(
      controller: sc,
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE7EBEE),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Ride requested',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1D252C),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            remainingSeconds <= 4
                ? "We'll update you as soon as we can"
                : 'Finding drivers nearby',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color(0xFF778189),
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress.clamp(0.08, 1),
              minHeight: 4,
              backgroundColor: const Color(0xFFEAF2F8),
              color: const Color(0xFF2D5878),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE7EBEE)),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${widget.rideType} details',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xFF778189),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Meet at your pickup spot on $_pickupAddress',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1D252C),
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.paymentMethod,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF2D5878),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _openDetails,
                  icon: const Icon(Icons.more_horiz_rounded),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SafetyKitSheetRow(rideId: _match.ride.rideId),
        ],
      ),
    );
  }

  Widget _roundBtn(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, size: 22, color: const Color(0xFF1D252C)),
        ),
      ),
    );
  }
}
