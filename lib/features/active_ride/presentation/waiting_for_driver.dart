import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:movera_rider/app/di.dart';
import 'package:movera_rider/app/router/ride_navigator.dart';
import 'package:movera_rider/core/maps/geo_point.dart';
import 'package:movera_rider/core/maps/map_owners.dart';
import 'package:movera_rider/core/web/web_overlay.dart';
import 'package:movera_rider/features/active_ride/application/active_ride_controller.dart';
import 'package:movera_rider/features/active_ride/presentation/waiting_sheet_bits.dart';
import 'package:movera_rider/features/active_ride/presentation/rider_in_trip_panel.dart';
import 'package:movera_rider/features/driver_arriving/application/driver_tracking_controller.dart';
import 'package:movera_rider/features/driver_arriving/presentation/driver_profile_page.dart';
import 'package:movera_rider/features/finding_driver/domain/cancellation_reason.dart';
import 'package:movera_rider/features/finding_driver/domain/driver_eta.dart';
import 'package:movera_rider/features/finding_driver/presentation/cancel_ride_sheet.dart';
import 'package:movera_rider/features/finding_driver/presentation/ride_details_sheet.dart';
import 'package:movera_rider/features/active_ride/presentation/driver_arrived_sheet.dart';
import 'package:movera_rider/features/active_ride/presentation/driver_cancelled_sheet.dart';
import 'package:movera_rider/features/active_ride/presentation/ride_terminal_state_sheet.dart';
import 'package:movera_rider/features/finding_driver/presentation/finding_drivers.dart';
import 'package:movera_rider/features/ride_booking/domain/entities/matched_driver.dart';
import 'package:movera_rider/features/ride_booking/domain/ride_status.dart';
import 'package:movera_rider/core/realtime/ride_realtime.dart';
import 'package:movera_rider/features/ride_complete/presentation/ride_completed.dart';
import 'package:movera_rider/features/ride_booking/domain/ride_notes.dart';
import 'package:movera_rider/features/safety/application/safety_controller.dart';
import 'package:movera_rider/features/safety/domain/safety_event.dart';
import 'package:movera_rider/features/safety/presentation/ride_safety_kit.dart';
import 'package:movera_rider/shared/design_system/motion/movera_motion.dart';
import 'package:movera_rider/shared/design_system/movera_icon_button.dart';
import 'package:movera_rider/shared/design_system/movera_sheet.dart';
import 'package:movera_rider/shared/widgets/custom_google_map.dart';
import 'package:movera_rider/shared/widgets/navigation_transition.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

class WaitingForDriver extends StatefulWidget {
  const WaitingForDriver({
    super.key,
    required this.pickupAddress,
    required this.destinationAddress,
    required this.pickupPosition,
    required this.destinationPosition,
    required this.rideType,
    required this.price,
    required this.paymentMethod,
    this.notes = RideNotes.empty,
    this.driver,
  });

  final String pickupAddress;
  final String destinationAddress;
  final LatLng pickupPosition;
  final LatLng destinationPosition;
  final String rideType;
  final double price;
  final String paymentMethod;
  final RideNotes notes;
  final MatchedDriver? driver;

  @override
  State<WaitingForDriver> createState() => _WaitingForDriverState();
}

