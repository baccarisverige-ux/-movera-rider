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
import 'package:movera_rider/features/driver_arriving/application/driver_tracking_controller.dart';
import 'package:movera_rider/features/driver_arriving/presentation/driver_profile_page.dart';
import 'package:movera_rider/features/finding_driver/domain/cancellation_reason.dart';
import 'package:movera_rider/features/finding_driver/presentation/cancel_ride_sheet.dart';
import 'package:movera_rider/features/finding_driver/presentation/ride_details_sheet.dart';
import 'package:movera_rider/features/active_ride/presentation/driver_arrived_sheet.dart';
import 'package:movera_rider/features/ride_booking/domain/entities/matched_driver.dart';
import 'package:movera_rider/features/ride_booking/domain/ride_status.dart';
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
  Set<Marker> _markers = {};
  final ActiveRideController _ride = ActiveRideController();
  late final DriverTrackingController _tracking = DriverTrackingController(
    pickupLat: widget.pickupPosition.latitude,
    pickupLng: widget.pickupPosition.longitude,
  );
  late final CameraPosition _initialPosition;
  late final AnimationController _sheetSlide;
  bool _leaving = false;
  bool _completedOpened = false;
  bool _arrivalAnnounced = false;
  bool _overlayOn = false;

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
    _loadMarkers();
    SafetyController.shared.load();
    final rideId = AppScope.instance.ride.rideId;
    if (rideId != null) {
      _tracking.start(
        rideId: rideId,
        initial: widget.driver,
        onChange: () {
          if (!mounted) return;
          setState(_loadMarkers);
          _maybeAnnounceArrival();
          _maybeOpenCompleted();
        },
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sheetSlide.duration = MoveraMotion.of(context, MoveraDurations.sheetOpen);
  }

  void _loadMarkers() {
    _markers = {
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
      if (_tracking.eta?.latitude != null && _tracking.eta?.longitude != null)
        Marker(
          markerId: const MarkerId('driver'),
          position: LatLng(_tracking.eta!.latitude!, _tracking.eta!.longitude!),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueViolet,
          ),
        ),
    };
  }

  /// The driver reaching pickup is easy to miss on a map the rider is not
  /// watching, so say it once and never again for this ride.
  void _maybeAnnounceArrival() {
    if (!mounted || _leaving || _arrivalAnnounced || _completedOpened) return;
    if (_tracking.status != RideStatus.driverWaiting) return;
    _arrivalAnnounced = true;
    unawaited(
      showDriverArrivedSheet(
        context,
        driver: _tracking.driver ?? widget.driver,
      ),
    );
  }

  void _maybeOpenCompleted() {
    if (!mounted || _leaving || _completedOpened) return;
    final status = _tracking.status;
    if (!status.isCompletedSurface) return;
    unawaited(_openCompleted(status));
  }

  Future<void> _openCompleted(RideStatus status) async {
    if (!mounted || _leaving || _completedOpened) return;
    _completedOpened = true;
    await _ride.markCompleted(status);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      BottomToTopTransition(const RideCompleted()),
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
        await _confirmCancel();
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
                child: CustomGoogleMap(
                  key: const ValueKey('waiting-map'),
                  initialPosition: _initialPosition,
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
                      onPressed: _confirmCancel,
                      label: 'Cancel ride',
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
                  onPressed: () {
                    AppScope.instance.camera.focusOnPickup(
                      GeoPoint(
                        widget.pickupPosition.latitude,
                        widget.pickupPosition.longitude,
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
