import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:movera_rider/app/di.dart';
import 'package:movera_rider/app/router/home_history_observer.dart';
import 'package:movera_rider/app/router/ride_navigator.dart';
import 'package:movera_rider/core/maps/geo_point.dart';
import 'package:movera_rider/core/maps/map_owners.dart';
import 'package:movera_rider/core/maps/route_polyline.dart';
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
import 'package:movera_rider/features/ride_booking/application/ride_restore_coordinator.dart';
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
import 'package:movera_rider/shared/widgets/movera_map_markers.dart';
import 'package:movera_rider/shared/widgets/navigation_transition.dart';
import 'package:movera_rider/shared/widgets/realtime_connection_banner.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:smooth_sheets/smooth_sheets.dart';

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
    this.realtime,
    this.rideId,
    this.persistRideSnapshot = true,
    this.onTerminal,
    this.onDriverCancelled,
    this.onCompleted,
    this.onCancel,
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

  /// Optional transport and lifecycle overrides let Scheduled Ride reuse this
  /// exact presentation without touching the on-demand ride session.
  final RideRealtime? realtime;
  final String? rideId;
  final bool persistRideSnapshot;
  final Future<void> Function(BuildContext context, RideStatus status)?
  onTerminal;
  final Future<void> Function(BuildContext context)? onDriverCancelled;
  final Future<void> Function(BuildContext context, RideStatus status)?
  onCompleted;
  final Future<void> Function(BuildContext context, String? reasonId)? onCancel;

  @override
  State<WaitingForDriver> createState() => _WaitingForDriverState();
}

class _WaitingForDriverState extends State<WaitingForDriver> {
  final ActiveRideController _ride = ActiveRideController();
  late final DriverTrackingController _tracking = DriverTrackingController(
    realtime: widget.realtime,
    pickupLat: widget.pickupPosition.latitude,
    pickupLng: widget.pickupPosition.longitude,
    persistRideSnapshot: widget.persistRideSnapshot,
  );
  late final CameraPosition _initialPosition;
  final SheetController _sheetController = SheetController();
  final GlobalKey<_WaitingRideMapState> _mapKey =
      GlobalKey<_WaitingRideMapState>(debugLabel: 'waiting-ride-map');
  bool _leaving = false;
  bool _completedOpened = false;
  bool _arrivalAnnounced = false;
  bool _researching = false;
  bool _overlayOn = false;
  bool _mapParked = false;
  bool _modalHandoffInProgress = false;
  RideStatus? _pendingStageStatus;
  String _sheetSignature = '';

  RideRealtime get _realtime =>
      widget.realtime ?? AppScope.instance.rideRealtime;
  String? get _rideId => widget.rideId ?? AppScope.instance.ride.rideId;

  @override
  void initState() {
    super.initState();
    _initialPosition = CameraPosition(target: widget.pickupPosition, zoom: 14);
    _sheetController.addListener(_syncSheetOverlay);
    moveraNavigationEpoch.addListener(_onNavigationChanged);
    setWebOverlayOpen(false);
    _tracking.driver = widget.driver;
    SafetyController.shared.load();
    final rideId = _rideId;
    if (rideId != null && rideId.trim().isNotEmpty) {
      _tracking.start(
        rideId: rideId,
        initial: widget.driver,
        onChange: _onLiveTick,
      );
    }
  }