class _WaitingForDriverState extends State<WaitingForDriver>
    with SingleTickerProviderStateMixin {
  final ActiveRideController _ride = ActiveRideController();
  late final DriverTrackingController _tracking = DriverTrackingController(
    pickupLat: widget.pickupPosition.latitude,
    pickupLng: widget.pickupPosition.longitude,
  );
  late final CameraPosition _initialPosition;
  late final AnimationController _sheetSlide;
  final GlobalKey<_WaitingRideMapState> _mapKey =
      GlobalKey<_WaitingRideMapState>(debugLabel: 'waiting-ride-map');
  bool _leaving = false;
  bool _completedOpened = false;
  bool _arrivalAnnounced = false;
  bool _researching = false;
  bool _overlayOn = false;
  bool _mapParked = false;
  String _sheetSignature = '';

  @override
  void initState() {
    super.initState();
    _initialPosition = CameraPosition(target: widget.pickupPosition, zoom: 14);
    _sheetSlide = AnimationController(
      vsync: this,
      duration: MoveraDurations.sheetOpen,
      value: 0,
    );
    _sheetSlide.addListener(_syncSheetOverlay);
    _syncSheetOverlay();
    _tracking.driver = widget.driver;
    SafetyController.shared.load();
    final rideId = AppScope.instance.ride.rideId;
    if (rideId != null) {
      _tracking.start(
        rideId: rideId,
        initial: widget.driver,
        onChange: _onLiveTick,
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sheetSlide.duration = MoveraMotion.of(context, MoveraDurations.sheetOpen);
  }

  void _onLiveTick() {
    if (!mounted) return;
    final status = _tracking.status;
    if (status.isTerminal && !status.isCompletedSurface) {
      unawaited(_handleExternalTerminal(status));
      return;
    }
    _maybeAnnounceArrival();
    _maybeOpenCompleted();
    _mapKey.currentState?.paintIfDue();
    final signature = _sheetSignatureFor(
      status: status,
      driver: _tracking.driver ?? widget.driver,
      eta: _tracking.eta,
    );
    if (signature == _sheetSignature) return;
    _sheetSignature = signature;
    setState(() {});
  }

  String _sheetSignatureFor({
    required RideStatus status,
    required MatchedDriver? driver,
    required DriverEta? eta,
  }) {
    final headline = eta?.headline(status: status) ?? 'Driver found';
    final subtitle =
        eta?.subtitle(firstName: driver?.firstName, status: status) ?? '';
    return '${status.name}|$headline|$subtitle|${driver?.id ?? ''}';
  }

  /// The driver reaching pickup is easy to miss on a map the rider is not
  /// watching, so say it once and never again for this ride.
  void _maybeAnnounceArrival() {
    if (!mounted || _leaving || _arrivalAnnounced || _completedOpened) return;
    final explicitArrival =
        _tracking.lastSignal == RideRealtimeSignal.driverArrived;
    if (!explicitArrival && _tracking.status != RideStatus.driverWaiting) {
      return;
    }
    _arrivalAnnounced = true;
    unawaited(
      showDriverArrivedSheet(
        context,
        driver: _tracking.driver ?? widget.driver,
        onWay: _sendOnTheWay,
      ),
    );
  }

  Future<void> _sendOnTheWay() async {
    final rideId = AppScope.instance.ride.rideId;
    if (rideId == null) return;
    await AppScope.instance.rideRealtime.sendSignal(
      rideId: rideId,
      signal: RideRealtimeSignal.riderOnTheWay,
      message: "I'm on the way",
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Sent to driver · I'm on the way"),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  void _maybeOpenCompleted() {
    if (!mounted || _leaving || _completedOpened) return;
    final status = _tracking.status;
    if (!status.isCompletedSurface) return;
    unawaited(_openCompleted(status));
  }

  Future<void> _handleExternalTerminal(RideStatus status) async {
    if (!mounted ||
        _leaving ||
        _completedOpened ||
        !status.isTerminal ||
        status.isCompletedSurface) {
      return;
    }
    // A driver dropping the ride before pickup does not end the rider's trip.
    // Dispatch looks again, so say what happened and go back to searching
    // rather than sending them Home to rebook from scratch.
    if (status == RideStatus.cancelledByDriver && !_tracking.status.isCompletedSurface) {
      await _researchAfterDriverCancel();
      return;
    }
    _leaving = true;
    setState(() {});
    _tracking.dispose();
    await _ride.markExternalTerminal(status);
    if (!mounted) return;
    await showRideTerminalStateSheet(context, status: status);
    if (!mounted) return;
    RideNavigator.home(context, status: status);
  }

  Future<void> _researchAfterDriverCancel() async {
    if (_researching) return;
    _researching = true;
    final lostDriver = _tracking.driver ?? widget.driver;
    _tracking.dispose();

    if (mounted) {
      await showDriverCancelledSheet(context, driverName: lostDriver?.firstName);
    }
    if (!mounted) return;

    await _parkMapForStageChange();
    if (!mounted) return;

    // Same ride, same price, same addresses — only the driver changes.
    AppScope.instance.rideRealtime.researchAfterDriverCancel();
    Navigator.pushReplacement(
      context,
      RideStageTransition(
        FindingDrivers(
          pickupAddress: widget.pickupAddress,
          destinationAddress: widget.destinationAddress,
          pickupPosition: widget.pickupPosition,
          destinationPosition: widget.destinationPosition,
          rideType: widget.rideType,
          price: widget.price,
          paymentMethod: widget.paymentMethod,
          notes: widget.notes,
        ),
      ),
    );
  }

  Future<void> _openCompleted(RideStatus status) async {
    if (!mounted || _leaving || _completedOpened) return;
    _completedOpened = true;
    final rideId = AppScope.instance.ride.rideId;
    await _ride.markCompleted(status);
    if (!mounted) return;
    _tracking.dispose();
    await _parkMapForStageChange();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      RideStageTransition(
        RideCompleted(status: status, rideId: rideId),
      ),
    );
  }

  Future<void> _confirmCancel() async {
    if (_leaving) return;
    final outcome = await showCancelRideSheet(
      context,
      takingLonger: false,
      phase: CancelPhase.matched,
    );
    if (!outcome.cancelled || !mounted) return;
    _leaving = true;
    setState(() {});
    _tracking.dispose();
    await _ride.markCancelled(reasonId: outcome.reasonId);
    if (!mounted) return;
    await _parkMapForStageChange();
    if (!mounted) return;
    RideNavigator.home(context);
  }

  void _openProfile() {
    final driver = _tracking.driver ?? widget.driver;
    if (driver == null) return;
    Navigator.push(
      context,
      RightToLeftTransition(DriverProfilePage(driver: driver)),
    );
  }

  bool get _isInTrip =>
      _tracking.status == RideStatus.tripStarted ||
      _tracking.status == RideStatus.tripInProgress;

  Future<void> _openDetails() {
    return MoveraSheet.show<void>(
      context: context,
      builder: (sheetContext) => RideDetailsSheet(
        pickupAddress: widget.pickupAddress,
        destinationAddress: widget.destinationAddress,
        rideType: widget.rideType,
        price: widget.price,
        paymentMethod: widget.paymentMethod,
        notes: widget.notes,
        canEditPickup: false,
        allowCancel: !_isInTrip,
        onEditPickup: () {},
        onEditDestination: () {},
        onCancelTrip: () {
          Navigator.pop(sheetContext);
          _confirmCancel();
        },
      ),
    );
  }

  @override
  void dispose() {
    _sheetSlide.removeListener(_syncSheetOverlay);
    _sheetSlide.dispose();
    _tracking.dispose();
    setWebOverlayOpen(false);
    AppScope.instance.maps.detach(owner: MapOwners.waiting);
    super.dispose();
  }

  void _syncSheetOverlay() {
    final cover = _sheetSlide.value > 0.05;
    if (cover == _overlayOn) return;
    _overlayOn = cover;
    setWebOverlayOpen(cover);
  }

  double _minSheet(MediaQueryData media) => 390 + media.padding.bottom;

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

  Future<void> _parkMapForStageChange() async {
    if (_mapParked) return;
    _mapParked = true;
    setWebOverlayOpen(false);
    AppScope.instance.maps.detach(owner: MapOwners.waiting);
    if (mounted) setState(() {});
    await WidgetsBinding.instance.endOfFrame;
  }

  void _recenterMap() {
    final eta = _tracking.eta;
    final target = _isInTrip
        ? (eta?.latitude != null && eta?.longitude != null
              ? GeoPoint(eta!.latitude!, eta.longitude!)
              : GeoPoint(
                  widget.destinationPosition.latitude,
                  widget.destinationPosition.longitude,
                ))
        : GeoPoint(
            widget.pickupPosition.latitude,
            widget.pickupPosition.longitude,
          );
    AppScope.instance.camera.focusOnPickup(target);
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
    final driver = _tracking.driver ?? widget.driver;
    final eta = _tracking.eta;
    final headline = eta?.headline(status: _tracking.status) ?? 'Driver found';
    final subtitle =
        eta?.subtitle(firstName: driver?.firstName, status: _tracking.status) ??
        (driver == null
            ? 'Driver details will appear when matching confirms them.'
            : 'Leave now to meet ${driver.firstName}');
    final media = MediaQuery.of(context);
    const mapReserve = 300.0;
    return PopScope(
      canPop: _leaving,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (_isInTrip) {
          await _openDetails();
        } else {
          await _confirmCancel();
        }
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
              child: _mapParked
                  ? const ColoredBox(color: Color(0xFFF6F5F1))
                  : _WaitingRideMap(
                      key: _mapKey,
                      initialPosition: _initialPosition,
                      pickupPosition: widget.pickupPosition,
                      destinationPosition: widget.destinationPosition,
                      pickupAddress: widget.pickupAddress,
                      destinationAddress: widget.destinationAddress,
                      tracking: _tracking,
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
                      icon: _isInTrip
                          ? Icons.receipt_long_outlined
                          : Icons.keyboard_arrow_down_rounded,
                      onPressed: _isInTrip ? _openDetails : _confirmCancel,
                      label: _isInTrip ? 'Trip details' : 'Cancel ride',
                    ),
                    const Spacer(),
                    SafetyKitMapButton(rideId: AppScope.instance.ride.rideId),
                  ],
                ),
              ),
            ),
            Positioned(
              right: 12,
              bottom: mapReserve + 16,
              child: PointerInterceptor(
                child: MoveraIconButton.round(
                  icon: Icons.my_location_rounded,
                  onPressed: _recenterMap,
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
                      key: const ValueKey<String>('waiting-panel'),
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
                          KeyedSubtree(
                            key: ValueKey<String>(
                              'waiting-stage-${_tracking.status.name}',
                            ),
                            child: const SizedBox.shrink(),
                          ),
                          Expanded(child: _panel(driver, headline, subtitle)),
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

  Widget _panel(MatchedDriver? driver, String headline, String subtitle) {
    if (_isInTrip) {
      return RiderInTripPanel(
        destinationAddress: widget.destinationAddress,
        rideType: widget.rideType,
        paymentMethod: widget.paymentMethod,
        price: widget.price,
        driver: driver,
        rideId: AppScope.instance.ride.rideId,
        onOpenProfile: _openProfile,
        onCall: () => SafetyController.shared.record(SafetyKind.maskedCall),
        onMore: _openDetails,
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      headline,
                      style: waitingText(22, weight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: waitingText(14, color: const Color(0xFF5C656C)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              WaitingShareButton(rideId: AppScope.instance.ride.rideId),
            ],
          ),
          const SizedBox(height: 16),
          WaitingDriverCard(
            driver: driver,
            onOpenProfile: _openProfile,
            onCall: () => SafetyController.shared.record(SafetyKind.maskedCall),
            onMore: _openDetails,
          ),
          const SizedBox(height: 12),
          WaitingRideDetailsCard(
            rideType: widget.rideType,
            pickupAddress: widget.pickupAddress,
            destinationAddress: widget.destinationAddress,
            inTrip:
                _tracking.status == RideStatus.tripStarted ||
                _tracking.status == RideStatus.tripInProgress,
            paymentMethod: widget.paymentMethod,
            price: widget.price,
            onMore: _openDetails,
          ),
          WaitingNotesAndPin(notes: widget.notes),
        ],
      ),
    );
  }
}

class _WaitingRideMap extends StatefulWidget {
  const _WaitingRideMap({
    super.key,
    required this.initialPosition,
    required this.pickupPosition,
    required this.destinationPosition,
    required this.pickupAddress,
    required this.destinationAddress,
    required this.tracking,
  });

  final CameraPosition initialPosition;
  final LatLng pickupPosition;
  final LatLng destinationPosition;
  final String pickupAddress;
  final String destinationAddress;
  final DriverTrackingController tracking;

  @override
  State<_WaitingRideMap> createState() => _WaitingRideMapState();
}

class _WaitingRideMapState extends State<_WaitingRideMap> {
  Set<Marker> _markers = const <Marker>{};
  DateTime? _lastPaint;
  Widget? _leaf;

  @override
  void initState() {
    super.initState();
    _markers = _buildMarkers();
  }

  @override
  void didUpdateWidget(covariant _WaitingRideMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pickupPosition == widget.pickupPosition &&
        oldWidget.destinationPosition == widget.destinationPosition &&
        oldWidget.pickupAddress == widget.pickupAddress &&
        oldWidget.destinationAddress == widget.destinationAddress &&
        identical(oldWidget.tracking, widget.tracking)) {
      return;
    }
    _markers = _buildMarkers();
    _leaf = null;
  }

  void paintIfDue() {
    final now = DateTime.now();
    if (_lastPaint != null &&
        now.difference(_lastPaint!) < const Duration(milliseconds: 400)) {
      return;
    }
    _lastPaint = now;
    final next = _buildMarkers();
    if (_sameMarkers(_markers, next)) return;
    if (!mounted) return;
    setState(() {
      _markers = next;
      _leaf = null;
    });
  }

  bool _sameMarkers(Set<Marker> current, Set<Marker> next) {
    if (identical(current, next)) return true;
    if (current.length != next.length) return false;
    final byId = <String, LatLng>{
      for (final marker in current) marker.markerId.value: marker.position,
    };
    for (final marker in next) {
      final position = byId[marker.markerId.value];
      if (position == null || position != marker.position) return false;
    }
    return true;
  }

  Set<Marker> _buildMarkers() {
    final eta = widget.tracking.eta;
    final inTrip =
        widget.tracking.status == RideStatus.tripStarted ||
        widget.tracking.status == RideStatus.tripInProgress;
    return {
      if (!inTrip)
        Marker(
          markerId: const MarkerId('pickup'),
          position: widget.pickupPosition,
          infoWindow: InfoWindow(title: shortPickupPlace(widget.pickupAddress)),
        ),
      Marker(
        markerId: const MarkerId('destination'),
        position: widget.destinationPosition,
        infoWindow: InfoWindow(
          title: shortPickupPlace(widget.destinationAddress),
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ),
      if (eta?.latitude != null && eta?.longitude != null)
        Marker(
          markerId: const MarkerId('driver'),
          position: LatLng(eta!.latitude!, eta.longitude!),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueViolet,
          ),
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    return _leaf ??= RepaintBoundary(
      child: CustomGoogleMap(
        key: const ValueKey('waiting-map'),
        initialPosition: widget.initialPosition,
        markers: _markers,
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
            owner: MapOwners.waiting,
          );
        },
      ),
    );
  }
}
