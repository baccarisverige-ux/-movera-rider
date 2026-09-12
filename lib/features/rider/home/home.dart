// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'dart:ui' show ImageFilter;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:movera_rider/app/di.dart';
import 'package:movera_rider/core/constants/appassets.dart';
import 'package:movera_rider/core/constants/appcolors.dart';
import 'package:movera_rider/core/constants/appfontweight.dart';
import 'package:movera_rider/core/location/location_point.dart';
import 'package:movera_rider/core/maps/camera_mode.dart';
import 'package:movera_rider/core/maps/geo_point.dart';
import 'package:movera_rider/core/utils/stale_guard.dart';
import 'package:movera_rider/features/ride_booking/data/ride_snapshot_store.dart';
import 'package:movera_rider/features/ride_booking/domain/ride_status.dart';
import 'package:movera_rider/features/rider/Finding%20Drivers/finding_drivers.dart';
import 'package:movera_rider/features/rider/my%20wallet/wallet.dart';
import 'package:movera_rider/features/rider/profile/profile.dart';
import 'package:movera_rider/features/rider/ride%20history/ride_history.dart';
import 'package:movera_rider/features/rider/select%20ride/select_ride.dart';
import 'package:movera_rider/features/rider/saved%20places/add%20place/add_place.dart';
import 'package:movera_rider/features/rider/schedule%20ride/schedule_ride.dart';
import 'package:movera_rider/features/rider/side%20menu/side_menu.dart';
import 'package:movera_rider/features/rider/support/support.dart';
import 'package:movera_rider/shared/presentation/notification/notifiction.dart';
import 'package:movera_rider/shared/services/location_address.dart'
    as address_service;
import 'package:movera_rider/shared/services/device_heading.dart'
    as heading_service;
import 'package:movera_rider/shared/widgets/custom_google_map.dart';
import 'package:movera_rider/shared/widgets/custom_text_widget.dart';
import 'package:movera_rider/shared/widgets/navigation_transition.dart';
import 'package:movera_rider/shared/widgets/responsive_size.dart';
import 'package:movera_rider/shared/widgets/sizedbox_extention.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:smooth_sheets/smooth_sheets.dart';

class _SavedPlaceData {
  const _SavedPlaceData({required this.type, required this.address});

  final String type;
  final String address;

  Map<String, String> toJson() => {'type': type, 'address': address};

  factory _SavedPlaceData.fromJson(Map<String, dynamic> json) {
    return _SavedPlaceData(
      type: json['type'] as String? ?? 'other',
      address: json['address'] as String? ?? '',
    );
  }
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final SheetController _homeSheetController = SheetController();
  final PanelController _profilePanelController = PanelController();
  Timer? _sheetIdleTimer;
  Timer? _locationPulseTimer;
  Timer? _headingTimer;
  StreamSubscription<Position>? _positionSubscription;
  final StaleGuard _geoGuard = StaleGuard();
  bool _locationPulseExpanded = false;
  double _locationHeading = 0;
  bool _hasCompassHeading = false;
  double _lastMapZoom = 13.0;
  LatLng _lastMapTarget = const LatLng(59.3293, 18.0686);
  bool _showRecenterButton = true;
  bool _promotionVisible = _promotionEnabled;
  BitmapDescriptor? _locationPuckCompact;
  BitmapDescriptor? _locationPuckExpanded;

  static const double _sheetMinHeight = 184;
  static const double _sheetPromoMinHeight = 244;
  static const double _sheetMaxHeight = 294;

  // Campaign values are kept together so the admin service can replace them
  // without changing the rider interface.
  static const bool _promotionEnabled = true;
  static const String _promotionId = 'next_ride_40_sep_2026';
  static const String _promotionTitle = '40% off your next ride';
  bool _destinationSheetOpen = false;
  bool _findingLocation = true;
  String? _pickupAddress;
  String? _destinationAddress;
  String? _homeAddress;
  String? _workAddress;
  List<String> _routeStops = [];
  // Live device GPS. This may change continuously.
  LatLng? _currentLatLng;
  // Pickup locked for the trip after the rider confirms it.
  LatLng? _tripPickupLatLng;
  List<String> _recentAddresses = [];
  List<_SavedPlaceData> _savedPlaces = [];

  static const int _maxRecentAddresses = 8;
  static const int _maxCustomPlaces = 8;

