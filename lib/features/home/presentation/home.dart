// ignore_for_file: deprecated_member_use, unused_element, unused_field

import 'dart:async';
import 'dart:math' as math;

import 'dart:ui' show ImageFilter;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:movera_rider/app/di.dart';
import 'package:movera_rider/app/router/routes.dart';
import 'package:movera_rider/core/constants/appassets.dart';
import 'package:movera_rider/core/constants/appcolors.dart';
import 'package:movera_rider/core/constants/appfontweight.dart';
import 'package:movera_rider/core/maps/camera_mode.dart';
import 'package:movera_rider/core/maps/geo_point.dart';
import 'package:movera_rider/core/maps/map_owners.dart';
import 'package:movera_rider/core/maps/map_lifecycle.dart';
import 'package:movera_rider/core/performance/route_transition_metrics.dart';
import 'package:movera_rider/core/debug/web_qa_hooks.dart';
import 'package:movera_rider/core/web/web_overlay.dart';
import 'package:movera_rider/features/destination/application/destination_controller.dart';
import 'package:movera_rider/features/home/application/home_controller.dart';
import 'package:movera_rider/features/home/application/home_places_controller.dart';
import 'package:movera_rider/features/pickup/presentation/confirm_pickup_spot.dart';
import 'package:movera_rider/features/wallet/presentation/wallet.dart';
import 'package:movera_rider/features/profile/presentation/account_home.dart';
import 'package:movera_rider/features/profile/presentation/profile.dart';
import 'package:movera_rider/features/ride_selection/presentation/select_ride.dart';
import 'package:movera_rider/core/web/web_search_interrupted.dart';
import 'package:movera_rider/features/ride_booking/application/ride_restore_coordinator.dart';
import 'package:movera_rider/shared/design_system/movera_toast.dart';
import 'package:movera_rider/shared/widgets/early_input_capture.dart';
import 'package:movera_rider/features/reservations/presentation/home_reservation_chrono.dart';
import 'package:movera_rider/features/reservations/presentation/ride_scheduled.dart';
import 'package:movera_rider/features/scheduled_rides/presentation/schedule_ride.dart';
import 'package:movera_rider/features/home/presentation/side_menu.dart';
import 'package:movera_rider/features/home/presentation/widgets/comfort_ride_carousel.dart';
import 'package:movera_rider/features/home/presentation/widgets/advance_booking_card.dart';
import 'package:movera_rider/features/home/presentation/widgets/premium_bottom_nav_item.dart';
import 'package:movera_rider/features/home/presentation/widgets/premium_top_actions.dart';
import 'package:movera_rider/features/home/presentation/widgets/saved_places_row.dart';
import 'package:movera_rider/features/home/presentation/widgets/where_to_card.dart';
import 'package:movera_rider/features/home/presentation/widgets/premium_route_location_badge.dart';
import 'package:movera_rider/shared/widgets/custom_google_map.dart';
import 'package:movera_rider/shared/widgets/movera_map_markers.dart';
import 'package:movera_rider/shared/design_system/motion/movera_motion.dart';
import 'package:movera_rider/shared/design_system/movera_sheet.dart';
import 'package:movera_rider/shared/widgets/custom_text_widget.dart';
import 'package:movera_rider/shared/widgets/navigation_transition.dart';
import 'package:movera_rider/shared/widgets/responsive_size.dart';
import 'package:movera_rider/shared/widgets/sizedbox_extention.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:smooth_sheets/smooth_sheets.dart';

