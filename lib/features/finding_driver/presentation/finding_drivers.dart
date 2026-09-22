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
import 'package:movera_rider/shared/widgets/navigation_transition.dart';
import 'package:movera_rider/shared/widgets/realtime_connection_banner.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

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

class _FindingDriversState extends State<FindingDrivers>
    with SingleTickerProviderStateMixin {
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  final FindingDriverController _match = FindingDriverController();
  bool _mapParked = false;
  bool _leaving = false;
  bool _cancelSheetOpen = false;
  bool _pickupEditOpen = false;
  bool _detailsSheetOpen = false;
  bool _matchedPending = false;
  RideStatus? _terminalPending;
  bool _overlayOn = false;
  int _nearbyPaintKey = 0;
  late final AnimationController _sheetSlide;

  late String _pickupAddress;
  late LatLng _pickupPosition;

  @override
  void initState() {
    super.initState();
    _pickupAddress = widget.pickupAddress;
    _pickupPosition = widget.pickupPosition;
    _sheetSlide = AnimationController(
      vsync: this,
      duration: MoveraDurations.sheetOpen,
      value: 0,
    );
    _sheetSlide.addListener(_syncSheetOverlay);
    moveraNavigationEpoch.addListener(_onNavigationChanged);
    _syncSheetOverlay();
    _loadMapBits();
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
    _drainDeferredNavigation();
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sheetSlide.duration = MoveraMotion.of(context, MoveraDurations.sheetOpen);
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
      for (final vehicle in _match.nearby)
        Marker(
          markerId: MarkerId('nearby-${vehicle.id}'),
          position: LatLng(vehicle.latitude, vehicle.longitude),
          rotation: vehicle.bearing,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueViolet,
          ),
        ),
    };
    _polylines = {
      routePolyline(
        id: 'route',
        from: _pickupPosition,
        to: widget.destinationPosition,
        color: const Color(0xFF1D252C),
      ),
    };
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
          Navigator.pop(sheetContext);
          AppScope.instance.maps.detach(owner: MapOwners.finding);
          if (!mounted) return;
          setState(() {
            _mapParked = true;
            _pickupEditOpen = true;
          });
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
              _loadMapBits();
            }
          });

          if (_match.matchCount == 1) _matchedPending = true;
          _drainDeferredNavigation();
        },
        onEditDestination: () => Navigator.pop(sheetContext),
        onCancelTrip: () {
          Navigator.pop(sheetContext);
          _confirmCancel();
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
    _sheetSlide.removeListener(_syncSheetOverlay);
    _sheetSlide.dispose();
    if (!_leaving && _match.matchCount == 0) {
      unawaited(_match.cancelSearch());
    }
    _match.dispose();
    setWebOverlayOpen(false);
    AppScope.instance.maps.detach(owner: MapOwners.finding);
    super.dispose();
  }

  void _syncSheetOverlay() {
    final cover = _sheetSlide.value > 0.05 || _match.showPriceBump;
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

  void _onSheetDragUpdate(DragUpdateDetails details, MediaQueryData media) {
    final range = _maxSheet(media) - _minSheet(media);
    if (range <= 0) return;
    _sheetSlide.value = (_sheetSlide.value - details.primaryDelta! / range)
        .clamp(0.0, 1.0);
  }

  void _onSheetDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    final target = velocity < -480
        ? 1.0
        : velocity > 480
        ? 0.0
        : _sheetSlide.value >= 0.42
        ? 1.0
        : 0.0;
    _sheetSlide.animateTo(
      target,
      duration: MoveraMotion.of(context, MoveraDurations.large),
      curve: MoveraCurves.snap,
    );
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
                          AppScope.instance.maps.attach(
                            controller,
                            owner: MapOwners.finding,
                          );
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
                        if (_sheetSlide.value > 0.2) {
                          _sheetSlide.animateTo(0);
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
            AnimatedBuilder(
              animation: _sheetSlide,
              builder: (context, _) {
                final minSheet = _minSheet(media);
                final maxSheet = _maxSheet(media);
                final height =
                    minSheet + (maxSheet - minSheet) * _sheetSlide.value;
                return Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: height,
                  child: PointerInterceptor(
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
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onVerticalDragUpdate: (d) =>
                                _onSheetDragUpdate(d, media),
                            onVerticalDragEnd: _onSheetDragEnd,
                            child: const SizedBox(
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
                );
              },
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
          if (!_match.showPriceBump) ...[
            Center(
              child: Image.asset(
                excludeFromSemantics: true,
                AppAssets.scheduleRideCar,
                height: 88,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
            ),
            const SizedBox(height: 10),
          ],
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
