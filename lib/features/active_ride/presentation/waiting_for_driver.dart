import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:movera_rider/app/di.dart';
import 'package:movera_rider/app/router/routes.dart';
import 'package:movera_rider/app/router/home_history_observer.dart';
import 'package:movera_rider/app/router/ride_navigator.dart';
import 'package:movera_rider/core/maps/geo_point.dart';
import 'package:movera_rider/core/maps/map_owners.dart';
import 'package:movera_rider/core/maps/route_polyline.dart';
import 'package:movera_rider/core/motion/bearing.dart';
import 'package:movera_rider/core/realtime/mock_ride_realtime.dart';
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
import 'package:movera_rider/features/active_ride/presentation/driver_call_unavailable_dialog.dart';
import 'package:movera_rider/features/active_ride/presentation/driver_cancelled_notice.dart';
import 'package:movera_rider/features/active_ride/presentation/ride_terminal_state_sheet.dart';
import 'package:movera_rider/features/finding_driver/presentation/finding_drivers.dart';
import 'package:movera_rider/features/reservations/application/reservation_error_message.dart';
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
import 'package:movera_rider/shared/design_system/movera_empty_state.dart';
import 'package:movera_rider/shared/design_system/movera_icon_button.dart';
import 'package:movera_rider/shared/design_system/movera_sheet.dart';
import 'package:movera_rider/shared/widgets/custom_google_map.dart';
import 'package:movera_rider/shared/widgets/movera_map_markers.dart';
import 'package:movera_rider/shared/widgets/navigation_transition.dart';
import 'package:movera_rider/shared/widgets/realtime_connection_banner.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:smooth_sheets/smooth_sheets.dart';

/// D-016: how long the driver marker eases towards a new fix. Following the
/// actual interval between fixes (clamped) removes the move-then-stall rhythm
/// a fixed short ease produced at a 2–3 s fix cadence.
@visibleForTesting
Duration driverEaseDuration(Duration? sinceLastFix) {
  const fallback = Duration(milliseconds: 900);
  const shortest = Duration(milliseconds: 400);
  const longest = Duration(milliseconds: 4000);
  if (sinceLastFix == null || sinceLastFix <= Duration.zero) return fallback;
  if (sinceLastFix < shortest) return shortest;
  if (sinceLastFix > longest) return longest;
  return sinceLastFix;
}