typedef _SavedPlaceData = SavedPlaceData;

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> with WidgetsBindingObserver {
  final SheetController _homeSheetController = SheetController();
  final PanelController _profilePanelController = PanelController();
  Timer? _sheetIdleTimer;
  late final HomeLocationController _locationCtl = HomeLocationController(
    location: AppScope.instance.location,
    geocoding: AppScope.instance.geocoding,
    motion: AppScope.instance.motion,
  );
  late final HomePlacesController _places = HomePlacesController();
  bool _showRecenterButton = true;
  BitmapDescriptor? _locationPuckCompact;
  BitmapDescriptor? _locationPuckExpanded;
  ui.Image? _puckCompactImage;
  ui.Image? _puckExpandedImage;
  int _webPuckPaintGen = 0;

  static const double _sheetMinHeight = 184;
  static const double _sheetMaxHeight = 294;

  bool _destinationSheetOpen = false;
  bool _findingLocation = true;

  bool get _locationPulseExpanded => _locationCtl.pulseExpanded;
  set _locationPulseExpanded(bool value) => _locationCtl.pulseExpanded = value;
  double get _locationHeading => _locationCtl.heading;
  set _locationHeading(double value) => _locationCtl.heading = value;
  bool get _hasCompassHeading => _locationCtl.hasCompassHeading;
  set _hasCompassHeading(bool value) => _locationCtl.hasCompassHeading = value;
  double get _lastMapZoom => _locationCtl.lastMapZoom;
  set _lastMapZoom(double value) => _locationCtl.lastMapZoom = value;
  LatLng get _lastMapTarget => _locationCtl.lastMapTarget;
  set _lastMapTarget(LatLng value) => _locationCtl.lastMapTarget = value;
  String? get _pickupAddress => _places.pickupAddress;
  set _pickupAddress(String? value) => _places.pickupAddress = value;
  String? get _destinationAddress => _places.destinationAddress;
  set _destinationAddress(String? value) => _places.destinationAddress = value;
  String? get _homeAddress => _places.homeAddress;
  set _homeAddress(String? value) => _places.homeAddress = value;
  String? get _workAddress => _places.workAddress;
  set _workAddress(String? value) => _places.workAddress = value;
  List<String> get _routeStops => _places.routeStops;
  set _routeStops(List<String> value) => _places.routeStops = value;
  LatLng? get _currentLatLng => _places.currentLatLng;
  set _currentLatLng(LatLng? value) => _places.currentLatLng = value;
  LatLng? get _tripPickupLatLng => _places.tripPickupLatLng;
  set _tripPickupLatLng(LatLng? value) => _places.tripPickupLatLng = value;
  List<String> get _recentAddresses => _places.recentAddresses;
  set _recentAddresses(List<String> value) => _places.recentAddresses = value;
  List<_SavedPlaceData> get _savedPlaces => _places.savedPlaces;
  set _savedPlaces(List<_SavedPlaceData> value) => _places.savedPlaces = value;

  static const int _maxCustomPlaces = HomePlacesController.maxCustom;

  GoogleMapController? _mapController;
  final ValueNotifier<bool> _mapParked = ValueNotifier(false);
  final MapParkingGuard _mapParkingGuard = MapParkingGuard();
  bool get _homeMapParked => _mapParked.value;
  Set<Marker> get _markers => _locationCtl.markers;
  set _markers(Set<Marker> value) => _locationCtl.markers = value;
  Set<Circle> get _locationCircles => _locationCtl.locationCircles;
  set _locationCircles(Set<Circle> value) =>
      _locationCtl.locationCircles = value;
  Set<Polygon> get _locationDirection => _locationCtl.locationDirection;
  set _locationDirection(Set<Polygon> value) =>
      _locationCtl.locationDirection = value;

  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(59.3293, 18.0686),
    zoom: 13.0,
  );

  static const Color _premiumInk = Color(0xFF1D252C);
  static const Color _premiumMuted = Color(0xFF5C656C);
  static const Color _premiumLine = Color(0xFFE7EBEE);
  static const Color _premiumAccent = Color(0xFF2D5878);
  static const Color _premiumAccentSoft = Color(0xFFEAF2F8);

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
    WidgetsBinding.instance.addObserver(this);
    reportHomeBuilt();
    _homeSheetController.addListener(_syncHomeSheetState);
    _loadMarkers();
    _restoreAddressData();
    _startHeadingTracking();
    _announceInterruptedSearch();
  }

  /// A reload during Finding Driver drops the search. Landing on an empty Home
  /// with no explanation reads as though the ride was never requested, so say
  /// what happened.
  void _announceInterruptedSearch() {
    // Two sources: builds that keep the snapshot leave the coordinator a flag;
    // the web build's snapshot is gone before Flutter starts, so it leaves a
    // note in the session instead.
    final interrupted =
        RideRestoreCoordinator.instance.takeSearchInterrupted() |
        takeWebSearchInterrupted();
    if (!interrupted) return;
    // Let the first frame settle so the messenger has a Scaffold to put this
    // in, and leave it up long enough to actually be read.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      MoveraToast.show(
        context,
        'Your ride search was interrupted. Book again when you are ready.',
        duration: const Duration(seconds: 8),
      );
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _locationCtl.pauseLiveUpdates();
      return;
    }
    if (state != AppLifecycleState.resumed) return;
    _locationCtl.resumeLiveUpdates();
    if (_locationCtl.state == HomeLocationState.temporarilyUnavailable) {
      _locationCtl.recoverLiveLocation(
        isMounted: () => mounted,
        onFix: (latLng, heading) {
          _currentLatLng = latLng;
          _locationHeading = heading;
          _updateLocationVisuals();
        },
      );
    } else if (_currentLatLng == null) {
      _detectCurrentAddress();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sheetIdleTimer?.cancel();
    _locationCtl.dispose();
    _puckCompactImage?.dispose();
    _puckExpandedImage?.dispose();
    _mapParked.dispose();
    AppScope.instance.maps.detach(owner: MapOwners.home);
    setWebOverlayOpen(false);
    _homeSheetController
      ..removeListener(_syncHomeSheetState)
      ..dispose();
    super.dispose();
  }

  Future<void> _restoreAddressData() async {
    await _places.load();
    if (mounted) setState(() {});
    await _detectCurrentAddress();
  }

  Future<void> _persistAddressData() => _places.persist();

  Future<void> _detectCurrentAddress() async {
    if (mounted) setState(() => _findingLocation = true);
    try {
      final detected = await _locationCtl.detectCurrent();
      if (!mounted) return;
      if (detected.denied) {
        setState(() {
          _findingLocation = false;
          _pickupAddress ??= 'Current location';
        });
        return;
      }
      final target = detected.target;
      if (target == null) return;
      setState(() {
        _pickupAddress = detected.address;
        _currentLatLng = target;
        _findingLocation = false;
        _locationCtl.clearOverlays();
        _locationHeading = detected.heading;
      });
      await _prepareLocationPuckIcons();
      await _locationCtl.bindLiveLocation(
        isMounted: () => mounted,
        onFix: (latLng, heading) {
          _currentLatLng = latLng;
          _locationHeading = heading;
          _updateLocationVisuals();
        },
        onHeading: (heading) {
          _locationHeading = heading;
          _hasCompassHeading = true;
          _updateLocationVisuals();
        },
        onPulse: _updateLocationVisuals,
      );
      await AppScope.instance.maps.animateCamera(
        GeoPoint(target.latitude, target.longitude),
        zoom: 15,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _findingLocation = false;
        _pickupAddress ??= 'Current location';
      });
    }
  }

  String _shortAddress(String? address, {int maxLength = 24}) {
    final value = address?.trim() ?? '';
    if (value.isEmpty) return 'Set location';
    return value.length <= maxLength
        ? value
        : '${value.substring(0, maxLength - 1)}…';
  }

  String _targetTitle(String target, String? customType) {
    switch (target) {
      case 'pickup':
        return 'Choose pickup';
      case 'home':
        return 'Set Home address';
      case 'work':
        return 'Set Work address';
      case 'custom':
        return 'Set ${_placeLabel(customType ?? 'other')} address';
      default:
        return 'Where to?';
    }
  }

  String? _existingAddressFor(String target) => _places.existingFor(target);

  Future<String> _normaliseAddress(String input) {
    return _locationCtl.normaliseAddress(input);
  }

  Future<void> _moveMapToAddress(String address) async {
    final target = await _locationCtl.geocodeLatLng(address);
    if (target == null) return;
    await AppScope.instance.maps.animateCamera(
      GeoPoint(target.latitude, target.longitude),
      zoom: 15,
    );
  }

  void _rememberAddress(String address) => _places.remember(address);

  Future<void> _saveAddressFor(
    String target,
    String address, {
    String? customType,
  }) async {
    final resolved = await _normaliseAddress(address);
    if (resolved.isEmpty || !mounted) return;

    LatLng? resolvedPickupPosition;
    if (target == 'pickup') {
      if (resolved.toLowerCase() == 'current location') {
        resolvedPickupPosition = _currentLatLng;
      } else {
        final geocodedPickup = await _locationCtl.geocodeLatLng(resolved);
        if (geocodedPickup != null) {
          resolvedPickupPosition = geocodedPickup;
        }
      }
    }
    if (!mounted) return;

    setState(() {
      _places.applyResolved(
        target: target,
        address: resolved,
        pickupPosition: resolvedPickupPosition,
        customType: customType,
      );
      if (target == 'destination') {
        DestinationController().remember(address: resolved);
      }
    });
    await _persistAddressData();
    if (target == 'pickup' || target == 'destination') {
      await _moveMapToAddress(resolved);
    }
  }

  Future<void> _handleDestinationTap() async {
    // Capture from the tap itself: the sheet sequencing below takes long enough
    // that anything typed in the meantime would otherwise be lost.
    final capture = EarlyInputCapture()..start();
    try {
      if (!_destinationSheetOpen) {
        await _openDestinationSheet();
        await WidgetsBinding.instance.endOfFrame;
        if (!mounted) return;
      }
      await _showRouteAddressPicker(
        initialField: 'destination',
        capture: capture,
      );
    } finally {
      capture.stop();
    }
  }

  Future<void> _useSavedPlaceAsDestination(
    String? savedAddress, {
    required String target,
    String? customType,
  }) async {
    final address = savedAddress?.trim() ?? '';
    if (address.isEmpty) {
      await _showAddressPicker(target: target, customType: customType);
      return;
    }

    final destination = await _normaliseAddress(address);
    if (destination.isEmpty || !mounted) return;

    setState(() {
      _destinationAddress = destination;
      _rememberAddress(destination);
    });
    await _persistAddressData();
    await _withParkedHomeMap(() async {
      final pickupResult = await _openPickupMapPicker(
        _pickupAddress ?? 'Current location',
      );
      if (pickupResult == null || !mounted) return null;
      final pickupPosition = pickupResult.position;
      setState(() {
        _pickupAddress = pickupResult.address;
        _tripPickupLatLng = pickupResult.position;
      });
      if (!mounted) return null;
      final confirmedPickupPosition = pickupPosition;
      var resolvedDestination = destination;
      LatLng? destinationPosition;
      final destinationResult = await _locationCtl.geocodePlace(destination);
      if (destinationResult != null) {
        resolvedDestination = destinationResult.address;
        destinationPosition = destinationResult.point;
      } else {
        if (mounted) {
          MoveraToast.show(
            context,
            'Choose a valid destination address.',
          );
        }
        return null;
      }
      final confirmedDestinationPosition = destinationPosition;
      if (!mounted) return null;
      return Navigator.of(context).push(
        RideStageTransition(
          SelectRide(
            pickupAddress: _pickupAddress ?? 'Current location',
            destinationAddress: resolvedDestination,
            pickupPosition: confirmedPickupPosition,
            destinationPosition: confirmedDestinationPosition,
            stops: List<String>.from(_routeStops),
            bookingMode: BookingMode.now,
            onScheduled: (context, id) => RideScheduledPage.open(
              context,
              reservationId: id,
              replace: true,
            ),
          ),
          settings: const RouteSettings(name: AppRoutes.selectRide),
        ),
      );
    });
  }

  Future<T?> _withParkedHomeMap<T>(Future<T?> Function() action) async {
    final parkedNow = _mapParkingGuard.enter();
    try {
      if (parkedNow) {
        final parkingWatch = Stopwatch()..start();
        setWebOverlayOpen(false);
        _mapParked.value = true;
        _locationCtl.pauseLiveUpdates();
        AppScope.instance.mapLifecycle.park();
        AppScope.instance.maps.detach(owner: MapOwners.home);
        _mapController = null;
        // Let Flutter remove the platform map for one rendered frame before
        // the next map-heavy ride screen mounts.
        await WidgetsBinding.instance.endOfFrame;
        parkingWatch.stop();
        RouteTransitionMetrics.homeMapParking(parkingWatch.elapsed);
        if (!mounted) return null;
      }
      return await action();
    } finally {
      final resumeNow = _mapParkingGuard.exit();
      if (resumeNow && mounted) {
        AppScope.instance.mapLifecycle.resume();
        _closeDestinationSheet();
        _locationCtl.resumeLiveUpdates();
        _mapParked.value = false;
      }
    }
  }

  Future<PickupMapResult?> _openPickupMapPicker(
    String address, {
    bool isDestination = false,
  }) async {
    LatLng initialPosition =
        _tripPickupLatLng ?? _currentLatLng ?? _initialPosition.target;
    final cleanAddress = address.trim();
    if (cleanAddress.isNotEmpty &&
        cleanAddress.toLowerCase() != 'current location') {
      final geocoded = await _locationCtl.geocodeLatLng(cleanAddress);
      if (geocoded != null) initialPosition = geocoded;
    }
    if (!mounted) return null;
    return _withParkedHomeMap(() async {
      final result = await ConfirmPickupSpot.open(
        context,
        initialPosition: initialPosition,
        initialAddress: cleanAddress.isEmpty
            ? (_pickupAddress ?? 'Current location')
            : cleanAddress,
        title: isDestination ? 'Confirm destination' : 'Confirm pickup spot',
        confirmLabel: isDestination ? 'Confirm destination' : 'Confirm pickup',
      );
      if (result == null) return null;
      return PickupMapResult(
        address: result.address,
        position: result.position,
      );
    });
  }

  Future<void> _showRouteAddressPicker({
    required String initialField,
    EarlyInputCapture? capture,
  }) async {
    final pickupController = TextEditingController(
      text: _pickupAddress?.trim().isNotEmpty == true
          ? _pickupAddress!.trim()
          : 'Current location',
    );
    final destinationController = TextEditingController(
      text: _destinationAddress ?? '',
    );
    final stopControllers = _routeStops
        .map((address) => TextEditingController(text: address))
        .toList();
    final pickupFocus = FocusNode();
    final destinationFocus = FocusNode();
    final stopFocusNodes = stopControllers.map((_) => FocusNode()).toList();

    var activeField = initialField;
    var activeStopIndex = -1;
    var query = initialField == 'pickup'
        ? pickupController.text
        : destinationController.text;
    // ignore: unused_local_variable
    var pickupConfirmedOnMap = false;
    // ignore: unused_local_variable
    LatLng? confirmedPickupLatLng;
    var destinationConfirmedOnMap = false;
    LatLng? confirmedDestinationLatLng;

    TextEditingController activeController() {
      if (activeField == 'pickup') return pickupController;
      if (activeField == 'stop' &&
          activeStopIndex >= 0 &&
          activeStopIndex < stopControllers.length) {
        return stopControllers[activeStopIndex];
      }
      return destinationController;
    }

    // Either the capture the caller started at tap time, or a fresh one for
    // entry points that open this sheet directly.
    final routeCapture = capture ?? (EarlyInputCapture()..start());
    final ownsCapture = capture == null;
    routeCapture.attach(
      initialField == 'pickup' ? pickupController : destinationController,
      initialField == 'pickup' ? pickupFocus : destinationFocus,
    );

    final sheetDisposables = <ChangeNotifier>[
      pickupController,
      destinationController,
      pickupFocus,
      destinationFocus,
      ...stopControllers,
      ...stopFocusNodes,
    ];

    Map<String, dynamic>? draft;
    try {
      draft = await MoveraSheet.show<Map<String, dynamic>>(
        context: context,
        backgroundColor: Colors.transparent,
        barrierColor: Colors.black.withValues(alpha: 0.26),
        builder: (sheetContext) {
          return MoveraSheetDisposables(
            disposables: sheetDisposables,
            child: PointerInterceptor(
              child: StatefulBuilder(
              builder: (context, setModalState) {
                final filteredRecent = _recentAddresses
                    .where(
                      (address) =>
                          query.trim().isEmpty ||
                          address.toLowerCase().contains(
                            query.trim().toLowerCase(),
                          ),
                    )
                    .take(5)
                    .toList();

                void activateField(
                  String field,
                  TextEditingController controller, {
                  int stopIndex = -1,
                }) {
                  setModalState(() {
                    activeField = field;
                    activeStopIndex = stopIndex;
                    query = controller.text;
                  });
                }

                Widget routeField({
                  required String field,
                  required String label,
                  required String hint,
                  required TextEditingController controller,
                  required FocusNode focusNode,
                  int stopIndex = -1,
                  bool removable = false,
                  VoidCallback? onMapTap,
                  Color? badgeColor,
                }) {
                  final isActive =
                      activeField == field &&
                      (field != 'stop' || activeStopIndex == stopIndex);
                  return Row(
                    children: [
                      SizedBox(
                        width: ResSize.w * 27,
                        child: Center(
                          child: badgeColor != null
                              ? Semantics(
                                  button: true,
                                  label: field == 'pickup'
                                      ? 'Set pickup on map'
                                      : 'Select final destination',
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap:
                                        onMapTap ??
                                        () => activateField(
                                          field,
                                          controller,
                                          stopIndex: stopIndex,
                                        ),
                                    child: PremiumRouteLocationBadge(
                                      color: badgeColor,
                                      size: ResSize.h * 27,
                                    ),
                                  ),
                                )
                              : Container(
                                  width: ResSize.w * 10,
                                  height: ResSize.h * 10,
                                  decoration: BoxDecoration(
                                    color: AppColor.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: _premiumInk,
                                      width: 2,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      8.width,
                      Expanded(
                        child: TextField(
                          controller: controller,
                          focusNode: focusNode,
                          autofocus: isActive,
                          onTap: () => activateField(
                            field,
                            controller,
                            stopIndex: stopIndex,
                          ),
                          onChanged: (value) {
                            if (isActive) {
                              setModalState(() {
                                if (field == 'pickup') {
                                  pickupConfirmedOnMap = false;
                                  confirmedPickupLatLng = null;
                                } else if (field == 'destination') {
                                  destinationConfirmedOnMap = false;
                                  confirmedDestinationLatLng = null;
                                }
                              });
                              AppScope.instance.destinationSearch.type(value, (
                                text,
                              ) {
                                if (!mounted) return;
                                setModalState(() => query = text);
                              });
                            }
                          },
                          textInputAction: TextInputAction.search,
                          style: TextStyle(
                            color: _premiumInk,
                            fontSize: ResSize.setSp(14),
                            fontWeight: FontWeight.w600,
                          ),
                          decoration: InputDecoration(
                            labelText: label,
                            hintText: hint,
                            labelStyle: TextStyle(
                              color: isActive ? _premiumAccent : _premiumMuted,
                              fontSize: ResSize.setSp(10),
                              fontWeight: FontWeight.w600,
                            ),
                            hintStyle: TextStyle(
                              color: _premiumMuted.withValues(alpha: 0.68),
                              fontSize: ResSize.setSp(13),
                              fontWeight: FontWeight.w400,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              vertical: ResSize.h * 12,
                            ),
                          ),
                        ),
                      ),
                      if (removable)
                        IconButton(
                          onPressed: () {
                            final removedController = stopControllers.removeAt(
                              stopIndex,
                            );
                            final removedFocus = stopFocusNodes.removeAt(
                              stopIndex,
                            );
                            sheetDisposables.remove(removedController);
                            sheetDisposables.remove(removedFocus);
                            removedController.dispose();
                            removedFocus.dispose();
                            setModalState(() {
                              activeField = 'destination';
                              activeStopIndex = -1;
                              query = destinationController.text;
                            });
                            destinationFocus.requestFocus();
                          },
                          icon: const Icon(Icons.close_rounded),
                          color: _premiumMuted,
                          iconSize: ResSize.h * 18,
                          tooltip: 'Remove stop',
                        ),
                    ],
                  );
                }

                final routeRows = <Widget>[
                  routeField(
                    field: 'pickup',
                    label: 'Pickup',
                    hint: 'Enter pickup address',
                    controller: pickupController,
                    focusNode: pickupFocus,
                    badgeColor: const Color(0xFF079A60),
                    onMapTap: () async {
                      FocusScope.of(context).unfocus();
                      final result = await _openPickupMapPicker(
                        pickupController.text.trim(),
                      );
                      if (result == null || !mounted) return;
                      pickupController.text = result.address;
                      pickupController.selection = TextSelection.collapsed(
                        offset: pickupController.text.length,
                      );
                      setModalState(() {
                        pickupConfirmedOnMap = true;
                        confirmedPickupLatLng = result.position;
                        query = pickupController.text;
                      });
                    },
                  ),
                  const Divider(
                    color: Color(0xFFE4E8EA),
                    height: 1,
                    indent: 38,
                  ),
                ];

                for (var index = 0; index < stopControllers.length; index++) {
                  routeRows
                    ..add(
                      routeField(
                        field: 'stop',
                        label: 'Stop ${index + 1}',
                        hint: 'Enter stop address',
                        controller: stopControllers[index],
                        focusNode: stopFocusNodes[index],
                        stopIndex: index,
                        removable: true,
                      ),
                    )
                    ..add(
                      const Divider(
                        color: Color(0xFFE4E8EA),
                        height: 1,
                        indent: 38,
                      ),
                    );
                }

                routeRows.add(
                  routeField(
                    field: 'destination',
                    label: 'Final destination',
                    hint: 'Where to?',
                    controller: destinationController,
                    focusNode: destinationFocus,
                    badgeColor: const Color(0xFF1769E8),
                    onMapTap: () {
                      activateField('destination', destinationController);
                      destinationFocus.requestFocus();
                    },
                  ),
                );

                routeCapture.onChanged = (value) {
                  setModalState(() {
                    if (activeField == 'pickup') {
                      pickupConfirmedOnMap = false;
                      confirmedPickupLatLng = null;
                    } else if (activeField == 'destination') {
                      destinationConfirmedOnMap = false;
                      confirmedDestinationLatLng = null;
                    }
                  });
                  AppScope.instance.destinationSearch.type(value, (text) {
                    if (!mounted) return;
                    setModalState(() => query = text);
                  });
                };
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: Container(
                    height: MediaQuery.of(context).size.height * 0.92,
                    padding: EdgeInsets.fromLTRB(
                      ResSize.w * 14,
                      ResSize.h * 10,
                      ResSize.w * 14,
                      ResSize.h * 16,
                    ),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: ResSize.w * 42,
                          height: ResSize.h * 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFFD8DDE0),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        14.height,
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => Navigator.pop(sheetContext),
                              icon: const Icon(Icons.arrow_back_rounded),
                              color: _premiumInk,
                              tooltip: 'Back',
                            ),
                            Expanded(
                              child: Center(
                                child: TextWidget(
                                  text: 'Plan your ride',
                                  color: _premiumInk,
                                  fontSize: 19,
                                  fontWeight: fwBold,
                                ),
                              ),
                            ),
                            SizedBox(width: ResSize.w * 48),
                          ],
                        ),
                        14.height,
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: ResSize.w * 10,
                                  vertical: ResSize.h * 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColor.white,
                                  borderRadius: BorderRadius.circular(23),
                                  border: Border.all(
                                    color: _premiumInk,
                                    width: 1.25,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.045,
                                      ),
                                      blurRadius: 18,
                                      offset: const Offset(0, 7),
                                    ),
                                  ],
                                ),
                                child: Stack(
                                  children: [
                                    Positioned(
                                      left: ResSize.w * 13,
                                      top: ResSize.h * 25,
                                      bottom: ResSize.h * 25,
                                      child: Container(
                                        width: 1.4,
                                        color: _premiumInk.withValues(
                                          alpha: 0.72,
                                        ),
                                      ),
                                    ),
                                    Column(children: routeRows),
                                  ],
                                ),
                              ),
                            ),
                            6.width,
                            Material(
                              color: const Color(0xFFF0F2F3),
                              shape: const CircleBorder(),
                              child: InkWell(
                                onTap: stopControllers.length >= 3
                                    ? null
                                    : () {
                                        final controller =
                                            TextEditingController();
                                        final focusNode = FocusNode();
                                        setModalState(() {
                                          stopControllers.add(controller);
                                          stopFocusNodes.add(focusNode);
                                          sheetDisposables.add(controller);
                                          sheetDisposables.add(focusNode);
                                          activeField = 'stop';
                                          activeStopIndex =
                                              stopControllers.length - 1;
                                          query = '';
                                        });
                                        WidgetsBinding.instance
                                            .addPostFrameCallback((_) {
                                              focusNode.requestFocus();
                                            });
                                      },
                                customBorder: const CircleBorder(),
                                child: SizedBox(
                                  width: ResSize.w * 44,
                                  height: ResSize.h * 44,
                                  child: Icon(
                                    Icons.add_rounded,
                                    color: stopControllers.length >= 3
                                        ? _premiumMuted.withValues(alpha: 0.4)
                                        : _premiumInk,
                                    size: ResSize.h * 27,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        9.height,
                        Row(
                          children: [
                            Icon(
                              Icons.alt_route_rounded,
                              size: ResSize.h * 15,
                              color: _premiumAccent,
                            ),
                            7.width,
                            Expanded(
                              child: TextWidget(
                                text: stopControllers.isEmpty
                                    ? 'Add a stop before your final destination.'
                                    : 'Stops are visited in order before the final destination.',
                                color: _premiumMuted,
                                fontSize: 9,
                                fontWeight: fwNormal,
                              ),
                            ),
                          ],
                        ),
                        13.height,
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextWidget(
                            text: query.trim().isEmpty
                                ? 'Recent addresses'
                                : 'Address results',
                            color: _premiumMuted,
                            fontSize: 10.5,
                            fontWeight: fwSemiBold,
                          ),
                        ),
                        5.height,
                        Expanded(
                          child: ListView(
                            physics: const BouncingScrollPhysics(),
                            children: [
                              if (activeField == 'pickup')
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: Container(
                                    width: ResSize.w * 38,
                                    height: ResSize.h * 38,
                                    decoration: BoxDecoration(
                                      color: _premiumAccentSoft,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.my_location_rounded,
                                      color: _premiumAccent,
                                      size: ResSize.h * 19,
                                    ),
                                  ),
                                  title: TextWidget(
                                    text: 'Current location',
                                    color: _premiumInk,
                                    fontSize: 11.5,
                                    fontWeight: fwSemiBold,
                                  ),
                                  subtitle: TextWidget(
                                    text: _shortAddress(
                                      _pickupAddress,
                                      maxLength: 38,
                                    ),
                                    color: _premiumMuted,
                                    fontSize: 9,
                                    fontWeight: fwNormal,
                                  ),
                                  onTap: () {
                                    pickupController.text =
                                        _pickupAddress ?? 'Current location';
                                    pickupController.selection =
                                        TextSelection.collapsed(
                                          offset: pickupController.text.length,
                                        );
                                    setModalState(() {
                                      query = pickupController.text;
                                      pickupConfirmedOnMap =
                                          _currentLatLng != null;
                                      confirmedPickupLatLng = _currentLatLng;
                                    });
                                  },
                                ),
                              for (final address in filteredRecent)
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: Container(
                                    width: ResSize.w * 38,
                                    height: ResSize.h * 38,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFF3F5F5),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.history_rounded,
                                      color: _premiumInk,
                                      size: ResSize.h * 19,
                                    ),
                                  ),
                                  title: TextWidget(
                                    text: address,
                                    color: _premiumInk,
                                    fontSize: 11.5,
                                    fontWeight: fwMedium,
                                  ),
                                  onTap: () {
                                    final controller = activeController();
                                    controller.text = address;
                                    controller.selection =
                                        TextSelection.collapsed(
                                          offset: address.length,
                                        );
                                    setModalState(() {
                                      query = address;
                                      if (activeField == 'pickup') {
                                        pickupConfirmedOnMap = false;
                                        confirmedPickupLatLng = null;
                                      } else if (activeField == 'destination') {
                                        destinationConfirmedOnMap = false;
                                        confirmedDestinationLatLng = null;
                                      }
                                    });
                                  },
                                ),
                              if (query.trim().isNotEmpty &&
                                  !filteredRecent.any(
                                    (address) =>
                                        address.toLowerCase() ==
                                        query.trim().toLowerCase(),
                                  ))
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: Container(
                                    width: ResSize.w * 38,
                                    height: ResSize.h * 38,
                                    decoration: BoxDecoration(
                                      color: _premiumAccentSoft,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.search_rounded,
                                      color: _premiumAccent,
                                      size: ResSize.h * 19,
                                    ),
                                  ),
                                  title: TextWidget(
                                    text: 'Use “${query.trim()}”',
                                    color: _premiumInk,
                                    fontSize: 11.5,
                                    fontWeight: fwSemiBold,
                                  ),
                                  subtitle: TextWidget(
                                    text: activeField == 'destination'
                                        ? 'Set as final destination'
                                        : activeField == 'pickup'
                                        ? 'Set as pickup'
                                        : 'Set as Stop ${activeStopIndex + 1}',
                                    color: _premiumMuted,
                                    fontSize: 9,
                                    fontWeight: fwNormal,
                                  ),
                                  onTap: () {
                                    final address = query.trim();
                                    if (address.isEmpty) return;
                                    final controller = activeController();
                                    controller.text = address;
                                    controller.selection =
                                        TextSelection.collapsed(
                                          offset: address.length,
                                        );
                                    setModalState(() {
                                      query = address;
                                      if (activeField == 'pickup') {
                                        pickupConfirmedOnMap = false;
                                        confirmedPickupLatLng = null;
                                      } else if (activeField == 'destination') {
                                        destinationConfirmedOnMap = false;
                                        confirmedDestinationLatLng = null;
                                      }
                                    });
                                    FocusScope.of(context).unfocus();
                                  },
                                ),
                            ],
                          ),
                        ),
                        10.height,
                        Material(
                          color: destinationController.text.trim().isEmpty
                              ? _premiumAccent.withValues(alpha: 0.42)
                              : _premiumAccent,
                          borderRadius: BorderRadius.circular(18),
                          child: InkWell(
                            onTap: destinationController.text.trim().isEmpty
                                ? null
                                : () async {
                                    FocusScope.of(context).unfocus();
                                    // Book now always confirms pickup; GPS only prefills.
                                    final result = await _openPickupMapPicker(
                                      pickupController.text.trim(),
                                    );
                                    if (result == null || !mounted) return;
                                    pickupController.text = result.address;
                                    final exactPosition = result.position;

                                    var exactDestinationPosition =
                                        confirmedDestinationLatLng;
                                    if (!destinationConfirmedOnMap) {
                                      final destinationText =
                                          destinationController.text.trim();
                                      final geocodedDestination =
                                          await _locationCtl.geocodePlace(
                                            destinationText,
                                          );
                                      if (geocodedDestination != null) {
                                        destinationController.text =
                                            geocodedDestination.address;
                                        exactDestinationPosition =
                                            geocodedDestination.point;
                                      } else {
                                        if (sheetContext.mounted) {
                                          MoveraToast.show(
                                            sheetContext,
                                            'Choose a valid destination address.',
                                          );
                                        }
                                        return;
                                      }
                                    }
                                    if (!mounted ||
                                        !sheetContext.mounted ||
                                        exactDestinationPosition == null) {
                                      return;
                                    }
                                    Navigator.pop(sheetContext, {
                                      'pickup': pickupController.text.trim(),
                                      'pickupLat': exactPosition.latitude,
                                      'pickupLng': exactPosition.longitude,
                                      'destination': destinationController.text
                                          .trim(),
                                      'destinationLat':
                                          exactDestinationPosition.latitude,
                                      'destinationLng':
                                          exactDestinationPosition.longitude,
                                      'stops': stopControllers
                                          .map(
                                            (controller) =>
                                                controller.text.trim(),
                                          )
                                          .where(
                                            (address) => address.isNotEmpty,
                                          )
                                          .toList(),
                                    });
                                  },
                            borderRadius: BorderRadius.circular(18),
                            child: SizedBox(
                              width: double.infinity,
                              height: ResSize.h * 48,
                              child: Center(
                                child: TextWidget(
                                  text: 'Next',
                                  color: AppColor.white,
                                  fontSize: 12.5,
                                  fontWeight: fwSemiBold,
                                ),
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
            ),
          );
        },
      );
    } finally {
      if (ownsCapture) routeCapture.stop();
    }

    if (draft == null || !mounted) return;
    final rawPickup = draft['pickup'] as String? ?? '';
    final rawDestination = draft['destination'] as String? ?? '';
    final rawStops = (draft['stops'] as List<dynamic>? ?? <dynamic>[])
        .whereType<String>()
        .toList();
    final routePreparationWatch = Stopwatch()..start();
    final normalizedRoute = await Future.wait<String>([
      _normaliseAddress(rawPickup),
      _normaliseAddress(rawDestination),
      ...rawStops.map(_normaliseAddress),
    ]);
    routePreparationWatch.stop();
    RouteTransitionMetrics.routePreparation(
      routePreparationWatch.elapsed,
      stopCount: rawStops.length,
    );
    final pickup = normalizedRoute[0];
    final destination = normalizedRoute[1];
    final stops = normalizedRoute
        .skip(2)
        .where((address) => address.isNotEmpty)
        .toList();
    if (!mounted) return;
    final pickupLat = draft['pickupLat'] as double?;
    final pickupLng = draft['pickupLng'] as double?;
    final exactPickupPosition = pickupLat != null && pickupLng != null
        ? LatLng(pickupLat, pickupLng)
        : (_tripPickupLatLng ?? _currentLatLng);
    final destinationLat = draft['destinationLat'] as double?;
    final destinationLng = draft['destinationLng'] as double?;
    final exactDestinationPosition =
        destinationLat != null && destinationLng != null
        ? LatLng(destinationLat, destinationLng)
        : null;
    setState(() {
      if (pickup.isNotEmpty) _pickupAddress = pickup;
      if (exactPickupPosition != null) {
        _tripPickupLatLng = exactPickupPosition;
      }
      _destinationAddress = destination.isEmpty
          ? _destinationAddress
          : destination;
      _routeStops = stops;
      if (pickup.isNotEmpty) _rememberAddress(pickup);
      if (destination.isNotEmpty) _rememberAddress(destination);
      for (final stop in stops) {
        _rememberAddress(stop);
      }
    });
    await _persistAddressData();
    if (destination.isNotEmpty) {
      final pickupPosition = exactPickupPosition;
      final destinationPosition = exactDestinationPosition;
      if (pickupPosition == null || destinationPosition == null || !mounted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Please choose a valid pickup and destination.',
              ),
            ),
          );
        }
        return;
      }
      // Park the Home map before opening categories. Two Google Maps at once
      // crashes the browser tab on Flutter web.
      await _withParkedHomeMap(() {
        return Navigator.of(context).push(
          RideStageTransition(
            SelectRide(
              pickupAddress: pickup.isNotEmpty
                  ? pickup
                  : (_pickupAddress ?? 'Current location'),
              destinationAddress: destination,
              pickupPosition: pickupPosition,
              destinationPosition: destinationPosition,
              stops: List<String>.from(stops),
              bookingMode: BookingMode.now,
              onScheduled: (context, id) => RideScheduledPage.open(
                context,
                reservationId: id,
                replace: true,
              ),
            ),
            settings: const RouteSettings(name: AppRoutes.selectRide),
          ),
        );
      });
    }
  }

  Future<void> _showAddressPicker({
    required String target,
    String? customType,
  }) async {
    final initialAddress = _existingAddressFor(target);
    final controller = TextEditingController(
      text: initialAddress == 'Current location' ? '' : initialAddress ?? '',
    );
    final focusNode = FocusNode();
    var query = controller.text;
    // Started before the sheet opens; see EarlyInputCapture.
    final capture = EarlyInputCapture()..start();
    capture.attach(controller, focusNode);
    String? selected;
    try {
      selected = await MoveraSheet.show<String>(
        context: context,
        backgroundColor: Colors.transparent,
        barrierColor: Colors.black.withValues(alpha: 0.24),
        builder: (sheetContext) {
          return MoveraSheetDisposables(
            disposables: [controller, focusNode],
            child: PointerInterceptor(
              child: StatefulBuilder(
              builder: (context, setModalState) {
                capture.onChanged = (value) {
                  AppScope.instance.destinationSearch.type(value, (text) {
                    if (!mounted) return;
                    setModalState(() => query = text);
                  });
                };
                final filteredRecent = _recentAddresses
                    .where(
                      (address) =>
                          query.trim().isEmpty ||
                          address.toLowerCase().contains(
                            query.trim().toLowerCase(),
                          ),
                    )
                    .take(6)
                    .toList();
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: Container(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.78,
                    ),
                    padding: EdgeInsets.fromLTRB(
                      ResSize.w * 18,
                      ResSize.h * 11,
                      ResSize.w * 18,
                      ResSize.h * 20,
                    ),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: ResSize.w * 42,
                          height: ResSize.h * 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFFCED4D8),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        16.height,
                        Row(
                          children: [
                            Expanded(
                              child: TextWidget(
                                text: _targetTitle(target, customType),
                                color: _premiumInk,
                                fontSize: 18,
                                fontWeight: fwBold,
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(sheetContext),
                              icon: const Icon(Icons.close_rounded),
                              color: _premiumInk,
                              tooltip: 'Close',
                            ),
                          ],
                        ),
                        10.height,
                        TextField(
                          controller: controller,
                          focusNode: focusNode,
                          autofocus: true,
                          textInputAction: TextInputAction.search,
                          onChanged: (value) {
                            AppScope.instance.destinationSearch.type(value, (
                              text,
                            ) {
                              if (!mounted) return;
                              setModalState(() => query = text);
                            });
                          },
                          onSubmitted: (value) {
                            if (value.trim().isNotEmpty) {
                              Navigator.pop(sheetContext, value.trim());
                            }
                          },
                          style: TextStyle(
                            color: _premiumInk,
                            fontSize: ResSize.setSp(15),
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search or enter an address',
                            hintStyle: TextStyle(
                              color: _premiumMuted.withValues(alpha: 0.72),
                              fontSize: ResSize.setSp(14),
                            ),
                            prefixIcon: Icon(
                              Icons.search_rounded,
                              color: _premiumInk.withValues(alpha: 0.72),
                            ),
                            suffixIcon: query.isEmpty
                                ? null
                                : IconButton(
                                    onPressed: () {
                                      controller.clear();
                                      setModalState(() => query = '');
                                    },
                                    tooltip: 'Clear',
                                    icon: const Icon(Icons.close_rounded),
                                  ),
                            filled: true,
                            fillColor: const Color(0xFFF5F7F7),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: ResSize.w * 15,
                              vertical: ResSize.h * 15,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        12.height,
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              Navigator.pop(
                                sheetContext,
                                _pickupAddress ?? 'Current location',
                              );
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: ResSize.w * 13,
                                vertical: ResSize.h * 11,
                              ),
                              decoration: BoxDecoration(
                                color: _premiumAccentSoft.withValues(
                                  alpha: 0.62,
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.my_location_rounded,
                                    color: _premiumAccent,
                                    size: ResSize.h * 20,
                                  ),
                                  11.width,
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        TextWidget(
                                          text: 'Use current location',
                                          color: _premiumInk,
                                          fontSize: 12.5,
                                          fontWeight: fwSemiBold,
                                        ),
                                        2.height,
                                        TextWidget(
                                          text: _shortAddress(
                                            _pickupAddress,
                                            maxLength: 38,
                                          ),
                                          color: _premiumMuted,
                                          fontSize: 9,
                                          fontWeight: fwNormal,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        if (filteredRecent.isNotEmpty) ...[
                          16.height,
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextWidget(
                              text: 'Recent addresses',
                              color: _premiumMuted,
                              fontSize: 10.5,
                              fontWeight: fwSemiBold,
                            ),
                          ),
                          6.height,
                          Flexible(
                            child: ListView.separated(
                              shrinkWrap: true,
                              physics: const BouncingScrollPhysics(),
                              itemCount: filteredRecent.length,
                              separatorBuilder: (_, __) => const Divider(
                                color: Color(0xFFE7EBEE),
                                height: 1,
                              ),
                              itemBuilder: (context, index) {
                                final address = filteredRecent[index];
                                return ListTile(
                                  dense: true,
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: ResSize.w * 4,
                                  ),
                                  leading: Icon(
                                    Icons.history_rounded,
                                    color: _premiumMuted,
                                    size: ResSize.h * 20,
                                  ),
                                  title: TextWidget(
                                    text: address,
                                    color: _premiumInk,
                                    fontSize: 11,
                                    fontWeight: fwMedium,
                                  ),
                                  onTap: () =>
                                      Navigator.pop(sheetContext, address),
                                );
                              },
                            ),
                          ),
                        ],
                        if (query.trim().isNotEmpty) ...[
                          14.height,
                          Material(
                            color: _premiumAccent,
                            borderRadius: BorderRadius.circular(17),
                            child: InkWell(
                              onTap: () => Navigator.pop(
                                sheetContext,
                                controller.text.trim(),
                              ),
                              borderRadius: BorderRadius.circular(17),
                              child: SizedBox(
                                height: ResSize.h * 46,
                                width: double.infinity,
                                child: Center(
                                  child: TextWidget(
                                    text: 'Use this address',
                                    color: Colors.white,
                                    fontSize: 12.5,
                                    fontWeight: fwSemiBold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
            ),
          );
        },
      );
    } finally {
      capture.stop();
    }
    if (selected == null || selected.trim().isEmpty || !mounted) return;
    await _saveAddressFor(target, selected, customType: customType);
  }

  Future<void> _openAddPlacePicker() async {
    if (_savedPlaces.length >= _maxCustomPlaces) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can save up to 8 custom places.')),
      );
      return;
    }
    const placeTypes = <String>[
      'gym',
      'mall',
      'school',
      'airport',
      'family',
      'restaurant',
      'other',
    ];
    final type = await MoveraSheet.show<String>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.24),
      builder: (sheetContext) {
        return PointerInterceptor(
          child: Container(
            padding: EdgeInsets.fromLTRB(
              ResSize.w * 18,
              ResSize.h * 12,
              ResSize.w * 18,
              ResSize.h * 24,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: ResSize.w * 42,
                  height: ResSize.h * 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCED4D8),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                18.height,
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextWidget(
                    text: 'What place do you want to save?',
                    color: _premiumInk,
                    fontSize: 17,
                    fontWeight: fwBold,
                  ),
                ),
                16.height,
                Wrap(
                  spacing: ResSize.w * 9,
                  runSpacing: ResSize.h * 9,
                  children: placeTypes.map((placeType) {
                    return Material(
                      color: const Color(0xFFF5F7F7),
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        onTap: () => Navigator.pop(sheetContext, placeType),
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: ResSize.w * 13,
                            vertical: ResSize.h * 11,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _placeIcon(placeType),
                                size: ResSize.h * 18,
                                color: _premiumAccent,
                              ),
                              7.width,
                              TextWidget(
                                text: _placeLabel(placeType),
                                color: _premiumInk,
                                fontSize: 11,
                                fontWeight: fwSemiBold,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (type == null || !mounted) return;
    await _showAddressPicker(target: 'custom', customType: type);
  }

  String _placeLabel(String type) {
    switch (type) {
      case 'gym':
        return 'Gym';
      case 'mall':
        return 'Mall';
      case 'school':
        return 'School';
      case 'airport':
        return 'Airport';
      case 'family':
        return 'Family';
      case 'restaurant':
        return 'Restaurant';
      default:
        return 'Other';
    }
  }

  IconData _placeIcon(String type) {
    switch (type) {
      case 'gym':
        return Icons.fitness_center_rounded;
      case 'mall':
        return Icons.local_mall_outlined;
      case 'school':
        return Icons.school_outlined;
      case 'airport':
        return Icons.flight_takeoff_rounded;
      case 'family':
        return Icons.family_restroom_rounded;
      case 'restaurant':
        return Icons.restaurant_rounded;
      default:
        return Icons.place_outlined;
    }
  }

  Future<BitmapDescriptor> _buildLocationPuckIcon(bool expanded) async {
    final visual = await MoveraRiderPuckMarker.createVisual(expanded: expanded);
    if (expanded) {
      _puckExpandedImage?.dispose();
      _puckExpandedImage = visual.image;
    } else {
      _puckCompactImage?.dispose();
      _puckCompactImage = visual.image;
    }
    return visual.icon;
  }

  Future<void> _prepareLocationPuckIcons() async {
    _locationPuckCompact ??= await _buildLocationPuckIcon(false);
    _locationPuckExpanded ??= await _buildLocationPuckIcon(true);
  }

  Future<BitmapDescriptor?> _webRotatedPuck({
    required bool expanded,
    required double heading,
  }) async {
    final src = expanded ? _puckExpandedImage : _puckCompactImage;
    if (src == null) return null;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final cx = src.width * 0.5;
    final cy = src.height * 0.66;
    canvas
      ..translate(cx, cy)
      ..rotate(heading * math.pi / 180)
      ..translate(-cx, -cy)
      ..drawImage(src, Offset.zero, Paint());
    final image = await recorder.endRecording().toImage(src.width, src.height);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (data == null) return null;
    return BitmapDescriptor.fromBytes(data.buffer.asUint8List());
  }

  void _updateLocationVisuals() {
    final target = _currentLatLng;
    final expanded = _locationPulseExpanded;
    final icon = expanded ? _locationPuckExpanded : _locationPuckCompact;
    if (!mounted || target == null || icon == null) return;
    final heading = _locationHeading;
    if (kIsWeb) {
      _paintWebPuck(target: target, expanded: expanded, heading: heading);
      return;
    }
    _locationCtl.paintUserPuck(target: target, icon: icon, heading: heading);
  }

  Future<void> _paintWebPuck({
    required LatLng target,
    required bool expanded,
    required double heading,
  }) async {
    final gen = ++_webPuckPaintGen;
    final rotated = await _webRotatedPuck(expanded: expanded, heading: heading);
    if (!mounted || gen != _webPuckPaintGen) return;
    _locationCtl.paintUserPuck(
      target: target,
      icon:
          rotated ?? (expanded ? _locationPuckExpanded : _locationPuckCompact)!,
      heading: rotated == null ? heading : 0,
    );
  }

  Future<bool> _startHeadingTracking() {
    return _locationCtl.startHeading(
      isMounted: () => mounted,
      onHeading: (heading) {
        _locationHeading = heading;
        _hasCompassHeading = true;
        _updateLocationVisuals();
      },
    );
  }

  void _handleMapCameraMove(CameraPosition camera) {
    _lastMapZoom = camera.zoom;
    _lastMapTarget = camera.target;
    final user = _currentLatLng;
    if (user == null) return;
    final shouldShow = AppScope.instance.camera.followOrFree(
      zoom: camera.zoom,
      cameraTarget: GeoPoint(camera.target.latitude, camera.target.longitude),
      user: GeoPoint(user.latitude, user.longitude),
    );
    if (shouldShow != _showRecenterButton && mounted) {
      setState(() => _showRecenterButton = shouldShow);
    }
  }

  Future<void> _recenterOnUser() async {
    await _startHeadingTracking();
    AppScope.instance.maps.mode = CameraMode.followUser;
    var target = _currentLatLng;
    try {
      final fix = await _locationCtl.latestFix();
      if (fix != null) {
        target = fix;
        _currentLatLng = target;
        _locationHeading = _locationCtl.heading;
        _updateLocationVisuals();
      }
    } catch (_) {}
    if (target == null) return;
    await AppScope.instance.maps.animateCamera(
      GeoPoint(target.latitude, target.longitude),
      zoom: 17,
      bearing: _locationHeading,
    );
    if (mounted) setState(() => _showRecenterButton = false);
  }

  void _loadMarkers() {
    _locationCtl.clearOverlays();
  }

  double get _sheetMinPixels =>
      ResSize.h * _sheetMinHeight;

  double get _sheetMidPixels => ResSize.h * _sheetMaxHeight;

  bool get _isSheetAtMiddle {
    if (!_homeSheetController.hasClient) return false;
    final offset = _homeSheetController.metrics?.offset;
    if (offset == null) return false;
    return (offset - _sheetMidPixels).abs() <= ResSize.h * 1.5;
  }

  void _cancelSheetIdleTimer() {
    _sheetIdleTimer?.cancel();
    _sheetIdleTimer = null;
  }

  void _scheduleSheetIdleClose() {
    final accessibleNavigation =
        MediaQuery.maybeOf(context)?.accessibleNavigation ?? false;
    if (accessibleNavigation ||
        !_isSheetAtMiddle ||
        _sheetIdleTimer?.isActive == true) {
      _cancelSheetIdleTimer();
      return;
    }
    _sheetIdleTimer = Timer(const Duration(seconds: 3), () {
      _sheetIdleTimer = null;
      if (!mounted || !_isSheetAtMiddle) return;
      _animateHomeSheetTo(
        SheetOffset.absolute(_sheetMinPixels),
        duration: MoveraDurations.large,
        curve: MoveraCurves.close,
      );
    });
  }

  void _syncHomeSheetState() {
    if (!mounted || !_homeSheetController.hasClient) return;
    final offset = _homeSheetController.metrics?.offset;
    if (offset == null) return;

    if (_isSheetAtMiddle) {
      _scheduleSheetIdleClose();
    } else {
      _cancelSheetIdleTimer();
    }

    final expanded = offset > _sheetMidPixels + ResSize.h * 8;
    if (expanded != _destinationSheetOpen) {
      setState(() => _destinationSheetOpen = expanded);
    }
    final covering = offset > _sheetMinPixels + 12;
    setWebOverlayOpen(covering);
  }

  Future<void> _animateHomeSheetTo(
    SheetOffset target, {
    Duration duration = MoveraDurations.large,
    Curve curve = MoveraCurves.open,
  }) async {
    if (!_homeSheetController.hasClient) return;
    await _homeSheetController.animateTo(
      target,
      duration: duration,
      curve: curve,
    );
  }

  Future<void> _openDestinationSheet() async {
    if (!_destinationSheetOpen) {
      setState(() => _destinationSheetOpen = true);
    }

    await _animateHomeSheetTo(const SheetOffset(1));
  }

  void _closeDestinationSheet() {
    if (_destinationSheetOpen) {
      setState(() => _destinationSheetOpen = false);
    }
    _animateHomeSheetTo(SheetOffset.absolute(_sheetMinPixels));
  }

  void _toggleHomeSheet() {
    final offset = _homeSheetController.hasClient
        ? (_homeSheetController.metrics?.offset ?? _sheetMinPixels)
        : _sheetMinPixels;
    final midpoint = (_sheetMinPixels + _sheetMidPixels) / 2;
    final SheetOffset target;
    if (offset > _sheetMidPixels + ResSize.h * 8) {
      target = SheetOffset.absolute(_sheetMidPixels);
    } else if (offset > midpoint) {
      target = SheetOffset.absolute(_sheetMinPixels);
    } else {
      target = SheetOffset.absolute(_sheetMidPixels);
    }
    _animateHomeSheetTo(target, duration: MoveraDurations.large);
  }

  Future<void> _openSchedule() async {
    await _withParkedHomeMap(() {
      return Navigator.push(
        context,
        BottomToTopTransition(
          const ScheduleRide(),
          settings: const RouteSettings(name: AppRoutes.schedule),
        ),
      );
    });
  }

  void _openPayment() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const WalletScreen()),
    );
  }

  void _openAccount() {
    unawaited(
      _withParkedHomeMap(() {
        return Navigator.of(
          context,
        ).push(RightToLeftTransition(const AccountHomePage()));
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewportHeight = MediaQuery.of(context).size.height;
    final topInset = MediaQuery.of(context).padding.top + ResSize.h * 8;
    final fullSheetPixels = viewportHeight - topInset;

    return Scaffold(
      backgroundColor: const Color(0xFFEEF1E8),
      extendBody: true,
      drawer: const RiderSideMenu(),
      drawerScrimColor: Colors.black.withValues(alpha: 0.38),
      body: FocusTraversalGroup(
        child: Listener(
          behavior: HitTestBehavior.translucent,
        onPointerDown: (_) => _cancelSheetIdleTimer(),
        onPointerUp: (_) => _scheduleSheetIdleClose(),
        onPointerCancel: (_) => _scheduleSheetIdleClose(),
        child: Stack(
          children: [
            SizedBox(
              height: viewportHeight,
              width: double.infinity,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: RepaintBoundary(
                      child: _HomeMapLayer(
                        location: _locationCtl,
                        parked: _mapParked,
                        padding: EdgeInsets.only(bottom: _sheetMinPixels),
                        initialPosition: _initialPosition,
                        mapStyle: _premiumMapStyle,
                        onCameraMove: _handleMapCameraMove,
                        onMapCreated: (GoogleMapController controller) {
                          _mapController = controller;
                          AppScope.instance.maps.attach(
                            controller,
                            owner: MapOwners.home,
                          );
                          AppScope.instance.mapLifecycle.created();
                          final target = _currentLatLng;
                          if (target != null) {
                            AppScope.instance.maps.animateCamera(
                              GeoPoint(target.latitude, target.longitude),
                              zoom: 15,
                            );
                          }
                        },
                      ),
                    ),
                  ),
                  if (_showRecenterButton && _currentLatLng != null)
                    Positioned(
                      right: ResSize.w * 18,
                      bottom: _sheetMinPixels + ResSize.h * 14,
                      child: PointerInterceptor(
                        child: Tooltip(
                          message: 'Recenter map on your location',
                          child: Semantics(
                            button: true,
                            label: 'Recenter map on your location',
                            child: Material(
                              color: Colors.white,
                              shape: const CircleBorder(),
                              elevation: 8,
                              shadowColor: Colors.black26,
                              child: InkWell(
                                onTap: _recenterOnUser,
                                customBorder: const CircleBorder(),
                                child: const SizedBox(
                                  width: 48,
                                  height: 48,
                                  child: Icon(
                                    Icons.near_me_outlined,
                                    color: _premiumInk,
                                    size: 22,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (_destinationSheetOpen)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 1.4, sigmaY: 1.4),
                          child: Container(
                            color: AppColor.white.withValues(alpha: 0.05),
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    left: screenHorizPadding,
                    top: ResSize.h * 60,
                    child: const HomeReservationChrono(),
                  ),
                  Positioned.fill(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        screenHorizPadding,
                        ResSize.h * 50,
                        screenHorizPadding,
                        0,
                      ),
                      child: Align(
                        alignment: Alignment.topRight,
                        child: Builder(
                          builder: (drawerContext) => PremiumTopActions(
                            onMenuTap: () {
                              Scaffold.of(drawerContext).openDrawer();
                            },
                            onAccountTap: _openAccount,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SheetViewport(
              child: Sheet(
                controller: _homeSheetController,
                initialOffset: SheetOffset.absolute(_sheetMinPixels),
                physics: MoveraSheetMotion.physics,
                snapGrid: SheetSnapGrid(
                  snaps: [
                    SheetOffset.absolute(_sheetMinPixels),
                    SheetOffset.absolute(_sheetMidPixels),
                    const SheetOffset(1),
                  ],
                  minFlingSpeed: 520,
                ),
                scrollConfiguration: SheetScrollConfiguration.disabled,
                child: PointerInterceptor(
                  child: SizedBox(
                    height: fullSheetPixels,
                    width: double.infinity,
                    child: AnimatedBuilder(
                      animation: _homeSheetController,
                      builder: (context, child) {
                        final sheetHeight = _homeSheetController.hasClient
                            ? (_homeSheetController.metrics?.offset ??
                                  _sheetMinPixels)
                            : _sheetMinPixels;
                        final sheetProgress =
                            ((sheetHeight - _sheetMinPixels) /
                                    (_sheetMidPixels - _sheetMinPixels))
                                .clamp(0.0, 1.0);
                        final rawDetailProgress =
                            ((sheetHeight - _sheetMidPixels) /
                                    (fullSheetPixels - _sheetMidPixels))
                                .clamp(0.0, 1.0);
                        final detailProgress = Curves.easeInCubic.transform(
                          rawDetailProgress,
                        );
                        return _premiumCollapsedSheet(
                          sheetProgress,
                          detailProgress,
                          sheetHeight,
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            RiderProfile(
              controller: _profilePanelController,
              onClose: () {
                _profilePanelController.close();
              },
            ),
          ],
          ),
        ),
      ),
    );
  }

  Widget _premiumCollapsedSheet(
    double sheetProgress,
    double detailProgress,
    double sheetHeight,
  ) {
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
                  Semantics(
                    button: true,
                    label: 'Toggle home panel',
                    child: Tooltip(
                      message: 'Toggle home panel',
                      child: InkWell(
                        onTap: _toggleHomeSheet,
                        borderRadius: BorderRadius.circular(14),
                        child: SizedBox(
                          width: 48,
                          height: 32,
                          child: Center(
                            child: Container(
                              width: ResSize.w * 42,
                              height: ResSize.h * 4,
                              decoration: BoxDecoration(
                                color: const Color(0xFFCED4D8),
                                borderRadius: BorderRadius.circular(11),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  12.height,
                  WhereToCard(
                    destinationAddress: _destinationAddress,
                    onDestinationTap: _handleDestinationTap,
                    onOpenSchedule: _openSchedule,
                  ),
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
                              SavedPlacesRow(
                                homeAddress: _homeAddress,
                                workAddress: _workAddress,
                                savedPlaces: _savedPlaces,
                                onUseSavedPlace: _useSavedPlaceAsDestination,
                                onAddPlace: _openAddPlacePicker,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  IgnorePointer(
                    ignoring: detailProgress < 0.92,
                    child: ClipRect(
                      child: Align(
                        alignment: Alignment.topCenter,
                        heightFactor: detailProgress,
                        child: Opacity(
                          opacity: detailProgress,
                          child: Padding(
                            padding: EdgeInsets.only(top: ResSize.h * 24),
                            child: Column(
                              children: [
                                AdvanceBookingCard(
                                  onOpenSchedule: _openSchedule,
                                ),
                                14.height,
                                ComfortRideCarousel(
                                  onDestinationTap: _handleDestinationTap,
                                  onOpenSchedule: _openSchedule,
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
            Positioned(
              left: ResSize.w * (18 + (12 * (1 - sheetProgress))),
              right: ResSize.w * (18 + (12 * (1 - sheetProgress))),
              top: sheetHeight - ResSize.h * (63 + (30 * (1 - sheetProgress))),
              child: Transform.scale(
                scale: 0.84 + (0.16 * sheetProgress),
                alignment: Alignment.bottomCenter,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: ResSize.w * (4 * (1 - sheetProgress)),
                    vertical: ResSize.h * (5 * (1 - sheetProgress)),
                  ),
                  decoration: BoxDecoration(
                    color: AppColor.white,
                    borderRadius: BorderRadius.circular(
                      32 * (1 - sheetProgress),
                    ),
                    border: Border.all(
                      color: _premiumLine.withValues(alpha: 1 - sheetProgress),
                      width: 0.8,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: 0.14 * (1 - sheetProgress),
                        ),
                        blurRadius: 28 * (1 - sheetProgress),
                        offset: Offset(0, 10 * (1 - sheetProgress)),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Opacity(
                        opacity: sheetProgress,
                        child: const Divider(
                          color: Color(0xFFE7EBEE),
                          thickness: 0.8,
                          height: 1,
                        ),
                      ),
                      SizedBox(height: ResSize.h * (9 * sheetProgress)),
                      Row(
                        children: [
                          Expanded(
                            child: PremiumBottomNavItem(
                              iconAsset: AppAssets.navMap,
                              label: 'Map',
                              active: true,
                              floatingFraction: 1 - sheetProgress,
                              onTap: () => _animateHomeSheetTo(
                                SheetOffset.absolute(_sheetMinPixels),
                              ),
                            ),
                          ),
                          Expanded(
                            child: PremiumBottomNavItem(
                              iconAsset: AppAssets.navPayment,
                              label: 'Payment',
                              floatingFraction: 1 - sheetProgress,
                              onTap: _openPayment,
                            ),
                          ),
                          Expanded(
                            child: PremiumBottomNavItem(
                              iconAsset: AppAssets.navSchedule,
                              label: 'Schedule ride',
                              floatingFraction: 1 - sheetProgress,
                              onTap: _openSchedule,
                            ),
                          ),
                          Expanded(
                            child: PremiumBottomNavItem(
                              iconAsset: AppAssets.navAccount,
                              label: 'Account',
                              floatingFraction: 1 - sheetProgress,
                              onTap: _openAccount,
                            ),
                          ),
                        ],
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
  }
}

class _HomeMapLayer extends StatefulWidget {
  const _HomeMapLayer({
    required this.location,
    required this.parked,
    required this.padding,
    required this.initialPosition,
    required this.mapStyle,
    required this.onCameraMove,
    required this.onMapCreated,
  });

  final HomeLocationController location;
  final ValueNotifier<bool> parked;
  final EdgeInsets padding;
  final CameraPosition initialPosition;
  final String mapStyle;
  final void Function(CameraPosition) onCameraMove;
  final void Function(GoogleMapController) onMapCreated;

  @override
  State<_HomeMapLayer> createState() => _HomeMapLayerState();
}

class _HomeMapLayerState extends State<_HomeMapLayer> {
  Widget? _cached;
  Set<Marker>? _markers;
  Set<Circle>? _circles;
  Set<Polygon>? _polygons;
  EdgeInsets? _padding;
  bool? _parked;

  @override
  void initState() {
    super.initState();
    widget.location.addListener(_onChange);
    widget.parked.addListener(_onChange);
  }

  @override
  void didUpdateWidget(_HomeMapLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.location != widget.location) {
      oldWidget.location.removeListener(_onChange);
      widget.location.addListener(_onChange);
    }
    if (oldWidget.parked != widget.parked) {
      oldWidget.parked.removeListener(_onChange);
      widget.parked.addListener(_onChange);
    }
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.location.removeListener(_onChange);
    widget.parked.removeListener(_onChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.parked.value) {
      const parked = ColoredBox(color: Color(0xFFEEF1E8));
      _cached = parked;
      _parked = true;
      return parked;
    }
    if (_cached != null &&
        _parked == false &&
        identical(_markers, widget.location.markers) &&
        identical(_circles, widget.location.locationCircles) &&
        identical(_polygons, widget.location.locationDirection) &&
        _padding == widget.padding) {
      return _cached!;
    }
    _parked = false;
    _markers = widget.location.markers;
    _circles = widget.location.locationCircles;
    _polygons = widget.location.locationDirection;
    _padding = widget.padding;
    _cached = CustomGoogleMap(
      key: const ValueKey('home-map'),
      initialPosition: widget.initialPosition,
      markers: widget.location.markers,
      circles: widget.location.locationCircles,
      polygons: widget.location.locationDirection,
      padding: widget.padding,
      myLocationEnabled: false,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      compassEnabled: false,
      trafficEnabled: false,
      buildingsEnabled: true,
      indoorViewEnabled: false,
      mapType: MapType.normal,
      customMapStyle: widget.mapStyle,
      onCameraMove: widget.onCameraMove,
      onMapCreated: widget.onMapCreated,
      onTap: (LatLng position) {},
    );
    return _cached!;
  }
}
