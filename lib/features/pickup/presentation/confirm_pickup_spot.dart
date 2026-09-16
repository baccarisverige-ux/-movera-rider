import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:movera_rider/app/di.dart';
import 'package:movera_rider/core/maps/map_owners.dart';
import 'package:movera_rider/core/web/web_overlay.dart';
import 'package:movera_rider/features/pickup/application/pickup_controller.dart';
import 'package:movera_rider/shared/design_system/movera_icon_button.dart';
import 'package:movera_rider/shared/widgets/custom_google_map.dart';
import 'package:movera_rider/shared/widgets/navigation_transition.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

class ConfirmPickupResult {
  const ConfirmPickupResult({required this.position, required this.address});
  final LatLng position;
  final String address;
}

class ConfirmPickupSpot extends StatefulWidget {
  const ConfirmPickupSpot({
    super.key,
    required this.initialPosition,
    required this.initialAddress,
    this.scheduledSummary,
    this.categoryName,
    this.title = 'Confirm pickup spot',
    this.hint = 'Drag map to move pin',
    this.confirmLabel = 'Confirm pickup',
  });

  static Future<ConfirmPickupResult?> open(
    BuildContext context, {
    required LatLng initialPosition,
    required String initialAddress,
    String? scheduledSummary,
    String? categoryName,
    String title = 'Confirm pickup spot',
    String hint = 'Drag map to move pin',
    String confirmLabel = 'Confirm pickup',
  }) {
    return Navigator.of(context).push<ConfirmPickupResult>(
      RightToLeftTransition(
        ConfirmPickupSpot(
          initialPosition: initialPosition,
          initialAddress: initialAddress,
          scheduledSummary: scheduledSummary,
          categoryName: categoryName,
          title: title,
          hint: hint,
          confirmLabel: confirmLabel,
        ),
      ),
    );
  }

  final LatLng initialPosition;
  final String initialAddress;
  final String? scheduledSummary;
  final String? categoryName;
  final String title;
  final String hint;
  final String confirmLabel;

  @override
  State<ConfirmPickupSpot> createState() => _ConfirmPickupSpotState();
}

class _ConfirmPickupSpotState extends State<ConfirmPickupSpot> {
  GoogleMapController? _map;
  late LatLng _center;
  late String _address;
  bool _mapReady = false;
  bool _moving = false;
  final _search = TextEditingController();
  late final PickupMapController _pickup = PickupMapController(
    location: AppScope.instance.location,
    geocoding: AppScope.instance.geocoding,
  );

  static const _radiusMeters = 90.0;

  @override
  void initState() {
    super.initState();
    _center = widget.initialPosition;
    _address = widget.initialAddress;
    _search.text = widget.initialAddress;
    setWebOverlayOpen(false);
    Future<void>.delayed(Duration(milliseconds: kIsWeb ? 280 : 80), () {
      if (mounted) setState(() => _mapReady = true);
    });
  }

  @override
  void dispose() {
    _search.dispose();
    _pickup.dispose();
    AppScope.instance.maps.detach(owner: MapOwners.pickup);
    super.dispose();
  }

  Future<void> _idle() async {
    if (_moving) return;
    final address = await _pickup.reverse(_center);
    if (!mounted || address == null || address.isEmpty) return;
    setState(() {
      _address = address;
      _search.text = address;
    });
  }

  Future<void> _lookup() async {
    final query = _search.text.trim();
    if (query.isEmpty) return;
    final found = await _pickup.search(query);
    if (!mounted || found == null) return;
    setState(() {
      _center = found.position;
      _address = found.address ?? query;
    });
    await _map?.animateCamera(CameraUpdate.newLatLng(_center));
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                if (_mapReady)
                  CustomGoogleMap(
                    initialPosition: CameraPosition(
                      target: _center,
                      zoom: 16.4,
                    ),
                    myLocationEnabled: true,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    mapToolbarEnabled: false,
                    compassEnabled: false,
                    circles: {
                      Circle(
                        circleId: const CircleId('pickup-accuracy'),
                        center: _center,
                        radius: _radiusMeters,
                        fillColor: const Color(
                          0xFF2D5878,
                        ).withValues(alpha: 0.12),
                        strokeColor: const Color(
                          0xFF2D5878,
                        ).withValues(alpha: 0.35),
                        strokeWidth: 1,
                      ),
                    },
                    onMapCreated: (controller) {
                      _map = controller;
                      AppScope.instance.maps.attach(
                        controller,
                        owner: MapOwners.pickup,
                      );
                    },
                    onCameraMove: (position) {
                      _moving = true;
                      _center = position.target;
                    },
                    onCameraIdle: () {
                      _moving = false;
                      setState(() {});
                      _idle();
                    },
                  ),
                const IgnorePointer(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 28),
                      child: Icon(
                        Icons.location_on,
                        size: 44,
                        color: Color(0xFF11181D),
                      ),
                    ),
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                    child: Row(
                      children: [
                        MoveraIconButton.round(
                          icon: Icons.arrow_back_ios_new_rounded,
                          onPressed: () => Navigator.pop(context),
                          label: 'Back',
                          iconSize: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + inset),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1D252C),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.hint,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: const Color(0xFF5C656C),
                  ),
                ),
                if (widget.scheduledSummary != null ||
                    widget.categoryName != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    [
                      if (widget.scheduledSummary != null)
                        widget.scheduledSummary,
                      if (widget.categoryName != null) widget.categoryName,
                    ].join('  ·  '),
                    style: GoogleFonts.poppins(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1D252C),
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                TextField(
                  controller: _search,
                  onSubmitted: (_) => _lookup(),
                  decoration: InputDecoration(
                    hintText: 'Search address',
                    suffixIcon: IconButton(
                      onPressed: _lookup,
                      icon: const Icon(Icons.search_rounded),
                      tooltip: 'Search address',
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF6F8FA),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _address,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: const Color(0xFF5C656C),
                  ),
                ),
                const SizedBox(height: 16),
                PointerInterceptor(
                  child: SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton(
                      onPressed: () => Navigator.pop(
                        context,
                        ConfirmPickupResult(
                          position: _center,
                          address: _address,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF11181D),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        widget.confirmLabel,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
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