/// D-018: bounds and uniform padding that frame [a] and [b] above a bottom
/// obstruction (the sheet) instead of padding every side by its height.
///
/// google_maps_flutter 2.13 only offers a single uniform padding for
/// `newLatLngBounds`, so the obstruction is reserved by stretching the bounds
/// southwards: the real points then land in the top
/// `viewportHeight - bottomObstruction` of the map.
@visibleForTesting
({GeoPoint southwest, GeoPoint northeast, double padding}) waitingCameraFit({
  required GeoPoint a,
  required GeoPoint b,
  required double viewportHeight,
  required double bottomObstruction,
  double edgePadding = 48,
}) {
  const minSpan = 0.002; // ~200 m, so driver-at-pickup doesn't zoom to max.
  var south = math.min(a.latitude, b.latitude);
  var north = math.max(a.latitude, b.latitude);
  var west = math.min(a.longitude, b.longitude);
  var east = math.max(a.longitude, b.longitude);
  if (north - south < minSpan) {
    final mid = (north + south) / 2;
    south = mid - minSpan / 2;
    north = mid + minSpan / 2;
  }
  if (east - west < minSpan) {
    final mid = (east + west) / 2;
    west = mid - minSpan / 2;
    east = mid + minSpan / 2;
  }
  final full = math.max(viewportHeight - 2 * edgePadding, 1.0);
  final usable = math.max(
    viewportHeight - bottomObstruction - 2 * edgePadding,
    full * 0.25,
  );
  final span = north - south;
  final stretchedSouth = north - span * (full / usable);
  return (
    southwest: GeoPoint(math.max(stretchedSouth, -85.0), west),
    northeast: GeoPoint(north, east),
    padding: edgePadding,
  );
}

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
    destinationLat: widget.destinationPosition.latitude,
    destinationLng: widget.destinationPosition.longitude,
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
  bool _arrivedSheetShowing = false;
  bool _cancelling = false;
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
    final realtime = _realtime;
    if (realtime is MockRideRealtime) {
      realtime.destinationLat = widget.destinationPosition.latitude;
      realtime.destinationLng = widget.destinationPosition.longitude;
    }
    final rideId = _rideId;
    if (rideId != null && rideId.trim().isNotEmpty) {
      _tracking.start(
        rideId: rideId,
        initial: widget.driver,
        onChange: _onLiveTick,
      );
    } else {
      // No rideId means nothing will ever subscribe: no driver marker, no
      // status changes, and previously no error either — the screen just
      // sat there silently. Say so explicitly instead.
      _missingRideId = true;
    }
  }

  bool _missingRideId = false;

  void _retryTracking() {
    final rideId = _rideId;
    if (rideId == null || rideId.trim().isEmpty) return;
    setState(() => _missingRideId = false);
    _tracking.start(
      rideId: rideId,
      initial: widget.driver,
      onChange: _onLiveTick,
    );
  }

  void _retryLiveFeed() {
    final rideId = _rideId;
    if (rideId == null || rideId.trim().isEmpty) return;
    _tracking.start(
      rideId: rideId,
      initial: _tracking.driver ?? widget.driver,
      onChange: _onLiveTick,
    );
    _sheetSignature = '';
    setState(() {});
  }

  void _onLiveTick() {
    if (!mounted) return;
    final status = _tracking.status;

    // The arrived sheet is a modal route sitting on top of this screen, so
    // stage navigation deliberately waits for it to close before acting (see
    // _drainStageNavigation's !_routeIsCurrent guard) — otherwise the trip
    // could start and finish entirely behind a sheet the rider hasn't
    // dismissed yet, and dismissing it would then jump straight to "Trip
    // complete" with the in-trip phase never shown. Close it the moment the
    // trip actually starts so the rider sees that phase instead of skipping it.
    if (_arrivedSheetShowing && DriverEta.isInTrip(status)) {
      _arrivedSheetShowing = false;
      final nav = Navigator.of(context, rootNavigator: true);
      if (nav.canPop()) nav.pop();
    }

    // A driver drop is a reversible dispatch event, not the end of the
    // rider's trip. Handle it on the active Waiting owner immediately instead
    // of routing it through the generic terminal queue. The generic queue is
    // intentionally gated on route-current state; that can strand this
    // transient event when Waiting has just replaced the matching stage.
    if (status == RideStatus.cancelledByDriver) {
      if (!_leaving && !_completedOpened) {
        unawaited(_researchAfterDriverCancel());
      }
      return;
    }

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
        eta?.subtitle(firstName: driver?.displayFirstName, status: status) ?? '';
    return '${status.name}|$headline|$subtitle|${driver?.id ?? ''}'
        '|${_tracking.connectionDegraded}';
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
    _arrivedSheetShowing = true;
    unawaited(
      showDriverArrivedSheet(
        context,
        driver: _tracking.driver ?? widget.driver,
        onWay: _realtime.supportsRiderSignals ? _sendOnTheWay : null,
      ).whenComplete(() => _arrivedSheetShowing = false),
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

    // A queued outbox cancel (D-013/D-020) can land after the rider was told
    // the ride is still active. The server then reports cancelledByRider:
    // commit it locally instead of treating it as an external terminal.
    if (status == RideStatus.cancelledByRider && widget.onTerminal == null) {
      await _ride.completeServerConfirmedCancel();
      if (!mounted) return;
      await _parkMapForStageChange();
      if (!mounted) return;
      RideNavigator.home(context);
      return;
    }

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

    // The rider is not asked anything: their ride is still on, so the search
    // starts again straight away and a short notice says why the driver
    // changed.
    if (!mounted) {
      _researching = false;
      return;
    }
    showDriverCancelledNotice(context, driverName: lostDriver?.firstName);

    await _parkMapForStageChange();
    if (!mounted) {
      _researching = false;
      return;
    }

    final customDriverCancelled = widget.onDriverCancelled;
    if (customDriverCancelled != null) {
      _leaving = true;
      setState(() {});
      try {
        await customDriverCancelled(context);
      } finally {
        _researching = false;
      }
      return;
    }

    // Same ride, same price, same addresses — only the driver changes.
    // Re-open the shared session before restarting dispatch. The tracking
    // controller already reconciled the driver-drop event as terminal, and
    // without this explicit reversible dispatch transition the parked Finding
    // route observes a stale cancelledByDriver session once the search restarts.
    final redispatchRideId = _rideId;
    await _ride.resumeSearchingAfterDriverCancel(rideId: redispatchRideId);
    if (!mounted) {
      _researching = false;
      return;
    }
    _realtime.researchAfterDriverCancel();
    _leaving = true;
    setState(() {});

    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      // Normal forward path already has the parked Finding route directly
      // underneath this screen. Return to it instead of stacking another
      // Finding route every time a driver drops the ride.
      _researching = false;
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
      _researching = false;
      return;
    }

    // Widget tests or isolated hosts may not have RideRestoreGate installed.
    _researching = false;
    Navigator.pushReplacement(
      context,
      RideStageTransition(
        finding,
        settings: const RouteSettings(name: AppRoutes.findingDriver),
      ),
    );
  }

  Future<void> _openCompleted(RideStatus status) async {
    if (!mounted || _leaving || _completedOpened) return;
    _completedOpened = true;
    final rideId = _rideId;

    final customCompleted = widget.onCompleted;
    if (customCompleted != null) {
      _tracking.dispose();
      await _parkMapForStageChange();
      if (!mounted) return;
      await customCompleted(context, status);
      return;
    }

    // Keep the live subscription through the navigation barrier. Payment and
    // rating events can arrive while the active map is parking; disposing the
    // tracker before that barrier creates a blind window and can strand the
    // completion UI at tripCompleted.
    await _ride.markCompleted(status);
    if (!mounted) return;
    await _parkMapForStageChange();
    if (!mounted) return;
    final trackedStatus = _tracking.status;
    final completionStatus = trackedStatus.isCompletedSurface
        ? trackedStatus
        : status;
    final completed = RideCompleted(
      status: completionStatus,
      rideId: rideId,
      realtime: widget.realtime,
      showConnectionBanner: widget.realtime == null,
    );
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
      RideStageTransition(
        completed,
        settings: const RouteSettings(name: AppRoutes.rideCompleted),
      ),
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

    try {
      final customCancel = widget.onCancel;
      if (customCancel != null) {
        // Tracking is only torn down once the custom handler has actually
        // taken over the ride; if it throws, live updates must still work.
        await customCancel(context, outcome.reasonId);
        if (!mounted) return;
        _tracking.dispose();
        await _parkMapForStageChange();
        return;
      }

      // D-013: the server is asked first; local state only commits once it
      // has answered. Show that the request is in flight meanwhile.
      setState(() => _cancelling = true);
      final result = await _ride.markCancelled(reasonId: outcome.reasonId);
      if (!mounted) return;
      if (result != RideCancelOutcome.confirmed) {
        setState(() {
          _cancelling = false;
          _leaving = false;
        });
        _showCancelProblem(result);
        return;
      }
      _tracking.dispose();
      await _parkMapForStageChange();
      if (!mounted) return;
      RideNavigator.home(context);
    } catch (error, stack) {
      final scheduled = widget.onCancel != null;
      AppScope.instance.crashes.record(
        error,
        stack,
        rideId: _rideId,
        operation: scheduled ? 'reservation.cancel' : 'ride.cancel',
      );
      if (!mounted) return;
      setState(() {
        _cancelling = false;
        _leaving = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            scheduled
                ? reservationErrorMessage(error, ReservationAction.cancel)
                : "Couldn't cancel. Your ride is still on — try again.",
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showCancelProblem(RideCancelOutcome result) {
    final message = result == RideCancelOutcome.rejected
        ? 'This ride can no longer be cancelled.'
        : "We couldn't reach Movera to confirm your cancellation. Your ride "
              "is still active until it's confirmed — we'll retry "
              "automatically when you're back online.";
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 6),
      ),
    );
  }

  /// D-014: leaving the "Can't track this ride" screen must not silently
  /// orphan a live server ride. Try a real server cancel with any ride id
  /// still on record first; only then wipe local state and go Home.
  Future<void> _leaveUntrackedRide() async {
    if (_leaving) return;
    setState(() {
      _leaving = true;
      _cancelling = true;
    });
    try {
      await _ride.cancelUntrackedRide(rideId: _rideId);
    } catch (_) {
      // cancelUntrackedRide already logs; a transient failure stays queued
      // in the pending-cancel outbox. Leaving is still what the rider chose.
    }
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

  void _callDriverUnavailable() {
    final driver = _tracking.driver ?? widget.driver;
    SafetyController.shared.record(
      SafetyKind.maskedCall,
      rideId: _rideId,
    );
    unawaited(
      showDriverCallUnavailable(
        context,
        driverName: driver?.displayFirstName,
      ),
    );
  }

  bool get _isInTrip => DriverEta.isInTrip(_tracking.status);

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

  double _collapsedSheet(MediaQueryData media) => 190 + media.padding.bottom;

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
    if (_missingRideId) {
      return Scaffold(
        backgroundColor: const Color(0xFFF6F5F1),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  MoveraEmptyState(
                    icon: Icons.error_outline_rounded,
                    title: "Can't track this ride",
                    message:
                        "We lost track of which ride this is, so driver "
                        'updates can\'t load. Try again, or go back to Home.',
                    actionLabel: 'Retry',
                    onAction: _retryTracking,
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _cancelling ? null : _leaveUntrackedRide,
                    child: Text(_cancelling ? 'Leaving…' : 'Go home'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    final driver = _tracking.driver ?? widget.driver;
    final eta = _tracking.eta;
    final headline = eta?.headline(status: _tracking.status) ?? 'Driver found';
    final subtitle =
        eta?.subtitle(firstName: driver?.displayFirstName, status: _tracking.status) ??
        (driver == null
            ? 'Driver details will appear when matching confirms them.'
            : 'Leave now to meet ${driver.displayFirstName}');
    final media = MediaQuery.of(context);
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
              bottom: 0,
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
                      cameraBottomPadding: _collapsedSheet(media),
                    ),
            ),
            Positioned(
              top: media.padding.top + 8,
              left: 12,
              right: 12,
              child: PointerInterceptor(
                child: Row(
                  children: [
                    // Always the cancel action, never "collapse" — the
                    // chevron this used to show pre-trip is Finding's icon
                    // for collapsing its own sheet, and sharing it here made
                    // a rider trying to minimise the sheet land in the
                    // cancel flow instead.
                    MoveraIconButton.round(
                      icon: Icons.close_rounded,
                      onPressed: _confirmCancel,
                      label: 'Cancel ride',
                    ),
                    const Spacer(),
                    SafetyKitMapButton(rideId: _rideId),
                  ],
                ),
              ),
            ),
            if (widget.realtime == null || _tracking.connectionDegraded)
              Positioned(
                top: media.padding.top + 62,
                left: 12,
                right: 12,
                child: PointerInterceptor(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.realtime == null)
                        RealtimeConnectionBanner(
                          connection: AppScope.instance.realtime,
                        ),
                      // D-015: a dead ride feed used to look exactly like a
                      // stationary driver. Say so, and offer to reconnect.
                      if (_tracking.connectionDegraded) ...[
                        if (widget.realtime == null) const SizedBox(height: 8),
                        LiveFeedDegradedBanner(onRetry: _retryLiveFeed),
                      ],
                    ],
                  ),
                ),
              ),
            Positioned(
              right: 12,
              bottom: _minSheet(media) + 16,
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
                    SheetOffset.absolute(_collapsedSheet(media)),
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
            if (_cancelling)
              Positioned.fill(
                child: PointerInterceptor(
                  child: Semantics(
                    liveRegion: true,
                    label: 'Cancelling your ride',
                    child: const ColoredBox(
                      color: Color(0x66000000),
                      child: Center(child: _CancellingCard()),
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
        onCall: _callDriverUnavailable,
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
            onCall: _callDriverUnavailable,
            onMore: _openDetails,
          ),
          const SizedBox(height: 12),
          WaitingRideDetailsCard(
            rideType: widget.rideType,
            pickupAddress: widget.pickupAddress,
            destinationAddress: widget.destinationAddress,
            inTrip: _isInTrip,
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
    this.cameraBottomPadding = 140,
  });

  final CameraPosition initialPosition;
  final LatLng pickupPosition;
  final LatLng destinationPosition;
  final String pickupAddress;
  final String destinationAddress;
  final DriverTrackingController tracking;

  /// Approximates the sheet's on-screen clearance so [fitBounds] doesn't
  /// frame the driver and target only to have the bottom sheet cover them.
  final double cameraBottomPadding;

  @override
  State<_WaitingRideMap> createState() => _WaitingRideMapState();
}

class _WaitingRideMapState extends State<_WaitingRideMap>
    with SingleTickerProviderStateMixin {
  // U7: the markers live in a notifier so the moving driver only updates the
  // map's marker set. It used to setState + drop the cached map leaf on
  // every animation tick, rebuilding the whole map subtree each frame.
  final ValueNotifier<Set<Marker>> _markerSet =
      ValueNotifier<Set<Marker>>(const <Marker>{});
  Set<Marker> get _markers => _markerSet.value;
  set _markers(Set<Marker> next) => _markerSet.value = next;
  Set<Polyline> _polylines = const <Polyline>{};
  BitmapDescriptor? _riderPuck;
  BitmapDescriptor? _driverCar;
  DateTime? _lastPaint;
  Timer? _pendingRepaint;
  DateTime? _lastRouteRefresh;
  bool _mapReady = false;
  String? _routeKey;
  Widget? _leaf;
  bool _approximateRoute = false;

  // M-01/M-02: the driver marker used to teleport to each new fix. Ease
  // between the last displayed position/heading and the new one instead.
  //
  // D-016: the ease used to be a fixed 900 ms while fixes arrive every ~2–3 s,
  // so the car moved for under a second and then stood still. The duration
  // now follows the observed interval between fixes (see driverEaseDuration).
  late final AnimationController _driverAnim = AnimationController(
    vsync: this,
    duration: driverEaseDuration(null),
  )..addListener(() {
      if (!mounted) return;
      // The ease now spans most of each fix interval, so cap marker updates
      // at ~20 fps rather than on every frame for that whole time.
      final now = DateTime.now();
      final last = _lastAnimRebuild;
      if (_driverAnim.isAnimating &&
          last != null &&
          now.difference(last) < const Duration(milliseconds: 50)) {
        return;
      }
      _lastAnimRebuild = now;
      // U7: markers only; the map leaf and the rest of the stack stay put.
      _markers = _buildMarkers();
    });
  DateTime? _lastAnimRebuild;
  DateTime? _lastFixArrivedAt;
  LatLng? _driverAnimFrom;
  LatLng? _driverAnimTo;
  double _driverHeadingFrom = 0;
  double _driverHeadingTo = 0;

  // M-08: last point the camera was fit to, so a fix that hasn't moved the
  // driver meaningfully doesn't re-trigger animateCamera every paint.
  LatLng? _lastFitDriverPoint;
  bool _lastFitInTrip = false;

  bool get _inTrip => DriverEta.isInTrip(widget.tracking.status);

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

  @override
  void dispose() {
    _pendingRepaint?.cancel();
    _driverAnim.dispose();
    _markerSet.dispose();
    super.dispose();
  }

  void paintIfDue() {
    final now = DateTime.now();
    if (_lastPaint != null &&
        now.difference(_lastPaint!) < const Duration(milliseconds: 400)) {
      // M-03: a fix arriving inside the throttle window used to be dropped
      // until the next unrelated event happened to call paintIfDue again.
      // Schedule one for the remainder of this window instead.
      final remaining =
          const Duration(milliseconds: 400) - now.difference(_lastPaint!);
      _pendingRepaint?.cancel();
      _pendingRepaint = Timer(remaining, () {
        if (mounted) paintIfDue();
      });
      return;
    }
    _lastPaint = now;
    _updateDriverAnimation();

    final next = _buildMarkers();
    final markersChanged = !_sameMarkers(_markers, next);
    if (markersChanged && mounted) {
      // U7: no setState, no new map leaf; the marker listener updates it.
      _markers = next;
    }
    _maybeFitCamera();

    if (_mapReady &&
        (_lastRouteRefresh == null ||
            now.difference(_lastRouteRefresh!) >=
                const Duration(seconds: 10))) {
      unawaited(_refreshRoadRoute());
    }
  }

  /// Feeds a new fix into the from/to pair the animation eases between.
  /// The very first fix snaps (there is nothing to ease from yet).
  void _updateDriverAnimation() {
    final eta = widget.tracking.eta;
    final lat = eta?.latitude;
    final lng = eta?.longitude;
    if (lat == null || lng == null) return;
    final next = LatLng(lat, lng);
    final previousTo = _driverAnimTo;
    if (previousTo != null &&
        previousTo.latitude == next.latitude &&
        previousTo.longitude == next.longitude) {
      return;
    }
    final arrivedAt = DateTime.now();
    final previousArrival = _lastFixArrivedAt;
    _lastFixArrivedAt = arrivedAt;
    if (previousTo == null) {
      // First fix: nothing to animate from.
      _driverAnimFrom = next;
      _driverAnimTo = next;
      _driverHeadingFrom = 0;
      _driverHeadingTo = 0;
      return;
    }
    _driverAnimFrom = _currentDriverPosition() ?? previousTo;
    _driverAnimTo = next;
    _driverHeadingFrom = _currentDriverHeading();
    _driverHeadingTo = _bearingDegrees(previousTo, next) ?? _driverHeadingFrom;
    _driverAnim
      ..stop()
      ..duration = driverEaseDuration(
        previousArrival == null ? null : arrivedAt.difference(previousArrival),
      )
      ..forward(from: 0);
  }

  LatLng? _currentDriverPosition() {
    final from = _driverAnimFrom;
    final to = _driverAnimTo;
    if (from == null || to == null) return to;
    final t = _driverAnim.value;
    return LatLng(
      from.latitude + (to.latitude - from.latitude) * t,
      from.longitude + (to.longitude - from.longitude) * t,
    );
  }

  double _currentDriverHeading() {
    if (_driverAnimFrom == null) return _driverHeadingTo;
    return lerpHeading(_driverHeadingFrom, _driverHeadingTo, _driverAnim.value);
  }

  /// Initial bearing from [from] to [to] in degrees, or null when the two
  /// points coincide (no direction to point).
  double? _bearingDegrees(LatLng from, LatLng to) {
    if (from.latitude == to.latitude && from.longitude == to.longitude) {
      return null;
    }
    final lat1 = from.latitude * math.pi / 180;
    final lat2 = to.latitude * math.pi / 180;
    final dLng = (to.longitude - from.longitude) * math.pi / 180;
    final y = math.sin(dLng) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLng);
    return normalizeHeading(math.atan2(y, x) * 180 / math.pi);
  }

  void _maybeFitCamera() {
    final driver = _currentDriverPosition();
    if (driver == null) return;
    final target = _inTrip ? widget.destinationPosition : widget.pickupPosition;
    final samePoint = _lastFitDriverPoint != null &&
        _lastFitInTrip == _inTrip &&
        _lastFitDriverPoint!.latitude == driver.latitude &&
        _lastFitDriverPoint!.longitude == driver.longitude;
    if (samePoint) return;
    _lastFitDriverPoint = driver;
    _lastFitInTrip = _inTrip;
    // D-018: the sheet's clearance used to be passed as fitBounds' uniform
    // padding, i.e. applied to all four sides, which zoomed far out. Reserve
    // it at the bottom only by extending the framed bounds southwards.
    final fit = waitingCameraFit(
      a: GeoPoint(driver.latitude, driver.longitude),
      b: GeoPoint(target.latitude, target.longitude),
      viewportHeight: MediaQuery.maybeSizeOf(context)?.height ?? 800,
      bottomObstruction: widget.cameraBottomPadding,
    );
    unawaited(
      AppScope.instance.maps.fitBounds(
        fit.southwest,
        fit.northeast,
        padding: fit.padding,
      ),
    );
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
    final driverPosition = _currentDriverPosition();
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
      if (driverPosition != null)
        Marker(
          markerId: const MarkerId('driver'),
          position: driverPosition,
          rotation: _currentDriverHeading(),
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

    // roadRoutePolyline falls back to a straight two-point line whenever a
    // real road route can't be resolved. A genuine road route for anything
    // but a trivially short hop has more than two vertices, so this is a
    // reasonable signal to tell the rider the line is approximate rather
    // than implying turn-by-turn accuracy that isn't there.
    final approximate = route.points.length <= 2;
    setState(() {
      _polylines = {route};
      _approximateRoute = approximate;
      _leaf = null;
    });
  }

  Widget _buildMap(Set<Marker> markers) {
    return CustomGoogleMap(
      key: const ValueKey('waiting-map'),
      initialPosition: widget.initialPosition,
      markers: markers,
      polylines: _polylines,
      myLocationEnabled: false,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      compassEnabled: false,
      trafficEnabled: true,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: _leaf ??= RepaintBoundary(
            child: ValueListenableBuilder<Set<Marker>>(
              valueListenable: _markerSet,
              builder: (context, markers, _) => _buildMap(markers),
            ),
          ),
        ),
        if (_approximateRoute)
          Positioned(
            left: 12,
            bottom: 12,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.62),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Approximate route',
                  style: TextStyle(color: Colors.white, fontSize: 11),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _CancellingCard extends StatelessWidget {
  const _CancellingCard();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                'Cancelling your ride…',
                style: waitingText(15, weight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// D-015: shown when the ride's realtime stream itself errored or closed, so
/// the driver marker is frozen rather than the driver standing still.
class LiveFeedDegradedBanner extends StatelessWidget {
  const LiveFeedDegradedBanner({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      container: true,
      label: 'Live updates paused. Driver position may be out of date.',
      child: DecoratedBox(
        key: const ValueKey('waiting-live-feed-degraded'),
        decoration: BoxDecoration(
          color: const Color(0xF71D252C),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 6, 8),
          child: Row(
            children: [
              const Icon(
                Icons.portable_wifi_off_rounded,
                size: 18,
                color: Colors.white,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ExcludeSemantics(
                  child: Text(
                    'Live updates paused. Driver position may be out of date.',
                    style: waitingText(12.5, color: Colors.white),
                  ),
                ),
              ),
              TextButton(
                onPressed: onRetry,
                style: TextButton.styleFrom(foregroundColor: Colors.white),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