  // ignore: unused_field
  GoogleMapController? _mapController;
  bool _homeMapParked = false;
  // ignore: prefer_final_fields
  Set<Marker> _markers = {};
  Set<Circle> _locationCircles = {};
  Set<Polygon> _locationDirection = {};

  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(59.3293, 18.0686),
    zoom: 13.0,
  );

  static const Color _premiumInk = Color(0xFF1D252C);
  static const Color _premiumMuted = Color(0xFF778189);
  static const Color _premiumLine = Color(0xFFE7EBEE);
  static const Color _premiumField = Color(0xFFF6F5F1);
  static const Color _premiumAccent = Color(0xFF2D5878);
  static const Color _premiumAccentSoft = Color(0xFFEAF2F8);
  static const Color _premiumSurface = Color(0xFFF7F8F6);

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
    _homeSheetController.addListener(_syncHomeSheetState);
    _loadMarkers();
    _restoreAddressData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _restoreActiveRide();
    });
  }

  @override
  void dispose() {
    _sheetIdleTimer?.cancel();
    _locationPulseTimer?.cancel();
    _headingTimer?.cancel();
    _positionSubscription?.cancel();
    _geoGuard.dispose();
    AppScope.instance.mapLifecycle.dispose();
    AppScope.instance.maps.detach();
    _homeSheetController
      ..removeListener(_syncHomeSheetState)
      ..dispose();
    super.dispose();
  }

  void _dismissPromotion() {
    if (!mounted) return;
    // Dismiss only for this running session. Refreshing or reopening the app
    // creates a fresh Home state and shows the active campaign again.
    setState(() => _promotionVisible = false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _animateHomeSheetTo(
          SheetOffset.absolute(_sheetMinPixels),
          duration: const Duration(milliseconds: 280),
        );
      }
    });
  }

  Future<void> _restoreAddressData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPlaces = <_SavedPlaceData>[];
    final rawSavedPlaces = prefs.getString('movera_saved_places');
    if (rawSavedPlaces != null) {
      try {
        final decoded = jsonDecode(rawSavedPlaces) as List<dynamic>;
        for (final item in decoded) {
          if (item is Map) {
            final place = _SavedPlaceData.fromJson(
              Map<String, dynamic>.from(item),
            );
            if (place.address.trim().isNotEmpty) savedPlaces.add(place);
          }
        }
      } catch (_) {
        // Ignore damaged local data.
      }
    }
    if (mounted) {
      setState(() {
        _homeAddress = prefs.getString('movera_home_address');
        _workAddress = prefs.getString('movera_work_address');
        _recentAddresses =
            prefs.getStringList('movera_recent_addresses') ?? <String>[];
        _savedPlaces = savedPlaces.take(_maxCustomPlaces).toList();
      });
    }
    await _detectCurrentAddress();
  }

  Future<void> _persistAddressData() async {
    final prefs = await SharedPreferences.getInstance();
    if (_homeAddress == null) {
      await prefs.remove('movera_home_address');
    } else {
      await prefs.setString('movera_home_address', _homeAddress!);
    }
    if (_workAddress == null) {
      await prefs.remove('movera_work_address');
    } else {
      await prefs.setString('movera_work_address', _workAddress!);
    }
    await prefs.setStringList('movera_recent_addresses', _recentAddresses);
    await prefs.setString(
      'movera_saved_places',
      jsonEncode(_savedPlaces.map((place) => place.toJson()).toList()),
    );
  }

  Future<void> _restoreActiveRide() async {
    final snapshot = await RideSnapshotStore.read();
    if (snapshot == null || !mounted) return;
    AppScope.instance.ride.restoreFromBackend(
      snapshot.status,
      id: snapshot.rideId,
    );
    if (snapshot.status != RideStatus.findingDriver &&
        snapshot.status != RideStatus.driverAssigned &&
        snapshot.status != RideStatus.driverArriving &&
        snapshot.status != RideStatus.bookingRequested) {
      return;
    }
    await Navigator.push(
      context,
      BottomToTopTransition(
        FindingDrivers(
          pickupAddress: snapshot.pickupAddress,
          destinationAddress: snapshot.destinationAddress,
          pickupPosition: LatLng(snapshot.pickupLat, snapshot.pickupLng),
          destinationPosition: LatLng(
            snapshot.destinationLat,
            snapshot.destinationLng,
          ),
          rideType: snapshot.rideType,
          price: snapshot.price,
          paymentMethod: snapshot.paymentMethod,
        ),
      ),
    );
  }

  Future<void> _detectCurrentAddress() async {
    if (mounted) setState(() => _findingLocation = true);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _findingLocation = false;
            _pickupAddress ??= 'Current location';
          });
        }
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      final generation = _geoGuard.next();
      final detectedAddress = await address_service.reverseGeocodeAddress(
        position.latitude,
        position.longitude,
      );
      if (!_geoGuard.isCurrent(generation)) return;
      final address = detectedAddress?.trim().isNotEmpty == true
          ? detectedAddress!.trim()
          : 'Current location';
      final target = LatLng(position.latitude, position.longitude);
      if (!mounted) return;
      setState(() {
        _pickupAddress = address;
        _currentLatLng = target;
        _findingLocation = false;
        _markers = {};
        _locationHeading = position.heading.isFinite && position.heading >= 0
            ? position.heading
            : 0;
      });
      await _prepareLocationPuckIcons();
      _startLocationTracking();
      _startHeadingTracking();
      _startLocationPulse();
      await _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: target, zoom: 15),
        ),
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

  String? _existingAddressFor(String target) {
    switch (target) {
      case 'pickup':
        return _pickupAddress;
      case 'home':
        return _homeAddress;
      case 'work':
        return _workAddress;
      case 'destination':
        return _destinationAddress;
      default:
        return null;
    }
  }

  Future<String> _normaliseAddress(String input) async {
    final clean = input.trim();
    if (clean.isEmpty || clean == 'Current location') return clean;
    final generation = _geoGuard.next();
    final result = await address_service.geocodeAddress(clean);
    if (!_geoGuard.isCurrent(generation)) return clean;
    return result?.address.trim().isNotEmpty == true
        ? result!.address.trim()
        : clean;
  }

  Future<void> _moveMapToAddress(String address) async {
    final result = await address_service.geocodeAddress(address);
    if (result == null) return;
    final target = LatLng(result.latitude, result.longitude);
    await _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(CameraPosition(target: target, zoom: 15)),
    );
  }

  void _rememberAddress(String address) {
    final clean = address.trim();
    if (clean.isEmpty || clean == 'Current location') return;
    _recentAddresses.removeWhere(
      (saved) => saved.toLowerCase() == clean.toLowerCase(),
    );
    _recentAddresses.insert(0, clean);
    if (_recentAddresses.length > _maxRecentAddresses) {
      _recentAddresses = _recentAddresses.take(_maxRecentAddresses).toList();
    }
  }

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
        final geocodedPickup = await address_service.geocodeAddress(resolved);
        if (geocodedPickup != null) {
          resolvedPickupPosition = LatLng(
            geocodedPickup.latitude,
            geocodedPickup.longitude,
          );
        }
      }
    }
    if (!mounted) return;

    setState(() {
      switch (target) {
        case 'pickup':
          _pickupAddress = resolved;
          _tripPickupLatLng = resolvedPickupPosition;
          break;
        case 'destination':
          _destinationAddress = resolved;
          break;
        case 'home':
          _homeAddress = resolved;
          break;
        case 'work':
          _workAddress = resolved;
          break;
        case 'custom':
          final type = customType ?? 'other';
          final existingIndex = _savedPlaces.indexWhere(
            (place) => place.type == type,
          );
          final place = _SavedPlaceData(type: type, address: resolved);
          if (existingIndex >= 0) {
            _savedPlaces[existingIndex] = place;
          } else if (_savedPlaces.length < _maxCustomPlaces) {
            _savedPlaces.add(place);
          }
          break;
      }
      _rememberAddress(resolved);
    });
    await _persistAddressData();
    if (target == 'pickup' || target == 'destination') {
      await _moveMapToAddress(resolved);
    }
  }

  Future<void> _handleDestinationTap() async {
    if (!_destinationSheetOpen) {
      _openDestinationSheet();
      await Future<void>.delayed(const Duration(milliseconds: 360));
      if (!mounted) return;
    }
    await _showRouteAddressPicker(initialField: 'destination');
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
      var pickupPosition = _tripPickupLatLng ?? _currentLatLng;
      if (pickupPosition == null) {
        final pickupResult = await _openPickupMapPicker(
          _pickupAddress ?? 'Current location',
        );
        if (pickupResult == null || !mounted) return null;
        pickupPosition = pickupResult.position;
        setState(() {
          _pickupAddress = pickupResult.address;
          _tripPickupLatLng = pickupResult.position;
        });
      }
      if (!mounted) return null;
      final confirmedPickupPosition = pickupPosition;
      var resolvedDestination = destination;
      LatLng? destinationPosition;
      final destinationResult = await address_service.geocodeAddress(destination);
      if (destinationResult != null) {
        resolvedDestination = destinationResult.address.trim().isNotEmpty
            ? destinationResult.address.trim()
            : destination;
        destinationPosition = LatLng(
          destinationResult.latitude,
          destinationResult.longitude,
        );
      } else {
        final result = await _openPickupMapPicker(
          destination,
          isDestination: true,
        );
        if (result == null || !mounted) return null;
        resolvedDestination = result.address.trim().isNotEmpty
            ? result.address.trim()
            : destination;
        destinationPosition = result.position;
      }
      final confirmedDestinationPosition = destinationPosition;
      if (confirmedDestinationPosition == null || !mounted) return null;
      return Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SelectRide(
            pickupAddress: _pickupAddress ?? 'Current location',
            destinationAddress: resolvedDestination,
            pickupPosition: confirmedPickupPosition,
            destinationPosition: confirmedDestinationPosition,
            stops: List<String>.from(_routeStops),
          ),
        ),
      );
    });
  }

  Future<T?> _withParkedHomeMap<T>(Future<T?> Function() action) async {
    final parkedNow = !_homeMapParked;
    if (parkedNow) {
      setState(() => _homeMapParked = true);
      AppScope.instance.mapLifecycle.park();
      AppScope.instance.maps.detach();
      _mapController = null;
      await Future<void>.delayed(const Duration(milliseconds: 80));
      if (!mounted) return null;
    }
    try {
      return await action();
    } finally {
      if (parkedNow && mounted) {
        AppScope.instance.mapLifecycle.resume();
        setState(() => _homeMapParked = false);
      }
    }
  }

  Future<_PickupMapResult?> _openPickupMapPicker(
    String address, {
    bool isDestination = false,
  }) async {
    LatLng initialPosition =
        _tripPickupLatLng ?? _currentLatLng ?? _initialPosition.target;
    final cleanAddress = address.trim();
    if (cleanAddress.isNotEmpty &&
        cleanAddress.toLowerCase() != 'current location') {
      final geocoded = await address_service.geocodeAddress(cleanAddress);
      if (geocoded != null)
        initialPosition = LatLng(geocoded.latitude, geocoded.longitude);
    }
    if (!mounted) return null;
    return _withParkedHomeMap(() {
      return Navigator.of(context).push<_PickupMapResult>(
        MaterialPageRoute(
          builder: (_) => _PickupMapPickerPage(
            initialPosition: initialPosition,
            isDestination: isDestination,
            initialAddress: cleanAddress.isEmpty
                ? (_pickupAddress ?? 'Current location')
                : cleanAddress,
          ),
        ),
      );
    });
  }

  Future<void> _showRouteAddressPicker({required String initialField}) async {
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
    var pickupConfirmedOnMap = false;
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

    final draft = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.26),
      builder: (sheetContext) {
        return PointerInterceptor(
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
                    Container(
                      width: ResSize.w * 27,
                      alignment: Alignment.center,
                      child: Container(
                        width: ResSize.w * 10,
                        height: ResSize.h * 10,
                        decoration: BoxDecoration(
                          color: field == 'destination'
                              ? _premiumAccent
                              : AppColor.white,
                          shape: field == 'destination'
                              ? BoxShape.rectangle
                              : BoxShape.circle,
                          borderRadius: field == 'destination'
                              ? BorderRadius.circular(2)
                              : null,
                          border: Border.all(color: _premiumInk, width: 2),
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
                              query = value;
                              if (field == 'pickup') {
                                pickupConfirmedOnMap = false;
                                confirmedPickupLatLng = null;
                              } else if (field == 'destination') {
                                destinationConfirmedOnMap = false;
                                confirmedDestinationLatLng = null;
                              }
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
                            color: _premiumMuted.withOpacity(0.68),
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
                    if (badgeColor != null)
                      Semantics(
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
                          child: Padding(
                            padding: EdgeInsets.only(left: ResSize.w * 3),
                            child: _PremiumRouteLocationBadge(
                              color: badgeColor,
                              size: ResSize.h * 35.2,
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
                const Divider(color: Color(0xFFE4E8EA), height: 1, indent: 38),
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
                  onMapTap: () async {
                    FocusScope.of(context).unfocus();
                    final result = await _openPickupMapPicker(
                      destinationController.text.trim(),
                      isDestination: true,
                    );
                    if (result == null || !mounted) return;
                    destinationController.text = result.address;
                    destinationController.selection = TextSelection.collapsed(
                      offset: destinationController.text.length,
                    );
                    setModalState(() {
                      destinationConfirmedOnMap = true;
                      confirmedDestinationLatLng = result.position;
                      query = destinationController.text;
                    });
                  },
                ),
              );

              return Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.92,
                  padding: EdgeInsets.fromLTRB(
                    ResSize.w * 18,
                    ResSize.h * 10,
                    ResSize.w * 18,
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
                                    color: Colors.black.withOpacity(0.045),
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
                                      color: _premiumInk.withOpacity(0.72),
                                    ),
                                  ),
                                  Column(children: routeRows),
                                ],
                              ),
                            ),
                          ),
                          10.width,
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
                                width: ResSize.w * 48,
                                height: ResSize.h * 48,
                                child: Icon(
                                  Icons.add_rounded,
                                  color: stopControllers.length >= 3
                                      ? _premiumMuted.withOpacity(0.4)
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
                                  FocusScope.of(context).unfocus();
                                },
                              ),
                          ],
                        ),
                      ),
                      10.height,
                      Material(
                        color: destinationController.text.trim().isEmpty
                            ? _premiumAccent.withOpacity(0.42)
                            : _premiumAccent,
                        borderRadius: BorderRadius.circular(18),
                        child: InkWell(
                          onTap: destinationController.text.trim().isEmpty
                              ? null
                              : () async {
                                  FocusScope.of(context).unfocus();
                                  var exactPosition = confirmedPickupLatLng;
                                  if (!pickupConfirmedOnMap) {
                                    final result = await _openPickupMapPicker(
                                      pickupController.text.trim(),
                                    );
                                    if (result == null || !mounted) return;
                                    pickupController.text = result.address;
                                    exactPosition = result.position;
                                  }

                                  var exactDestinationPosition =
                                      confirmedDestinationLatLng;
                                  if (!destinationConfirmedOnMap) {
                                    final destinationText =
                                        destinationController.text.trim();
                                    final geocodedDestination =
                                        await address_service.geocodeAddress(
                                          destinationText,
                                        );
                                    if (geocodedDestination != null) {
                                      destinationController.text =
                                          geocodedDestination.address;
                                      exactDestinationPosition = LatLng(
                                        geocodedDestination.latitude,
                                        geocodedDestination.longitude,
                                      );
                                    } else {
                                      final result = await _openPickupMapPicker(
                                        destinationText,
                                        isDestination: true,
                                      );
                                      if (result == null || !mounted) return;
                                      destinationController.text =
                                          result.address;
                                      exactDestinationPosition =
                                          result.position;
                                    }
                                  }
                                  if (!mounted ||
                                      exactPosition == null ||
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
                                        .where((address) => address.isNotEmpty)
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
        );
      },
    );

    pickupFocus.dispose();
    destinationFocus.dispose();
    for (final focusNode in stopFocusNodes) {
      focusNode.dispose();
    }
    pickupController.dispose();
    destinationController.dispose();
    for (final controller in stopControllers) {
      controller.dispose();
    }

    if (draft == null || !mounted) return;
    final pickup = await _normaliseAddress(draft['pickup'] as String? ?? '');
    final destination = await _normaliseAddress(
      draft['destination'] as String? ?? '',
    );
    final rawStops = (draft['stops'] as List<dynamic>? ?? <dynamic>[])
        .whereType<String>()
        .toList();
    final stops = <String>[];
    for (final stop in rawStops) {
      final resolved = await _normaliseAddress(stop);
      if (resolved.isNotEmpty) stops.add(resolved);
    }
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
                'Please confirm pickup and destination on the map.',
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
          MaterialPageRoute(
            builder: (_) => SelectRide(
              pickupAddress: pickup.isNotEmpty
                  ? pickup
                  : (_pickupAddress ?? 'Current location'),
              destinationAddress: destination,
              pickupPosition: pickupPosition,
              destinationPosition: destinationPosition,
              stops: List<String>.from(stops),
            ),
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
    var query = controller.text;
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.24),
      builder: (sheetContext) {
        return PointerInterceptor(
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
                          ),
                        ],
                      ),
                      10.height,
                      TextField(
                        controller: controller,
                        autofocus: true,
                        textInputAction: TextInputAction.search,
                        onChanged: (value) {
                          setModalState(() => query = value);
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
                            color: _premiumMuted.withOpacity(0.72),
                            fontSize: ResSize.setSp(14),
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: _premiumInk.withOpacity(0.72),
                          ),
                          suffixIcon: query.isEmpty
                              ? null
                              : IconButton(
                                  onPressed: () {
                                    controller.clear();
                                    setModalState(() => query = '');
                                  },
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
                              color: _premiumAccentSoft.withOpacity(0.62),
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
        );
      },
    );
    controller.dispose();
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
    final type = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.24),
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
    const width = 65.9;
    const height = 75.3;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..scale(0.588, 0.588);
    const center = Offset(56, 84);
    // Narrow at the user, with a curved arc at the direction edge.
    final beam = Path()
      ..moveTo(56, 80)
      ..lineTo(23, 18)
      ..quadraticBezierTo(56, 1, 89, 18)
      ..close();
    final beamPaint = Paint()
      ..shader = ui.Gradient.linear(const Offset(56, 4), center, [
        const Color(0x08747B80),
        const Color(0x35747B80),
      ]);
    canvas.drawPath(beam, beamPaint);
    canvas.drawCircle(
      center,
      expanded ? 31 : 25,
      Paint()..color = const Color(0x18747B80),
    );
    canvas.drawCircle(center, 20, Paint()..color = Colors.white);
    canvas.drawCircle(center, 15, Paint()..color = const Color(0xFF747B80));
    final image = await recorder.endRecording().toImage(
      width.toInt(),
      height.toInt(),
    );
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
  }

  Future<void> _prepareLocationPuckIcons() async {
    _locationPuckCompact ??= await _buildLocationPuckIcon(false);
    _locationPuckExpanded ??= await _buildLocationPuckIcon(true);
  }

  void _updateLocationVisuals() {
    final target = _currentLatLng;
    final icon = _locationPulseExpanded
        ? _locationPuckExpanded
        : _locationPuckCompact;
    if (!mounted || target == null || icon == null) return;
    setState(() {
      _locationCircles = {};
      _locationDirection = {};
      _markers = {
        Marker(
          markerId: const MarkerId('live_user_location'),
          position: target,
          icon: icon,
          anchor: const Offset(0.5, 0.66),
          rotation: _locationHeading,
          flat: true,
          zIndex: 20,
        ),
      };
    });
  }

  void _startLocationPulse() {
    _locationPulseTimer?.cancel();
    _locationPulseExpanded = false;
    _updateLocationVisuals();
    _locationPulseTimer = Timer.periodic(const Duration(milliseconds: 850), (
      _,
    ) {
      _locationPulseExpanded = !_locationPulseExpanded;
      _updateLocationVisuals();
    });
  }

  void _startLocationTracking() {
    _positionSubscription?.cancel();
    const settings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 1,
    );
    _positionSubscription =
        Geolocator.getPositionStream(locationSettings: settings).listen((
          position,
        ) {
          if (!mounted) return;
          final motion = AppScope.instance.motion.ingest(
            LocationPoint(
              point: GeoPoint(position.latitude, position.longitude),
              timestamp: position.timestamp,
              accuracyMeters: position.accuracy,
              speedMps: position.speed,
              heading: position.heading,
            ),
          );
          _currentLatLng = motion == null
              ? LatLng(position.latitude, position.longitude)
              : LatLng(motion.position.latitude, motion.position.longitude);
          // GPS course is only a fallback. It must never overwrite the live
          // compass while the user is stationary or moving slowly.
          if (!_hasCompassHeading &&
              position.heading.isFinite &&
              position.heading >= 0) {
            _locationHeading = position.heading;
          }
          _updateLocationVisuals();
        });
  }

  void _startHeadingTracking() {
    heading_service.startHeadingTracking();
    _headingTimer?.cancel();
    _headingTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      final heading = heading_service.currentHeading();
      if (heading == null || !heading.isFinite || !mounted) return;
      var delta = (heading - _locationHeading + 540) % 360 - 180;
      if (delta.abs() < 0.5) return;
      _hasCompassHeading = true;
      _locationHeading = (_locationHeading + delta * 0.32 + 360) % 360;
      _updateLocationVisuals();
    });
  }

  void _handleMapCameraMove(CameraPosition camera) {
    _lastMapZoom = camera.zoom;
    _lastMapTarget = camera.target;
    final user = _currentLatLng;
    if (user == null) return;
    final distance = Geolocator.distanceBetween(
      camera.target.latitude,
      camera.target.longitude,
      user.latitude,
      user.longitude,
    );
    final shouldShow = camera.zoom < 15.5 || distance > 35;
    if (shouldShow != _showRecenterButton && mounted) {
      AppScope.instance.maps.mode = shouldShow
          ? CameraMode.free
          : CameraMode.followUser;
      setState(() => _showRecenterButton = shouldShow);
    }
  }

  Future<void> _recenterOnUser() async {
    _startHeadingTracking();
    AppScope.instance.maps.mode = CameraMode.followUser;
    var target = _currentLatLng;
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          timeLimit: Duration(seconds: 8),
        ),
      );
      target = LatLng(position.latitude, position.longitude);
      _currentLatLng = target;
      if (!_hasCompassHeading &&
          position.heading.isFinite &&
          position.heading >= 0) {
        _locationHeading = position.heading;
      }
      _updateLocationVisuals();
    } catch (_) {}
    if (target == null) return;
    final controller = _mapController;
    if (controller == null) return;

    // Let the map platform animate position and zoom together. This avoids
    // visible stepping on mobile browsers.
    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: target, zoom: 17, bearing: _locationHeading),
      ),
    );
    if (mounted) setState(() => _showRecenterButton = false);
  }

  void _loadMarkers() {
    _markers = {};
  }

  double _fullSheetHeight() {
    final viewportHeight = MediaQuery.of(context).size.height;
    final topInset = MediaQuery.of(context).padding.top + 8;
    return ((viewportHeight - topInset) / ResSize.h).clamp(520.0, 1000.0);
  }

  double get _sheetMinPixels =>
      ResSize.h * (_promotionVisible ? _sheetPromoMinHeight : _sheetMinHeight);

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
    if (!_isSheetAtMiddle || _sheetIdleTimer?.isActive == true) return;
    _sheetIdleTimer = Timer(const Duration(seconds: 3), () {
      _sheetIdleTimer = null;
      if (!mounted || !_isSheetAtMiddle) return;
      _animateHomeSheetTo(
        SheetOffset.absolute(_sheetMinPixels),
        duration: const Duration(milliseconds: 680),
        curve: const Cubic(0.45, 0.0, 0.20, 1.0),
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
  }

  Future<void> _animateHomeSheetTo(
    SheetOffset target, {
    Duration duration = const Duration(milliseconds: 440),
    Curve curve = const Cubic(0.16, 1.0, 0.30, 1.0),
  }) async {
    if (!_homeSheetController.hasClient) return;
    await _homeSheetController.animateTo(
      target,
      duration: duration,
      curve: curve,
    );
  }

  void _openDestinationSheet() {
    if (!_destinationSheetOpen) {
      setState(() => _destinationSheetOpen = true);
    }
    _animateHomeSheetTo(const SheetOffset(1));
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
    _animateHomeSheetTo(target, duration: const Duration(milliseconds: 390));
  }

  void _openSchedule() {
    Navigator.push(context, BottomToTopTransition(const ScheduleRide()));
  }

  void _openRideHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RideHistory()),
    );
  }

  void _openPayment() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const WalletScreen()),
    );
  }

  void _openAddPlace() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddPlace()),
    );
  }

  void _openAccount() {
    _animateHomeSheetTo(
      SheetOffset.absolute(_sheetMinPixels),
      duration: const Duration(milliseconds: 320),
    );
    _profilePanelController.open();
  }

  @override
  Widget build(BuildContext context) {
    final viewportHeight = MediaQuery.of(context).size.height;
    final topInset = MediaQuery.of(context).padding.top + ResSize.h * 8;
    final fullSheetPixels = viewportHeight - topInset;

    return Scaffold(
      drawer: RiderSideMenu(),
      drawerScrimColor: Colors.black.withOpacity(0.38),
      body: Listener(
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
                    child: _homeMapParked
                        ? const ColoredBox(color: Color(0xFFEEF1E8))
                        : CustomGoogleMap(
                            initialPosition: _initialPosition,
                            markers: _markers,
                            circles: _locationCircles,
                            polygons: _locationDirection,
                            myLocationEnabled: false,
                            myLocationButtonEnabled: false,
                            zoomControlsEnabled: false,
                            mapToolbarEnabled: false,
                            compassEnabled: false,
                            trafficEnabled: false,
                            buildingsEnabled: true,
                            indoorViewEnabled: false,
                            mapType: MapType.normal,
                            customMapStyle: _premiumMapStyle,
                            onCameraMove: _handleMapCameraMove,
                            onMapCreated: (GoogleMapController controller) {
                              _mapController = controller;
                              AppScope.instance.maps.attach(controller);
                              AppScope.instance.mapLifecycle.created();
                              final target = _currentLatLng;
                              if (target != null) {
                                controller.animateCamera(
                                  CameraUpdate.newCameraPosition(
                                    CameraPosition(target: target, zoom: 15),
                                  ),
                                );
                              }
                            },
                            onTap: (LatLng position) {},
                          ),
                  ),
                  if (_showRecenterButton && _currentLatLng != null)
                    Positioned(
                      right: ResSize.w * 18,
                      bottom: _sheetMinPixels + ResSize.h * 14,
                      child: PointerInterceptor(
                        child: Material(
                          color: Colors.white,
                          shape: const CircleBorder(),
                          elevation: 8,
                          shadowColor: Colors.black26,
                          child: InkWell(
                            onTap: _recenterOnUser,
                            customBorder: const CircleBorder(),
                            child: SizedBox(
                              width: ResSize.w * 45,
                              height: ResSize.h * 45,
                              child: Icon(
                                Icons.near_me_outlined,
                                color: _premiumInk,
                                size: ResSize.h * 22,
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
                            color: AppColor.white.withOpacity(0.05),
                          ),
                        ),
                      ),
                    ),
                  Positioned.fill(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        screenHorizPadding,
                        ResSize.h * 60,
                        screenHorizPadding,
                        0,
                      ),
                      child: Align(
                        alignment: Alignment.topRight,
                        child: Builder(
                          builder: (drawerContext) => _premiumTopActions(
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
                physics: const BouncingSheetPhysics(),
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
    );
  }

  Widget _premiumTopActions({
    required VoidCallback onMenuTap,
    required VoidCallback onAccountTap,
  }) {
    return Container(
      height: ResSize.h * 50,
      padding: EdgeInsets.all(ResSize.h * 3),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColor.white.withOpacity(0.99),
            const Color(0xFFF8FAFA).withOpacity(0.98),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _premiumLine, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF162C36).withOpacity(0.13),
            blurRadius: 22,
            offset: const Offset(0, 7),
          ),
          BoxShadow(
            color: AppColor.white.withOpacity(0.88),
            blurRadius: 2,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _premiumTopAction(
            icon: Icons.menu_open_rounded,
            semanticLabel: 'Menu',
            onTap: onMenuTap,
          ),
          Container(height: ResSize.h * 23, width: 0.8, color: _premiumLine),
          _premiumTopAction(
            icon: Icons.person_rounded,
            semanticLabel: 'Account',
            onTap: onAccountTap,
          ),
        ],
      ),
    );
  }

  Widget _premiumTopAction({
    required IconData icon,
    required String semanticLabel,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(19),
          child: SizedBox(
            height: ResSize.h * 44,
            width: ResSize.w * 46,
            child: Icon(
              icon,
              size: ResSize.h * 24,
              color: const Color(0xFF11181D),
            ),
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
                  GestureDetector(
                    onTap: _toggleHomeSheet,
                    child: Container(
                      width: ResSize.w * 42,
                      height: ResSize.h * 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFCED4D8),
                        borderRadius: BorderRadius.circular(11),
                      ),
                    ),
                  ),
                  12.height,
                  if (_promotionVisible) ...[_ridePromotionTicket(), 9.height],
                  _whereToCard(),
                  IgnorePointer(
                    ignoring: sheetProgress < 0.92,
                    child: ClipRect(
                      child: Align(
                        alignment: Alignment.topCenter,
                        heightFactor: sheetProgress,
                        child: Opacity(
                          opacity: sheetProgress,
                          child: Column(
                            children: [15.height, _savedPlacesRow()],
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
                                _advanceBookingCard(),
                                14.height,
                                _comfortRideCarousel(),
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
                      color: _premiumLine.withOpacity(1 - sheetProgress),
                      width: 0.8,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(
                          0.14 * (1 - sheetProgress),
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
                            child: _premiumBottomNavItem(
                              iconAsset: AppAssets.navMap,
                              label: 'Map',
                              active: true,
                              floatingFraction: 1 - sheetProgress,
                              onTap: () {},
                            ),
                          ),
                          Expanded(
                            child: _premiumBottomNavItem(
                              iconAsset: AppAssets.navPayment,
                              label: 'Payment',
                              floatingFraction: 1 - sheetProgress,
                              onTap: _openPayment,
                            ),
                          ),
                          Expanded(
                            child: _premiumBottomNavItem(
                              iconAsset: AppAssets.navSchedule,
                              label: 'Schedule ride',
                              floatingFraction: 1 - sheetProgress,
                              onTap: _openSchedule,
                            ),
                          ),
                          Expanded(
                            child: _premiumBottomNavItem(
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

  Widget _comfortRideCarousel() {
    final viewportWidth = MediaQuery.of(context).size.width;
    final cardWidth = (viewportWidth * 0.78).clamp(270.0, 330.0).toDouble();
    final imageHeight = ResSize.h * 112;
    final bandHeight = ResSize.h * 64;

    return SizedBox(
      height: imageHeight + bandHeight + ResSize.h * 2,
      width: double.infinity,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.only(right: ResSize.w * 8),
        children: [
          _homePromoCard(
            cardWidth: cardWidth,
            imageHeight: imageHeight,
            bandHeight: bandHeight,
            imageAsset: 'assets/images/movera_comfort_ride.jpeg',
            title: 'Movera Comfort',
            subtitle: 'Extra space. Elevated comfort. A smoother way to ride.',
            onTap: _handleDestinationTap,
          ),
          SizedBox(width: ResSize.w * 12),
          _homePromoCard(
            cardWidth: cardWidth,
            imageHeight: imageHeight,
            bandHeight: bandHeight,
            imageAsset: 'assets/images/pin_verification.png',
            title: 'Safety Toolkit',
            subtitle: 'Essential safety tools, ready throughout every ride.',
            onTap: () {},
          ),
          SizedBox(width: ResSize.w * 12),
          _homePromoCard(
            cardWidth: cardWidth,
            imageHeight: imageHeight,
            bandHeight: bandHeight,
            imageAsset: 'assets/images/movera_airport_premium.jpeg',
            title: 'Fly with ease',
            subtitle:
                'Reserve your airport ride ahead and travel with less stress.',
            onTap: _openSchedule,
          ),
          SizedBox(width: ResSize.w * 12),
          _homePromoCard(
            cardWidth: cardWidth,
            imageHeight: imageHeight,
            bandHeight: bandHeight,
            imageAsset: 'assets/images/movera_events_premium.jpeg',
            title: 'Reserve for events',
            subtitle:
                'Plan your ride early and arrive exactly when you need to.',
            onTap: _openSchedule,
          ),
          SizedBox(width: ResSize.w * 12),
          _homePromoCard(
            cardWidth: cardWidth,
            imageHeight: imageHeight,
            bandHeight: bandHeight,
            imageAsset: 'assets/images/movera_business_premium.jpeg',
            title: 'Reserve work rides',
            subtitle:
                'Reliable scheduled rides for meetings and important workdays.',
            onTap: _openSchedule,
          ),
          SizedBox(width: ResSize.w * 12),
          _homePromoCard(
            cardWidth: cardWidth,
            imageHeight: imageHeight,
            bandHeight: bandHeight,
            imageAsset: 'assets/images/movera_outings_premium.jpeg',
            title: 'Plan for outings',
            subtitle:
                'Book ahead for dinners, appointments and plans around town.',
            onTap: _openSchedule,
          ),
          SizedBox(width: ResSize.w * 18),
        ],
      ),
    );
  }

  Widget _homePromoCard({
    required double cardWidth,
    required double imageHeight,
    required double bandHeight,
    required String imageAsset,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: cardWidth,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: AppColor.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: _premiumLine, width: 0.8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.055),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: double.infinity,
                  height: imageHeight,
                  child: Image.asset(
                    imageAsset,
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                    filterQuality: FilterQuality.high,
                  ),
                ),
                Container(
                  width: double.infinity,
                  height: bandHeight,
                  color: AppColor.white,
                  padding: EdgeInsets.fromLTRB(
                    ResSize.w * 13,
                    ResSize.h * 8,
                    ResSize.w * 13,
                    ResSize.h * 7,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextWidget(
                        text: title,
                        color: _premiumInk,
                        fontSize: 13.6,
                        fontWeight: fwBold,
                      ),
                      3.height,
                      TextWidget(
                        text: subtitle,
                        color: _premiumMuted,
                        fontSize: 9.2,
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
    );
  }

  Widget _pickupAddressField() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showRouteAddressPicker(initialField: 'pickup'),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: ResSize.h * 52,
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: ResSize.w * 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F9F9),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE8EDEF), width: 0.8),
          ),
          child: Row(
            children: [
              Container(
                width: ResSize.w * 32,
                height: ResSize.h * 32,
                decoration: BoxDecoration(
                  color: _premiumAccentSoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.my_location_rounded,
                  color: _premiumAccent,
                  size: ResSize.h * 17,
                ),
              ),
              11.width,
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextWidget(
                      text: 'Pickup',
                      color: _premiumMuted,
                      fontSize: 8.5,
                      fontWeight: fwMedium,
                    ),
                    2.height,
                    TextWidget(
                      text: _findingLocation
                          ? 'Finding your current location…'
                          : _shortAddress(_pickupAddress, maxLength: 35),
                      color: _premiumInk,
                      fontSize: 11.5,
                      fontWeight: fwSemiBold,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.edit_location_alt_outlined,
                color: _premiumMuted,
                size: ResSize.h * 18,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _savedPlacesRow() {
    final cards = <Widget>[
      SizedBox(
        width: ResSize.w * 108,
        child: _quickPlaceCard(
          iconAsset: AppAssets.quickHome,
          title: 'Home',
          subtitle: _shortAddress(_homeAddress, maxLength: 15),
          onTap: () =>
              _useSavedPlaceAsDestination(_homeAddress, target: 'home'),
        ),
      ),
      8.width,
      SizedBox(
        width: ResSize.w * 108,
        child: _quickPlaceCard(
          iconAsset: AppAssets.quickWork,
          title: 'Work',
          subtitle: _shortAddress(_workAddress, maxLength: 15),
          onTap: () =>
              _useSavedPlaceAsDestination(_workAddress, target: 'work'),
        ),
      ),
      8.width,
      SizedBox(
        width: ResSize.w * 108,
        child: _quickPlaceCard(
          iconAsset: AppAssets.quickAdd,
          title: 'Add',
          subtitle: 'New place',
          onTap: _openAddPlacePicker,
        ),
      ),
    ];
    for (final place in _savedPlaces) {
      cards
        ..add(8.width)
        ..add(SizedBox(width: ResSize.w * 108, child: _customPlaceCard(place)));
    }
    return SizedBox(
      height: ResSize.h * 46,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(children: cards),
      ),
    );
  }

  Widget _customPlaceCard(_SavedPlaceData place) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _useSavedPlaceAsDestination(
          place.address,
          target: 'custom',
          customType: place.type,
        ),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: ResSize.h * 44,
          padding: EdgeInsets.symmetric(horizontal: ResSize.w * 9),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFFFFF), Color(0xFFF5F9F9)],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFDDE7E9), width: 0.8),
          ),
          child: Row(
            children: [
              Icon(
                _placeIcon(place.type),
                size: ResSize.h * 13,
                color: _premiumAccent,
              ),
              7.width,
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextWidget(
                      text: _placeLabel(place.type),
                      color: _premiumInk,
                      fontSize: 10.5,
                      fontWeight: fwSemiBold,
                    ),
                    2.height,
                    TextWidget(
                      text: _shortAddress(place.address, maxLength: 15),
                      color: _premiumMuted.withOpacity(0.82),
                      fontSize: 7.8,
                      fontWeight: fwNormal,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _advanceBookingCard() {
    return InkWell(
      onTap: _openSchedule,
      borderRadius: BorderRadius.circular(26),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(
          ResSize.w * 12,
          ResSize.h * 12,
          ResSize.w * 12,
          ResSize.h * 15,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFA),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: _premiumLine, width: 0.8),
          boxShadow: [
            BoxShadow(
              color: _premiumAccent.withOpacity(0.06),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: SizedBox(
                width: double.infinity,
                height: ResSize.h * 142,
                child: Image.asset(
                  'assets/images/advance_booking_driver.png',
                  fit: BoxFit.cover,
                  alignment: const Alignment(0, -0.28),
                  filterQuality: FilterQuality.high,
                ),
              ),
            ),
            15.height,
            TextWidget(
              text: 'Plan ahead. Ride on time.',
              color: _premiumInk,
              fontSize: 17,
              fontWeight: fwBold,
            ),
            7.height,
            Padding(
              padding: EdgeInsets.symmetric(horizontal: ResSize.w * 8),
              child: TextWidget(
                text:
                    'Book your ride in advance and we’ll help arrange a driver for the time you choose.',
                color: _premiumMuted,
                fontSize: 11.5,
                fontWeight: fwNormal,
                textAlign: TextAlign.center,
              ),
            ),
            14.height,
            Container(
              height: ResSize.h * 42,
              width: double.infinity,
              decoration: BoxDecoration(
                color: _premiumAccent,
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: TextWidget(
                text: 'Schedule a ride',
                color: AppColor.white,
                fontSize: 12.5,
                fontWeight: fwSemiBold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ridePromotionTicket() {
    return Semantics(
      button: true,
      label: _promotionTitle,
      child: Container(
        height: ResSize.h * 48,
        decoration: BoxDecoration(
          color: AppColor.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0xFFDDE2E4), width: 0.9),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF142D39).withOpacity(0.09),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _handleDestinationTap,
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(15),
                  ),
                  child: Padding(
                    padding: EdgeInsets.only(left: ResSize.w * 11),
                    child: Row(
                      children: [
                        Container(
                          width: ResSize.w * 45,
                          height: ResSize.h * 34,
                          alignment: Alignment.center,
                          child: Image.asset(
                            'assets/images/promo_card_img.png',
                            width: ResSize.w * 43,
                            height: ResSize.h * 31,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.high,
                          ),
                        ),
                        8.width,
                        Expanded(
                          child: TextWidget(
                            text: _promotionTitle,
                            color: _premiumInk,
                            fontSize: 12.2,
                            fontWeight: fwSemiBold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Container(width: 0.8, height: ResSize.h * 24, color: _premiumLine),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _dismissPromotion,
                borderRadius: const BorderRadius.horizontal(
                  right: Radius.circular(15),
                ),
                child: SizedBox(
                  width: ResSize.w * 45,
                  height: double.infinity,
                  child: Icon(
                    Icons.close_rounded,
                    size: ResSize.h * 20,
                    color: _premiumMuted,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _whereToCard() {
    return Container(
      height: ResSize.h * 58,
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(ResSize.w * 4, 0, ResSize.w * 7, 0),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9F9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8EDEF), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF173B4D).withOpacity(0.035),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _handleDestinationTap,
                borderRadius: BorderRadius.circular(18),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: ResSize.w * 13),
                  child: Row(
                    children: [
                      Icon(
                        Icons.search_rounded,
                        size: ResSize.h * 26,
                        color: _premiumInk,
                      ),
                      12.width,
                      Expanded(
                        child: TextWidget(
                          text: _destinationAddress == null
                              ? 'Where to?'
                              : _shortAddress(
                                  _destinationAddress,
                                  maxLength: 28,
                                ),
                          color: _premiumInk.withOpacity(0.72),
                          fontSize: _destinationAddress == null ? 16.5 : 12.5,
                          fontWeight: fwMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _openSchedule,
              borderRadius: BorderRadius.circular(18),
              child: Container(
                height: ResSize.h * 28.4,
                padding: EdgeInsets.symmetric(horizontal: ResSize.w * 8),
                decoration: BoxDecoration(
                  color: AppColor.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _premiumLine, width: 0.8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.045),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      AppAssets.navSchedule,
                      height: ResSize.h * 20.4,
                      width: ResSize.w * 20.4,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                    ),
                    4.width,
                    TextWidget(
                      text: 'Later',
                      color: _premiumInk,
                      fontSize: 9.2,
                      fontWeight: fwSemiBold,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickPlaceCard({
    required String iconAsset,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: ResSize.h * 44,
          padding: EdgeInsets.symmetric(horizontal: ResSize.w * 9),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFFFFF), Color(0xFFF5F9F9)],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFDDE7E9), width: 0.8),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF174E55).withOpacity(0.055),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: AppColor.white.withOpacity(0.9),
                blurRadius: 2,
                offset: const Offset(0, -1),
              ),
            ],
          ),
          child: Row(
            children: [
              Image.asset(
                iconAsset,
                height: ResSize.h * 12.3,
                width: ResSize.w * 12.3,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
              8.width,
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextWidget(
                      text: title,
                      color: _premiumInk,
                      fontSize: 11.5,
                      fontWeight: fwSemiBold,
                    ),
                    2.height,
                    TextWidget(
                      text: subtitle,
                      color: _premiumMuted.withOpacity(0.82),
                      fontSize: 8.25,
                      fontWeight: fwNormal,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _premiumBottomNavItem({
    required String iconAsset,
    required String label,
    required VoidCallback onTap,
    bool active = false,
    double floatingFraction = 0,
  }) {
    final activeColor = Color.lerp(
      const Color(0xFF2A7A84),
      _premiumInk,
      floatingFraction,
    )!;
    final color = active ? activeColor : const Color(0xFF899197);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          height: ResSize.h * 52,
          margin: EdgeInsets.symmetric(
            horizontal: ResSize.w * 2.5 * floatingFraction,
          ),
          decoration: BoxDecoration(
            color: active
                ? Color.lerp(
                    Colors.transparent,
                    const Color(0xFFF2F2F2),
                    floatingFraction,
                  )
                : Colors.transparent,
            borderRadius: BorderRadius.circular(
              24 * floatingFraction + 14 * (1 - floatingFraction),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: ResSize.h * 30,
                width: ResSize.w * 30,
                child: Center(
                  child: Opacity(
                    opacity: active ? 1 : 0.86,
                    child: Image.asset(
                      iconAsset,
                      height: ResSize.h * 18.68,
                      width: ResSize.w * 18.68,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                ),
              ),
              3.height,
              Padding(
                padding: EdgeInsets.symmetric(horizontal: ResSize.w * 2),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: TextWidget(
                    text: label,
                    color: Colors.black,
                    fontSize: 9.5,
                    fontWeight: active ? fwSemiBold : fwMedium,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget profilePanelColumn(ScrollController sc) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: screenHorizPadding,
        vertical: ResSize.h * 20,
      ),
      controller: sc,
      child: Column(
        children: [
          Container(
            width: ResSize.w * 40,
            height: ResSize.h * 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          20.height,
          Row(
            children: [
              Container(
                height: ResSize.h * 60,
                width: ResSize.w * 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColor.liteBlue,
                ),
                child: Center(
                  child: Icon(
                    Icons.person,
                    size: ResSize.h * 35,
                    color: Colors.white,
                  ),
                ),
              ),
              16.width,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextWidget(
                      text: "John Doe",
                      fontSize: 18,
                      fontWeight: fwBold,
                      color: AppColor.title,
                    ),
                    4.height,
                    TextWidget(
                      text: "john.doe@email.com",
                      fontSize: 14,
                      fontWeight: fwNormal,
                      color: AppColor.subtitle,
                    ),
                    4.height,
                    Row(
                      children: [
                        Icon(
                          Icons.star,
                          size: ResSize.h * 16,
                          color: Colors.amber,
                        ),
                        4.width,
                        TextWidget(
                          text: "4.8 (125 rides)",
                          fontSize: 12,
                          fontWeight: fwMedium,
                          color: AppColor.subtitle,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  _profilePanelController.close();
                },
                child: Container(
                  height: ResSize.h * 30,
                  width: ResSize.w * 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey[100],
                  ),
                  child: Center(
                    child: Icon(
                      Icons.close,
                      size: ResSize.h * 20,
                      color: AppColor.title,
                    ),
                  ),
                ),
              ),
            ],
          ),
          24.height,
          _buildProfileOption(
            icon: Icons.account_circle_outlined,
            title: "Edit Profile",
            onTap: () {},
          ),
          _buildProfileOption(
            icon: Icons.history,
            title: "Ride History",
            onTap: () {
              Navigator.push(
                context,
                RightToLeftTransition(const RideHistory()),
              );
            },
          ),
          _buildProfileOption(
            icon: Icons.payment_outlined,
            title: "Payment Methods",
            onTap: () {
              Navigator.push(
                context,
                RightToLeftTransition(const WalletScreen()),
              );
            },
          ),
          _buildProfileOption(
            icon: Icons.notifications_outlined,
            title: "Notifications",
            onTap: () {
              Navigator.push(
                context,
                RightToLeftTransition(const NotificationScreen()),
              );
            },
          ),
          _buildProfileOption(
            icon: Icons.help_outline,
            title: "Help & Support",
            onTap: () {
              Navigator.push(
                context,
                RightToLeftTransition(const SupportHome()),
              );
            },
          ),
          _buildProfileOption(
            icon: Icons.settings_outlined,
            title: "Settings",
            onTap: () {},
          ),
          16.height,
          Divider(color: AppColor.border, thickness: 0.4),
          16.height,
          _buildProfileOption(
            icon: Icons.logout,
            title: "Sign Out",
            onTap: () {},
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: ResSize.h * 16,
          horizontal: ResSize.w * 4,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: ResSize.h * 24,
              color: isDestructive ? Colors.red : AppColor.title,
            ),
            16.width,
            Expanded(
              child: TextWidget(
                text: title,
                fontSize: 16,
                fontWeight: fwMedium,
                color: isDestructive ? Colors.red : AppColor.title,
              ),
            ),
            if (!isDestructive)
              Icon(
                Icons.arrow_forward_ios,
                size: ResSize.h * 16,
                color: AppColor.subtitle,
              ),
          ],
        ),
      ),
    );
  }
}

class _PremiumRouteLocationBadge extends StatelessWidget {
  const _PremiumRouteLocationBadge({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final corner = size * 0.25;
    final road = size * 0.105;
    final pinOutline = size * 0.65;
    final pinSize = size * 0.57;

    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(corner),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFFFFF), Color(0xFFF1F0EC)],
          ),
          border: Border.all(color: const Color(0xFFD2D6D8), width: 0.8),
          boxShadow: const [
            BoxShadow(
              color: Color(0x190D1A20),
              blurRadius: 7,
              offset: Offset(0, 3),
            ),
            BoxShadow(
              color: Color(0xA6FFFFFF),
              blurRadius: 1,
              offset: Offset(0, -1),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(corner - 1),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                left: -size * 0.06,
                top: size * 0.23,
                child: Container(
                  width: size * 0.74,
                  height: road,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.98),
                    borderRadius: BorderRadius.circular(road),
                  ),
                ),
              ),
              Positioned(
                right: size * 0.17,
                top: -size * 0.04,
                child: Container(
                  width: road,
                  height: size * 0.65,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.97),
                    borderRadius: BorderRadius.circular(road),
                  ),
                ),
              ),
              Positioned(
                right: -size * 0.08,
                bottom: size * 0.10,
                child: Transform.rotate(
                  angle: -0.52,
                  child: Container(
                    width: size * 0.70,
                    height: road,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFFFF),
                      borderRadius: BorderRadius.circular(road),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: size * 0.11,
                bottom: -size * 0.04,
                child: Container(
                  width: size * 0.10,
                  height: size * 0.50,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0E3E5),
                    borderRadius: BorderRadius.circular(size),
                  ),
                ),
              ),
              Transform.translate(
                offset: Offset(0, size * 0.035),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      color: const Color(0xFFFDFDFD),
                      size: pinOutline,
                      shadows: const [
                        Shadow(
                          color: Color(0x30000000),
                          blurRadius: 5,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    ShaderMask(
                      blendMode: BlendMode.srcIn,
                      shaderCallback: (bounds) => LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color.lerp(color, Colors.white, 0.22)!,
                          color,
                          Color.lerp(color, Colors.black, 0.24)!,
                        ],
                        stops: const [0.0, 0.48, 1.0],
                      ).createShader(bounds),
                      child: Icon(
                        Icons.location_on_rounded,
                        color: Colors.white,
                        size: pinSize,
                      ),
                    ),
                    Positioned(
                      top: size * 0.17,
                      left: size * 0.43,
                      child: Container(
                        width: size * 0.075,
                        height: size * 0.075,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.55),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PickupMapResult {
  const _PickupMapResult({required this.address, required this.position});
  final String address;
  final LatLng position;
}

class _PickupMapPickerPage extends StatefulWidget {
  const _PickupMapPickerPage({
    required this.initialPosition,
    required this.initialAddress,
    this.isDestination = false,
  });

  final LatLng initialPosition;
  final String initialAddress;
  final bool isDestination;

  @override
  State<_PickupMapPickerPage> createState() => _PickupMapPickerPageState();
}

class _PickupMapPickerPageState extends State<_PickupMapPickerPage> {
  static const Color _ink = Color(0xFF172027);
  static const Color _muted = Color(0xFF747D84);
  static const Color _accent = Color(0xFF245E78);
  static const Color _field = Color(0xFFF4F5F6);
  static const Color _line = Color(0xFFE5E8EA);

  GoogleMapController? _controller;
  late LatLng _position;
  late String _address;
  bool _resolving = false;

  @override
  void initState() {
    super.initState();
    _position = widget.initialPosition;
    _address = widget.initialAddress;
    WidgetsBinding.instance.addPostFrameCallback((_) => _resolveAddress());
  }

  Future<void> _resolveAddress() async {
    if (_resolving) return;
    setState(() => _resolving = true);
    final resolved = await address_service.reverseGeocodeAddress(
      _position.latitude,
      _position.longitude,
    );
    if (!mounted) return;
    setState(() {
      if (resolved != null && resolved.trim().isNotEmpty) {
        _address = resolved.trim();
      }
      _resolving = false;
    });
  }

  Future<void> _recenter() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return;
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }
      final current = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final target = LatLng(current.latitude, current.longitude);
      _position = target;
      await _controller?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: target, zoom: 17),
        ),
      );
      await _resolveAddress();
    } catch (_) {}
  }

  String get _shortAddress {
    if (_resolving) return 'Finding pickup point…';
    final clean = _address.trim();
    if (clean.isEmpty) return 'Current location';
    return clean.split(',').take(2).join(',').trim();
  }

  @override
  Widget build(BuildContext context) {
    final safeTop = MediaQuery.of(context).padding.top;
    final safeBottom = MediaQuery.of(context).padding.bottom;
    final panelBottomPadding = 18.0 + safeBottom;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomGoogleMap(
              initialPosition: CameraPosition(
                target: widget.initialPosition,
                zoom: 17,
              ),
              myLocationEnabled: false,
              onMapCreated: (controller) => _controller = controller,
              onCameraMove: (camera) => _position = camera.target,
              onCameraIdle: _resolveAddress,
              padding: const EdgeInsets.only(bottom: 286),
            ),
          ),
          const Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 112),
              child: _PremiumPickupPin(),
            ),
          ),
          Positioned(
            top: safeTop + 16,
            left: 16,
            child: PointerInterceptor(
              child: Material(
                color: Colors.white,
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: () => Navigator.pop(context),
                  customBorder: const CircleBorder(),
                  child: const SizedBox(
                    width: 54,
                    height: 54,
                    child: Icon(
                      Icons.arrow_back_rounded,
                      color: _ink,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: 18,
            bottom: 278 + safeBottom,
            child: PointerInterceptor(
              child: Material(
                color: Colors.white,
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: _recenter,
                  customBorder: const CircleBorder(),
                  child: const SizedBox(
                    width: 52,
                    height: 52,
                    child: Icon(
                      Icons.my_location_rounded,
                      color: _ink,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: PointerInterceptor(
              child: Container(
                padding: EdgeInsets.fromLTRB(20, 10, 20, panelBottomPadding),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  border: Border(top: BorderSide(color: _line, width: 1)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD9DDE0),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      widget.isDestination
                          ? 'Set exact destination'
                          : 'Set exact pickup',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _ink,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.35,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Drag map to move pin',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _muted,
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      height: 58,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: _field,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: _accent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.location_on_rounded,
                              color: Colors.white,
                              size: 17,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _shortAddress,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _ink,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          if (_resolving)
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: _accent,
                              ),
                            )
                          else
                            const Icon(
                              Icons.place_outlined,
                              color: _muted,
                              size: 22,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Material(
                      color: _ink,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        onTap: _resolving
                            ? null
                            : () => Navigator.pop(
                                context,
                                _PickupMapResult(
                                  address: _address,
                                  position: _position,
                                ),
                              ),
                        borderRadius: BorderRadius.circular(14),
                        child: SizedBox(
                          height: 58,
                          width: double.infinity,
                          child: Center(
                            child: Text(
                              _resolving
                                  ? 'Locating…'
                                  : widget.isDestination
                                  ? 'Confirm destination'
                                  : 'Confirm pickup',
                              style: TextStyle(
                                color: Colors.white.withOpacity(
                                  _resolving ? 0.58 : 1,
                                ),
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.15,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumPickupPin extends StatelessWidget {
  const _PremiumPickupPin();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: const BoxDecoration(
            color: Color(0xFF172027),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Container(
              width: 11,
              height: 11,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
        Container(width: 3, height: 19, color: const Color(0xFF172027)),
        Container(
          width: 12,
          height: 4,
          decoration: BoxDecoration(
            color: const Color(0xFFB7BDC1),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ],
    );
  }
}