  void _onLiveTick() {
    if (!mounted) return;
    final status = _tracking.status;
    if (status.isTerminal && !status.isCompletedSurface) {
      _queueStageNavigation(status);
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
    if (!mounted ||
        _leaving ||
        _arrivalAnnounced ||
        _completedOpened ||
        _modalHandoffInProgress ||
        !_routeIsCurrent) {
      return;
    }
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
        onWay: _realtime.supportsRiderSignals ? _sendOnTheWay : null,
      ),
    );
  }

  Future<void> _sendOnTheWay() async {
    final rideId = _rideId;
    if (rideId == null || rideId.trim().isEmpty) return;
    if (!_realtime.supportsRiderSignals) return;
    await _realtime.sendSignal(
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

  bool get _routeIsCurrent => ModalRoute.of(context)?.isCurrent ?? true;

  void _onNavigationChanged() {
    if (!mounted) return;
    // Route observer callbacks occur while Navigator is locked. Completion,
    // terminal and arrival surfaces can push sheets/routes, so wait one frame
    // before draining anything that was deferred behind a child route.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _drainStageNavigation();
      if (!_leaving && !_completedOpened) _maybeAnnounceArrival();
    });
  }

  void _queueStageNavigation(RideStatus status) {
    if (!mounted || _leaving || _completedOpened) return;
    _pendingStageStatus = status;
    _drainStageNavigation();
  }

  void _drainStageNavigation() {
    if (!mounted ||
        _leaving ||
        _completedOpened ||
        _modalHandoffInProgress ||
        !_routeIsCurrent) {
      return;
    }
    final status = _pendingStageStatus;
    if (status == null) return;
    _pendingStageStatus = null;

    if (status.isTerminal && !status.isCompletedSurface) {
      unawaited(_handleExternalTerminal(status));
      return;
    }
    if (status.isCompletedSurface) {
      unawaited(_openCompleted(status));
    }
  }

  void _maybeOpenCompleted() {
    if (!mounted || _leaving || _completedOpened) return;
    final status = _tracking.status;
    if (!status.isCompletedSurface) return;
    _queueStageNavigation(status);
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

    final customTerminal = widget.onTerminal;
    if (customTerminal != null) {
      await showRideTerminalStateSheet(context, status: status);
      if (!mounted) return;
      await _parkMapForStageChange();
      if (!mounted) return;
      await customTerminal(context, status);
      return;
    }

    await _ride.markExternalTerminal(status);
    if (!mounted) return;
    await showRideTerminalStateSheet(context, status: status);
    if (!mounted) return;
    await _parkMapForStageChange();
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

    final customDriverCancelled = widget.onDriverCancelled;
    if (customDriverCancelled != null) {
      _leaving = true;
      setState(() {});
      await customDriverCancelled(context);
      return;
    }

    // Same ride, same price, same addresses — only the driver changes.
    _realtime.researchAfterDriverCancel();
    _leaving = true;
    if (mounted) setState(() {});

    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      // Normal forward path already has the parked Finding route directly
      // underneath this screen. Return to it instead of stacking another
      // Finding route every time a driver drops the ride.
      navigator.pop(true);
      return;
    }

    // Cold restore can put Waiting directly inside RideRestoreGate, with no
    // pushed Finding route underneath. Replace only the gate child so the app
    // root/navigator stays intact.
    final finding = FindingDrivers(
      pickupAddress: widget.pickupAddress,
      destinationAddress: widget.destinationAddress,
      pickupPosition: widget.pickupPosition,
      destinationPosition: widget.destinationPosition,
      rideType: widget.rideType,
      price: widget.price,
      paymentMethod: widget.paymentMethod,
      notes: widget.notes,
    );
    final coordinator = RideRestoreCoordinator.instance;
    if (coordinator.replaceRootSurface(finding, RestoredSurface.finding)) {
      return;
    }

    // Widget tests or isolated hosts may not have RideRestoreGate installed.
    Navigator.pushReplacement(
      context,
      RideStageTransition(finding),
    );
  }

  Future<void> _openCompleted(RideStatus status) async {
    if (!mounted || _leaving || _completedOpened) return;
    _completedOpened = true;
    final rideId = _rideId;
    _tracking.dispose();

    final customCompleted = widget.onCompleted;
    if (customCompleted != null) {
      await _parkMapForStageChange();
      if (!mounted) return;
      await customCompleted(context, status);
      return;
    }

    await _ride.markCompleted(status);
    if (!mounted) return;
    await _parkMapForStageChange();
    if (!mounted) return;
    final completed = RideCompleted(status: status, rideId: rideId);
    final navigator = Navigator.of(context);

    // A cold restore renders Waiting inside RideRestoreGate on the Navigator
    // root. Replacing that route would dispose the gate, so Done could no
    // longer reveal Home. Swap only the gate child in that topology.
    if (!navigator.canPop()) {
      final coordinator = RideRestoreCoordinator.instance;
      if (coordinator.replaceRootSurface(
        completed,
        RestoredSurface.complete,
      )) {
        return;
      }
    }

    // Normal Book Now has Home/Finding underneath Waiting, so replacement is
    // correct here and avoids keeping the active-ride route in the stack.
    navigator.pushReplacement(
      RideStageTransition(completed),
    );
  }

  Future<void> _confirmCancel() async {
    if (_leaving) return;
    final outcome = await showCancelRideSheet(
      context,
      takingLonger: false,
      phase: _isInTrip ? CancelPhase.inTrip : CancelPhase.matched,
    );
    if (!outcome.cancelled || !mounted) return;
    _leaving = true;
    setState(() {});
    _tracking.dispose();

    final customCancel = widget.onCancel;
    if (customCancel != null) {
      await _parkMapForStageChange();
      if (!mounted) return;
      await customCancel(context, outcome.reasonId);
      return;
    }

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
      _tracking.status == RideStatus.tripInProgress ||
      _tracking.status == RideStatus.approachingDropoff;

  Future<void> _openDetails() async {
    await MoveraSheet.show<void>(
      context: context,
      builder: (sheetContext) => RideDetailsSheet(
        pickupAddress: widget.pickupAddress,
        destinationAddress: widget.destinationAddress,
        rideType: widget.rideType,
        price: widget.price,
        paymentMethod: widget.paymentMethod,
        notes: widget.notes,
        canEditPickup: false,
        allowCancel: true,
        onEditPickup: () {},
        onEditDestination: () {},
        onCancelTrip: () async {
          _modalHandoffInProgress = true;
          await popCurrentRouteAndWaitForExit(sheetContext);
          if (!mounted) return;
          _modalHandoffInProgress = false;
          await _confirmCancel();
        },
      ),
    );
  }

  @override
  void dispose() {
    moveraNavigationEpoch.removeListener(_onNavigationChanged);
    _sheetController.removeListener(_syncSheetOverlay);
    _sheetController.dispose();
    _tracking.dispose();
    setWebOverlayOpen(false);
    AppScope.instance.maps.detach(owner: MapOwners.waiting);
    super.dispose();
  }

  void _syncSheetOverlay() {
    if (!_sheetController.hasClient) return;
    final media = MediaQuery.maybeOf(context);
    if (media == null) return;
    final offset = _sheetController.metrics?.offset;
    final cover = offset != null && offset > _minSheet(media) + 12;
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
                          ? Icons.close_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      onPressed: _confirmCancel,
                      label: 'Cancel ride',
                    ),
                    const Spacer(),
                    SafetyKitMapButton(rideId: _rideId),
                  ],
                ),
              ),
            ),
            if (widget.realtime == null)
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
                  onPressed: _recenterMap,
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
                          KeyedSubtree(
                            key: ValueKey<String>(
                              'waiting-stage-${_tracking.status.name}',
                            ),
                            child: const SizedBox.shrink(),
                          ),
                          if (!_isInTrip)
                            _fixedPickupHeader(driver, headline, subtitle),
                          Expanded(child: _panel(driver)),
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

  Widget _fixedPickupHeader(
    MatchedDriver? driver,
    String headline,
    String subtitle,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 2, 20, 12),
      child: Row(
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
          WaitingShareButton(rideId: _rideId),
        ],
      ),
    );
  }

  Widget _panel(MatchedDriver? driver) {
    if (_isInTrip) {
      return RiderInTripPanel(
        destinationAddress: widget.destinationAddress,
        rideType: widget.rideType,
        paymentMethod: widget.paymentMethod,
        price: widget.price,
        driver: driver,
        rideId: _rideId,
        status: _tracking.status,
        onOpenProfile: _openProfile,
        onCall: () => SafetyController.shared.record(SafetyKind.maskedCall),
        onMore: _openDetails,
        onCancel: _confirmCancel,
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          WaitingDriverCard(
            driver: driver,
            rideId: _rideId,
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
  Set<Polyline> _polylines = const <Polyline>{};
  BitmapDescriptor? _riderPuck;
  BitmapDescriptor? _driverCar;
  DateTime? _lastPaint;
  DateTime? _lastRouteRefresh;
  bool _mapReady = false;
  String? _routeKey;
  Widget? _leaf;

  bool get _inTrip =>
      widget.tracking.status == RideStatus.tripStarted ||
      widget.tracking.status == RideStatus.tripInProgress ||
      widget.tracking.status == RideStatus.approachingDropoff;

  @override
  void initState() {
    super.initState();
    _markers = _buildMarkers();
    unawaited(_prepareMapVisuals());
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
    _polylines = const <Polyline>{};
    _routeKey = null;
    _leaf = null;
    if (_mapReady) {
      unawaited(_refreshRoadRoute(force: true));
    }
  }

  void paintIfDue() {
    final now = DateTime.now();
    if (_lastPaint != null &&
        now.difference(_lastPaint!) < const Duration(milliseconds: 400)) {
      return;
    }
    _lastPaint = now;

    final next = _buildMarkers();
    final markersChanged = !_sameMarkers(_markers, next);
    if (markersChanged && mounted) {
      setState(() {
        _markers = next;
        _leaf = null;
      });
    }

    if (_mapReady &&
        (_lastRouteRefresh == null ||
            now.difference(_lastRouteRefresh!) >=
                const Duration(seconds: 10))) {
      unawaited(_refreshRoadRoute());
    }
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
    return {
      if (!_inTrip && _riderPuck != null)
        Marker(
          markerId: const MarkerId('pickup'),
          position: widget.pickupPosition,
          infoWindow: InfoWindow(title: shortPickupPlace(widget.pickupAddress)),
          icon: _riderPuck!,
          anchor: const Offset(0.5, 0.72),
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
          rotation: 0,
          flat: true,
          anchor: const Offset(0.5, 0.5),
          icon:
              _driverCar ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
        ),
    };
  }

  Future<void> _prepareMapVisuals() async {
    final icons = await Future.wait<BitmapDescriptor>([
      MoveraRiderPuckMarker.createIcon(),
      MoveraVehicleMarker.createIcon(),
    ]);
    if (!mounted) return;
    setState(() {
      _riderPuck = icons[0];
      _driverCar = icons[1];
      _markers = _buildMarkers();
      _leaf = null;
    });
  }

  ({GeoPoint from, GeoPoint to})? _routeEndpoints() {
    final eta = widget.tracking.eta;
    final driverPoint = eta?.latitude != null && eta?.longitude != null
        ? GeoPoint(eta!.latitude!, eta.longitude!)
        : null;

    if (_inTrip) {
      return (
        from:
            driverPoint ??
            GeoPoint(
              widget.pickupPosition.latitude,
              widget.pickupPosition.longitude,
            ),
        to: GeoPoint(
          widget.destinationPosition.latitude,
          widget.destinationPosition.longitude,
        ),
      );
    }

    if (driverPoint == null) return null;
    return (
      from: driverPoint,
      to: GeoPoint(
        widget.pickupPosition.latitude,
        widget.pickupPosition.longitude,
      ),
    );
  }

  Future<void> _refreshRoadRoute({bool force = false}) async {
    if (!_mapReady) return;
    final endpoints = _routeEndpoints();
    if (endpoints == null) return;

    String keyFor(GeoPoint point) =>
        '${point.latitude.toStringAsFixed(4)},${point.longitude.toStringAsFixed(4)}';
    final requestKey =
        '${_inTrip ? 'trip' : 'pickup'}:${keyFor(endpoints.from)}>${keyFor(endpoints.to)}';
    if (!force && requestKey == _routeKey) return;

    _routeKey = requestKey;
    _lastRouteRefresh = DateTime.now();
    final route = await roadRoutePolyline(
      id: 'active-road-route',
      from: LatLng(endpoints.from.latitude, endpoints.from.longitude),
      to: LatLng(endpoints.to.latitude, endpoints.to.longitude),
      color: const Color(0xFF1D252C),
    );
    if (!mounted || _routeKey != requestKey || route.points.length < 2) return;

    setState(() {
      _polylines = {route};
      _leaf = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _leaf ??= RepaintBoundary(
      child: CustomGoogleMap(
        key: const ValueKey('waiting-map'),
        initialPosition: widget.initialPosition,
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
            owner: MapOwners.waiting,
          );
          unawaited(_refreshRoadRoute(force: true));
        },
      ),
    );
  }
}
