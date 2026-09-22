import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:movera_rider/app/di.dart';
import 'package:movera_rider/app/router/home_history_observer.dart';
import 'package:movera_rider/app/router/ride_navigator.dart';
import 'package:movera_rider/core/constants/appassets.dart';
import 'package:movera_rider/core/maps/geo_point.dart';
import 'package:movera_rider/core/maps/map_owners.dart';
import 'package:movera_rider/core/maps/route_polyline.dart';
import 'package:movera_rider/core/web/web_overlay.dart';
import 'package:movera_rider/features/active_ride/presentation/waiting_for_driver.dart';
import 'package:movera_rider/features/finding_driver/application/finding_driver_controller.dart';
import 'package:movera_rider/features/finding_driver/domain/cancellation_reason.dart';
import 'package:movera_rider/features/finding_driver/presentation/cancel_ride_sheet.dart';
import 'package:movera_rider/features/finding_driver/presentation/price_bump_card.dart';
import 'package:movera_rider/features/finding_driver/presentation/ride_details_sheet.dart';
import 'package:movera_rider/features/active_ride/presentation/ride_terminal_state_sheet.dart';
import 'package:movera_rider/features/pickup/presentation/confirm_pickup_spot.dart';
import 'package:movera_rider/features/ride_booking/domain/ride_notes.dart';
import 'package:movera_rider/features/ride_booking/domain/ride_status.dart';
import 'package:movera_rider/features/safety/presentation/ride_safety_kit.dart';
import 'package:movera_rider/shared/design_system/motion/movera_motion.dart';
import 'package:movera_rider/shared/design_system/movera_icon_button.dart';
import 'package:movera_rider/shared/design_system/movera_sheet.dart';
import 'package:movera_rider/shared/widgets/custom_google_map.dart';
import 'package:movera_rider/shared/widgets/movera_map_markers.dart';
import 'package:movera_rider/shared/widgets/navigation_transition.dart';
import 'package:movera_rider/shared/widgets/realtime_connection_banner.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:smooth_sheets/smooth_sheets.dart';

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
  final FindingDriverController _match = FindingDriverController();
  bool _mapParked = false;
  bool _mapReady = false;
  bool _leaving = false;
  bool _cancelSheetOpen = false;
  bool _pickupEditOpen = false;
  bool _detailsSheetOpen = false;
  bool _matchedPending = false;
  RideStatus? _terminalPending;
  bool _overlayOn = false;
  int _nearbyPaintKey = 0;
  final SheetController _sheetController = SheetController();
  BitmapDescriptor? _riderPuck;
  BitmapDescriptor? _driverCar;
  List<LatLng>? _roadRoutePoints;

  late String _pickupAddress;
  late LatLng _pickupPosition;

  @override
  void initState() {
    super.initState();
    _pickupAddress = widget.pickupAddress;
    _pickupPosition = widget.pickupPosition;
    _sheetController.addListener(_syncSheetOverlay);
    moveraNavigationEpoch.addListener(_onNavigationChanged);
    _syncSheetOverlay();
    _loadMapBits();
    unawaited(_prepareMapVisuals());
    _startMatching(price: widget.price);
  }

  void _startMatching({double? price}) {
    final effectivePrice =
        price ?? (_match.currentPrice > 0 ? _match.currentPrice : widget.price);
    _match.startFrom(
      pickupAddress: _pickupAddress,
      destinationAddress: widget.destinationAddress,
      pickupLat: _pickupPosition.latitude,
      pickupLng: _pickupPosition.longitude,
      destinationLat: widget.destinationPosition.latitude,
      destinationLng: widget.destinationPosition.longitude,
      rideType: widget.rideType,
      price: effectivePrice,
      paymentMethod: widget.paymentMethod,
      notes: widget.notes,
      onTick: (_) {
        if (!mounted) return;
        final nearbyKey = Object.hashAll(
          _match.nearby.map((vehicle) => '${vehicle.id}:${vehicle.latitude}'),
        );
        if (nearbyKey != _nearbyPaintKey) {
          _nearbyPaintKey = nearbyKey;
          _loadMapBits();
        }
        setState(() {});
        _syncSheetOverlay();
      },
      onMatched: () {
        if (!mounted || _leaving) return;
        _matchedPending = true;
        _drainDeferredNavigation();
      },
      onTerminal: (status) {
        if (!mounted || _leaving) return;
        _terminalPending = status;
        _drainDeferredNavigation();
      },
    );
  }

  bool get _routeIsCurrent => ModalRoute.of(context)?.isCurrent ?? true;

  void _onNavigationChanged() {
    if (!mounted) return;
    // NavigatorObserver notifications fire while Navigator is still locked.
    // A deferred match/terminal may need to push a route, so drain it only
    // after the current push/pop has fully committed.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _drainDeferredNavigation();
    });
  }

  void _drainDeferredNavigation() {
    if (!mounted ||
        _leaving ||
        !_routeIsCurrent ||
        _cancelSheetOpen ||
        _pickupEditOpen ||
        _detailsSheetOpen) {
      return;
    }

    final terminal = _terminalPending;
    if (terminal != null) {
      _terminalPending = null;
      _matchedPending = false;
      unawaited(_handleTerminal(terminal));
      return;
    }

    if (_matchedPending) {
      _matchedPending = false;
      unawaited(_openWaiting());
    }
  }

  void _resumeFindingAfterDriverCancel() {
    if (!mounted) return;
    final effectivePrice =
        _match.currentPrice > 0 ? _match.currentPrice : widget.price;
    _leaving = false;
    _cancelSheetOpen = false;
    _pickupEditOpen = false;
    _overlayOn = false;
    _nearbyPaintKey = 0;
    setWebOverlayOpen(false);
    setState(() => _mapParked = false);
    _startMatching(price: effectivePrice);
    _loadMapBits();
  }

  Future<void> _handleTerminal(RideStatus status) async {
    if (!mounted || _leaving) return;
    _leaving = true;
    setState(() {});
    await showRideTerminalStateSheet(context, status: status);
    if (!mounted) return;
    RideNavigator.home(context, status: status);
  }

  void _loadMapBits() {
    final routePoints = _roadRoutePoints;
    _markers = {
      Marker(
        markerId: const MarkerId('pickup'),
        position: _pickupPosition,
        infoWindow: InfoWindow(title: _pickupAddress),
        icon:
            _riderPuck ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        anchor: const Offset(0.5, 0.72),
      ),
      Marker(
        markerId: const MarkerId('destination'),
        position: widget.destinationPosition,
        infoWindow: InfoWindow(title: widget.destinationAddress),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ),
      for (final vehicle in _match.nearby)
        Marker(
          markerId: MarkerId('nearby-${vehicle.id}'),
          position: LatLng(vehicle.latitude, vehicle.longitude),
          rotation: vehicle.bearing,
          flat: true,
          anchor: const Offset(0.5, 0.5),
          icon:
              _driverCar ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
        ),
    };
    _polylines = {
      if (routePoints != null && routePoints.length >= 2)
        Polyline(
          polylineId: const PolylineId('route'),
          points: routePoints,
          color: const Color(0xFF1D252C),
          width: 4,
        )
      else
        routePolyline(
          id: 'route',
          from: _pickupPosition,
          to: widget.destinationPosition,
          color: const Color(0xFF1D252C),
        ),
    };
  }

  Future<void> _prepareMapVisuals() async {
    final icons = await Future.wait<BitmapDescriptor>([
      MoveraRiderPuckMarker.createIcon(),
      MoveraVehicleMarker.createIcon(),
    ]);
    if (!mounted) return;
    _riderPuck = icons[0];
    _driverCar = icons[1];
    _loadMapBits();
    setState(() {});
  }

  Future<void> _refreshRoadRoute() async {
    final points = await AppScope.instance.routing.roadLine(
      from: GeoPoint(_pickupPosition.latitude, _pickupPosition.longitude),
      to: GeoPoint(
        widget.destinationPosition.latitude,
        widget.destinationPosition.longitude,
      ),
    );
    if (!mounted || points.length < 2) return;
    _roadRoutePoints = [
      for (final point in points) LatLng(point.latitude, point.longitude),
    ];
    _loadMapBits();
    setState(() {});
  }

  Future<void> _openWaiting() async {
    if (!mounted || _leaving) return;
    _leaving = true;

    // Freeze and detach this map before the next map-heavy ride stage. Keeping
    // Finding alive but parked prevents SelectRide/Home from resuming their maps
    // underneath the active ride.
    _match.dispose();
    setWebOverlayOpen(false);
    AppScope.instance.maps.detach(owner: MapOwners.finding);
    if (mounted) setState(() => _mapParked = true);
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;

    final researchDriver = await Navigator.push<bool>(
      context,
      RideStageTransition(
        WaitingForDriver(
          pickupAddress: _pickupAddress,
          destinationAddress: widget.destinationAddress,
          pickupPosition: _pickupPosition,
          destinationPosition: widget.destinationPosition,
          rideType: widget.rideType,
          price: _match.currentPrice,
          paymentMethod: widget.paymentMethod,
          notes: widget.notes,
          driver: _match.matchedDriver,
        ),
      ),
    );
    if (!mounted || researchDriver != true) return;
    _resumeFindingAfterDriverCancel();
  }

  Future<void> _confirmCancel() async {
    if (_leaving) return;
    _cancelSheetOpen = true;
    final outcome = await showCancelRideSheet(
      context,
      takingLonger: _match.isDelayed,
      phase: CancelPhase.searching,
    );
    if (!mounted) {
      _cancelSheetOpen = false;
      return;
    }
    _cancelSheetOpen = false;
    if (_terminalPending != null) {
      _drainDeferredNavigation();
      return;
    }
    if (!outcome.cancelled) {
      _drainDeferredNavigation();
      return;
    }
    _leaving = true;
    setState(() {});
    await _match.cancelSearch(reasonId: outcome.reasonId);
    if (!mounted) return;
    RideNavigator.home(context);
  }

  Future<void> _openDetails() async {
    if (_detailsSheetOpen || _leaving) return;
    _detailsSheetOpen = true;
    try {
      await MoveraSheet.show<void>(
        context: context,
      builder: (sheetContext) => RideDetailsSheet(
        pickupAddress: _pickupAddress,
        destinationAddress: widget.destinationAddress,
        rideType: widget.rideType,
        price: _match.currentPrice,
        paymentMethod: widget.paymentMethod,
        notes: widget.notes,
        canEditPickup: true,
        canEditDestination: false,
        onEditPickup: () async {
          AppScope.instance.maps.detach(owner: MapOwners.finding);
          if (!mounted) return;
          setState(() {
            _mapParked = true;
            _pickupEditOpen = true;
          });
          await popCurrentRouteAndWaitForExit(sheetContext);
          if (!mounted) return;
          await WidgetsBinding.instance.endOfFrame;
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

          var updated = false;
          if (result is ConfirmPickupResult && _match.matchCount == 0) {
            updated = await _match.updatePickup(
              address: result.address,
              latitude: result.position.latitude,
              longitude: result.position.longitude,
            );
          }
          if (!mounted) return;

          setState(() {
            _mapParked = false;
            _pickupEditOpen = false;
            if (updated && result is ConfirmPickupResult) {
              _pickupAddress = result.address;
              _pickupPosition = result.position;
              _roadRoutePoints = null;
              _loadMapBits();
            }
          });
          if (updated && result is ConfirmPickupResult && _mapReady) {
            unawaited(_refreshRoadRoute());
          }

          if (_match.matchCount == 1) _matchedPending = true;
          _drainDeferredNavigation();
        },
        onEditDestination: () => Navigator.pop(sheetContext),
        onCancelTrip: () async {
          _cancelSheetOpen = true;
          await popCurrentRouteAndWaitForExit(sheetContext);
          if (!mounted) {
            _cancelSheetOpen = false;
            return;
          }
          await _confirmCancel();
        },
      ),
      );
    } finally {
      _detailsSheetOpen = false;
      if (mounted) _drainDeferredNavigation();
    }
  }

  @override
  void dispose() {
    moveraNavigationEpoch.removeListener(_onNavigationChanged);
    _sheetController.removeListener(_syncSheetOverlay);
    _sheetController.dispose();
    if (!_leaving && _match.matchCount == 0) {
      unawaited(_match.cancelSearch());
    }
    _match.dispose();
    setWebOverlayOpen(false);
    AppScope.instance.maps.detach(owner: MapOwners.finding);
    super.dispose();
  }

  void _syncSheetOverlay() {
    final media = MediaQuery.maybeOf(context);
    final offset = _sheetController.hasClient
        ? _sheetController.metrics?.offset
        : null;
    final minSheet = media == null ? 0.0 : _minSheet(media);
    final cover =
        (offset != null && offset > minSheet + 12) || _match.showPriceBump;
    if (cover == _overlayOn) return;
    _overlayOn = cover;
    setWebOverlayOpen(cover);
  }

  String _shortPlace(String value) {
    final parts = value
        .split(',')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .where((part) => !RegExp(r'^\d{3,}$').hasMatch(part))
        .toList();
    if (parts.isEmpty) return value;
    if (parts.length == 1) return parts.first;
    return '${parts[0]}, ${parts[1]}';
  }

  double _minSheet(MediaQueryData media) {
    final base = _match.showPriceBump ? 520.0 : 332.0;
    return base + media.padding.bottom;
  }

  double _maxSheet(MediaQueryData media) {
    final minH = _minSheet(media);
    final maxH = media.size.height - media.padding.top - 72;
    return maxH < minH + 48 ? minH + 48 : maxH;
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final copy = _match.copy;
    final progress = (_match.elapsedSeconds / 90).clamp(0.08, 0.86);
    const mapReserve = 300.0;
    return PopScope(
      canPop: _leaving,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmCancel();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F5F1),
        body: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              bottom: mapReserve,
              child: RepaintBoundary(
                child: _mapParked
                    ? const ColoredBox(color: Color(0xFFF6F5F1))
                    : CustomGoogleMap(
                        key: const ValueKey('finding-map'),
                        initialPosition: CameraPosition(
                          target: _pickupPosition,
                          zoom: 14.0,
                        ),
                        markers: _markers,
                        polylines: _polylines,
                        myLocationEnabled: true,
                        myLocationButtonEnabled: false,
                        zoomControlsEnabled: false,
                        mapToolbarEnabled: false,
                        compassEnabled: false,
                        trafficEnabled: false,
                        buildingsEnabled: false,
                        indoorViewEnabled: false,
                        tiltGesturesEnabled: false,
                        rotateGesturesEnabled: false,
                        mapType: MapType.normal,
                        onMapCreated: (controller) {
                          _mapReady = true;
                          AppScope.instance.maps.attach(
                            controller,
                            owner: MapOwners.finding,
                          );
                          unawaited(_refreshRoadRoute());
                        },
                      ),
              ),
            ),
            Positioned(
              top: media.padding.top + 8,
              left: 12,
              right: 12,
              child: PointerInterceptor(
                child: Row(
                  children: [
                    MoveraIconButton.round(
                      icon: Icons.keyboard_arrow_down_rounded,
                      onPressed: () {
                        final minSheet = _minSheet(media);
                        final offset = _sheetController.hasClient
                            ? _sheetController.metrics?.offset
                            : null;
                        if (offset != null && offset > minSheet + 12) {
                          _sheetController.animateTo(
                            SheetOffset.absolute(minSheet),
                            duration: MoveraDurations.large,
                            curve: MoveraCurves.close,
                          );
                        } else {
                          _confirmCancel();
                        }
                      },
                      label: 'Collapse',
                    ),
                    const Spacer(),
                    SafetyKitMapButton(rideId: _match.ride.rideId),
                  ],
                ),
              ),
            ),
            Positioned(
              top: media.padding.top + 62,
              left: 12,
              right: 12,
              child: PointerInterceptor(
                child: RealtimeConnectionBanner(
                  connection: AppScope.instance.realtime,
                ),
              ),
            ),
            Positioned(
              right: 12,
              bottom: mapReserve + 16,
              child: PointerInterceptor(
                child: MoveraIconButton.round(
                  icon: Icons.my_location_rounded,
                  onPressed: () {
                    AppScope.instance.camera.focusOnPickup(
                      GeoPoint(
                        _pickupPosition.latitude,
                        _pickupPosition.longitude,
                      ),
                    );
                  },
                  label: 'Recenter map',
                ),
              ),
            ),
            SheetViewport(
              child: Sheet(
                controller: _sheetController,
                initialOffset: SheetOffset.absolute(_minSheet(media)),
                physics: MoveraSheetMotion.physics,
                snapGrid: SheetSnapGrid(
                  snaps: [
                    SheetOffset.absolute(_minSheet(media)),
                    SheetOffset.absolute(_maxSheet(media)),
                  ],
                  minFlingSpeed: 520,
                ),
                scrollConfiguration: SheetScrollConfiguration.disabled,
                child: PointerInterceptor(
                  child: SizedBox(
                    height: _maxSheet(media),
                    width: double.infinity,
                    child: Material(
                      color: Colors.white,
                      elevation: 18,
                      shadowColor: const Color(
                        0xFF162C36,
                      ).withValues(alpha: 0.14),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          const SizedBox(
                            width: double.infinity,
                            height: 22,
                            child: Center(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Color(0xFFE7EBEE),
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(99),
                                  ),
                                ),
                                child: SizedBox(width: 36, height: 4),
                              ),
                            ),
                          ),
                          if (!_match.showPriceBump)
                            Padding(
                              padding: const EdgeInsets.only(
                                top: 2,
                                bottom: 6,
                              ),
                              child: Image.asset(
                                excludeFromSemantics: true,
                                AppAssets.scheduleRideCar,
                                height: 88,
                                fit: BoxFit.contain,
                                filterQuality: FilterQuality.high,
                              ),
                            ),
                          Expanded(
                            child: _panelBody(
                              progress,
                              copy.headline,
                              copy.subtitle,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _panelBody(double progress, String headline, String subtitle) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            headline,
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1D252C),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color(0xFF5C656C),
            ),
          ),
          if (_match.offerConfirmation != null) ...[
            const SizedBox(height: 10),
            Text(
              _match.offerConfirmation!,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2D5878),
              ),
            ),
          ],
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: const Color(0xFFEAF2F8),
              color: const Color(0xFF2D5878),
            ),
          ),
          if (_match.showPriceBump) ...[
            const SizedBox(height: 16),
            PriceBumpCard(
              currentPrice: _match.currentPrice,
              steps: const [50, 100, 150, 200],
              onConfirm: (kr) async {
                await _match.confirmPriceIncrease(kr);
                if (mounted) setState(() {});
              },
              onKeepWaiting: () {
                _match.dismissPriceBump();
                setState(() {});
              },
            ),
          ],
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE7EBEE)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.rideType,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xFF5C656C),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Meet at ${_shortPlace(_pickupAddress)}',
                        style: GoogleFonts.poppins(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1D252C),
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${widget.paymentMethod}  ·  ${_match.currentPrice.round()} kr',
                        style: GoogleFonts.poppins(
                          fontSize: 12.5,
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
                  tooltip: 'Ride details',
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
}
