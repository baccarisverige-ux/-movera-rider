import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:movera_rider/core/constants/appassets.dart';
import 'package:movera_rider/features/rider/Finding%20Drivers/finding_drivers.dart';
import 'package:movera_rider/shared/widgets/custom_google_map.dart';
import 'package:movera_rider/shared/widgets/navigation_transition.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

class SelectRide extends StatefulWidget {
  const SelectRide({
    super.key,
    required this.pickupAddress,
    required this.destinationAddress,
    required this.pickupPosition,
    required this.destinationPosition,
    this.stops = const <String>[],
  });

  final String pickupAddress;
  final String destinationAddress;
  final LatLng pickupPosition;
  final LatLng destinationPosition;
  final List<String> stops;

  @override
  State<SelectRide> createState() => _SelectRideState();
}

enum _RideFilter { recommended, faster, cheaper }

class _RideOption {
  const _RideOption({
    required this.id,
    required this.image,
    required this.name,
    required this.note,
    required this.arrival,
    required this.etaMin,
    required this.price,
    required this.seats,
    this.badge,
    this.glyph,
  });

  final String id;
  final String image;
  final String name;
  final String note;
  final String arrival;
  final int etaMin;
  final double price;
  final int seats;
  final String? badge;
  final IconData? glyph;
}

class _PaymentOption {
  const _PaymentOption({
    required this.brand,
    required this.name,
    required this.detail,
  });

  final String brand;
  final String name;
  final String detail;
}

class _SelectRideState extends State<SelectRide>
    with SingleTickerProviderStateMixin {
  static const Color _ink = Color(0xFF1D252C);
  static const Color _muted = Color(0xFF778189);
  static const Color _line = Color(0xFFE7EBEE);
  static const Color _accent = Color(0xFF2D5878);
  static const Color _accentSoft = Color(0xFFEAF2F8);
  static const Color _field = Color(0xFFF6F5F1);
  static const Color _cta = Color(0xFF11181D);

  static const List<_RideOption> _allRides = [
    _RideOption(
      id: 'movera',
      image: 'assets/images/rides/movera.png',
      name: 'Movera',
      note: 'Affordable and convenient rides',
      arrival: '8 min',
      etaMin: 8,
      price: 259,
      seats: 4,
      badge: 'RECOMMENDED',
    ),
    _RideOption(
      id: 'comfort',
      image: 'assets/images/rides/comfort.png',
      name: 'Comfort',
      note: 'Newer cars with extra legroom',
      arrival: '11 min',
      etaMin: 11,
      price: 339,
      seats: 4,
    ),
    _RideOption(
      id: 'premium',
      image: 'assets/images/rides/premium.png',
      name: 'Premium',
      note: 'Premium cars with top-rated drivers',
      arrival: '11 min',
      etaMin: 11,
      price: 369,
      seats: 4,
    ),
    _RideOption(
      id: 'priority',
      image: 'assets/images/rides/priority.png',
      name: 'Priority',
      note: 'More options, less waiting',
      arrival: '6 min',
      etaMin: 6,
      price: 289,
      seats: 4,
      badge: 'FASTER',
    ),
    _RideOption(
      id: 'xl',
      image: 'assets/images/rides/xl.png',
      name: 'Movera XL',
      note: 'Cars for larger groups (6 people)',
      arrival: '12 min',
      etaMin: 12,
      price: 399,
      seats: 6,
    ),
    _RideOption(
      id: 'electric',
      image: 'assets/images/rides/electric.png',
      name: 'Electric',
      note: 'Quiet and fossil-free cars',
      arrival: '9 min',
      etaMin: 9,
      price: 259,
      seats: 4,
      glyph: Icons.bolt_rounded,
    ),
    _RideOption(
      id: 'pet',
      image: 'assets/images/rides/pet.png',
      name: 'Movera Pet',
      note: 'Pet-friendly rides',
      arrival: '10 min',
      etaMin: 10,
      price: 279,
      seats: 4,
      glyph: Icons.pets_rounded,
    ),
  ];

  final List<_PaymentOption> _payments = const [
    _PaymentOption(
      brand: 'apple',
      name: 'Apple Pay',
      detail: 'Available by default',
    ),
    _PaymentOption(
      brand: 'google',
      name: 'Google Pay',
      detail: 'Available by default',
    ),
    _PaymentOption(
      brand: 'paypal',
      name: 'PayPal',
      detail: 'Pay for this ride',
    ),
    _PaymentOption(
      brand: 'cards',
      name: 'Card',
      detail: 'Visa, Mastercard',
    ),
    _PaymentOption(
      brand: 'swish',
      name: 'Swish',
      detail: 'Instant mobile payment',
    ),
    _PaymentOption(
      brand: 'cash',
      name: 'Cash',
      detail: 'Pay the driver in cash',
    ),
    _PaymentOption(
      brand: 'wallet',
      name: 'Wallet',
      detail: 'kr 7 available',
    ),
  ];

  String _selectedRideId = 'movera';
  int _selectedPayment = 0;
  _RideFilter _filter = _RideFilter.recommended;
  DateTime? _scheduledFor;
  final Map<String, double> _offeredPrices = {};
  bool _mapReady = false;
  bool _mapParked = false;
  GoogleMapController? _mapController;
  late final AnimationController _sheetSlide;
  final ScrollController _listController = ScrollController();

  @override
  void initState() {
    super.initState();
    _sheetSlide = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
      value: 1,
    );
    _sheetSlide.addStatusListener((status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        _pinSelectedToTop();
      }
    });
    Future<void>.delayed(
      Duration(milliseconds: kIsWeb ? 280 : 80),
      () {
        if (mounted) setState(() => _mapReady = true);
      },
    );
  }

  @override
  void dispose() {
    _sheetSlide.dispose();
    _listController.dispose();
    _mapController = null;
    super.dispose();
  }

  _RideOption get _selectedRide =>
      _allRides.firstWhere((ride) => ride.id == _selectedRideId);

  double _priceFor(_RideOption ride) =>
      _offeredPrices[ride.id] ?? ride.price;

  void _selectRide(String id) {
    setState(() {
      _selectedRideId = id;
      _offeredPrices.putIfAbsent(
        id,
        () => _allRides.firstWhere((ride) => ride.id == id).price,
      );
    });
    _pinSelectedToTop();
  }

  void _pinSelectedToTop() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_listController.hasClients) return;
      _listController.animateTo(
        0,
        duration: const Duration(milliseconds: 420),
        curve: const Cubic(0.22, 1.0, 0.36, 1.0),
      );
    });
  }

  void _nudgePrice(int delta) {
    final ride = _selectedRide;
    final current = _priceFor(ride);
    final minimum = (ride.price * 0.65).roundToDouble();
    final maximum = (ride.price * 1.8).roundToDouble();
    final next = (current + delta).clamp(minimum, maximum).roundToDouble();
    if (next == current) return;
    setState(() => _offeredPrices[ride.id] = next);
  }

  List<_RideOption> get _visibleRides {
    final rides = [..._allRides];
    switch (_filter) {
      case _RideFilter.faster:
        rides.sort((a, b) => a.etaMin.compareTo(b.etaMin));
        break;
      case _RideFilter.cheaper:
        rides.sort((a, b) => a.price.compareTo(b.price));
        break;
      case _RideFilter.recommended:
        break;
    }
    return rides;
  }

  List<_RideOption> get _rankedRides {
    final rides = [..._visibleRides];
    final selected = rides.where((ride) => ride.id == _selectedRideId);
    final rest = rides.where((ride) => ride.id != _selectedRideId);
    return [...selected, ...rest];
  }

  TextStyle _text(
    double size, {
    FontWeight weight = FontWeight.w500,
    Color color = _ink,
    double? height,
    double? letterSpacing,
  }) {
    return GoogleFonts.poppins(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  String _compactAddress(String value) {
    final cleaned = value.trim();
    if (cleaned.isEmpty) return 'Unknown place';
    final parts = cleaned
        .split(',')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .where((part) => !RegExp(r'^\d{3,}$').hasMatch(part))
        .toList();
    if (parts.isEmpty) return cleaned;
    if (parts.length == 1) return parts.first;
    return '${parts[0]}, ${parts[1]}';
  }

  String _kr(double value) => 'kr ${value.toStringAsFixed(0)}';

  double _minSheet(MediaQueryData media) {
    final needed = 368 + media.padding.bottom;
    final cap = media.size.height * 0.58;
    return needed.clamp(320.0, cap < 360 ? 360.0 : cap);
  }

  double _maxSheet(MediaQueryData media) {
    final minH = _minSheet(media);
    final maxH = media.size.height - media.padding.top - 200;
    return maxH <= minH ? minH : maxH;
  }

  Widget _webSafe(Widget child) {
    if (kIsWeb) return child;
    return PointerInterceptor(child: child);
  }

  void _onSheetDragUpdate(DragUpdateDetails details, MediaQueryData media) {
    _nudgeSheet(details.primaryDelta ?? 0, media);
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
    if (target < 0.5) _pinSelectedToTop();
    _sheetSlide.animateTo(
      target,
      duration: const Duration(milliseconds: 520),
      curve: const Cubic(0.22, 1.0, 0.36, 1.0),
    );
  }

  void _nudgeSheet(double primaryDelta, MediaQueryData media) {
    final range = _maxSheet(media) - _minSheet(media);
    if (range <= 0) return;
    _sheetSlide.value =
        (_sheetSlide.value - primaryDelta / range).clamp(0.0, 1.0);
  }

  bool _onListScroll(ScrollNotification notification, MediaQueryData media) {
    if (notification is OverscrollNotification) {
      _nudgeSheet(-notification.overscroll, media);
      if (_sheetSlide.value < 0.5) _pinSelectedToTop();
      return true;
    }
    if (notification is ScrollUpdateNotification) {
      final metrics = notification.metrics;
      final delta = notification.scrollDelta ?? 0;
      final atTop = metrics.pixels <= 0;
      final atBottom = metrics.pixels >= metrics.maxScrollExtent - 1;
      if (atTop && delta < 0) {
        _nudgeSheet(-delta, media);
        return true;
      }
      if (atBottom && delta > 0) {
        _nudgeSheet(-delta, media);
        return true;
      }
    }
    return false;
  }

  int _tripMinutes() {
    const earthKm = 6371.0;
    final lat1 = widget.pickupPosition.latitude * math.pi / 180;
    final lat2 = widget.destinationPosition.latitude * math.pi / 180;
    final dLat =
        (widget.destinationPosition.latitude - widget.pickupPosition.latitude) *
            math.pi /
            180;
    final dLng = (widget.destinationPosition.longitude -
            widget.pickupPosition.longitude) *
        math.pi /
        180;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) * math.cos(lat2) * math.sin(dLng / 2) * math.sin(dLng / 2);
    final km = 2 * earthKm * math.asin(math.sqrt(a));
    return (km / 32 * 60).clamp(10, 48).round();
  }

  List<LatLng> _routePoints() {
    final start = widget.pickupPosition;
    final end = widget.destinationPosition;
    final mid = LatLng(
      (start.latitude + end.latitude) / 2,
      (start.longitude + end.longitude) / 2,
    );
    final dx = end.longitude - start.longitude;
    final dy = end.latitude - start.latitude;
    final mag = math.sqrt(dx * dx + dy * dy);
    if (mag < 0.00001) return [start, end];
    final bend = mag * 0.22;
    final curve = LatLng(
      mid.latitude + (-dx / mag) * bend,
      mid.longitude + (dy / mag) * bend,
    );
    return [start, curve, end];
  }

  String get _pickupEtaLabel => '${_selectedRide.etaMin} min';

  String get _arriveLabel {
    final arrive = DateTime.now().add(
      Duration(minutes: _selectedRide.etaMin + _tripMinutes()),
    );
    final hour = arrive.hour.toString().padLeft(2, '0');
    final minute = arrive.minute.toString().padLeft(2, '0');
    return 'Arrive by $hour:$minute';
  }

  Future<void> _fitRoute() async {
    final controller = _mapController;
    if (controller == null || !mounted) return;
    final pickup = widget.pickupPosition;
    final destination = widget.destinationPosition;
    final samePoint =
        (pickup.latitude - destination.latitude).abs() < 0.00008 &&
        (pickup.longitude - destination.longitude).abs() < 0.00008;
    try {
      if (samePoint) {
        await controller.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: pickup, zoom: 14.4),
          ),
        );
        return;
      }
      await controller.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(
              pickup.latitude < destination.latitude
                  ? pickup.latitude
                  : destination.latitude,
              pickup.longitude < destination.longitude
                  ? pickup.longitude
                  : destination.longitude,
            ),
            northeast: LatLng(
              pickup.latitude > destination.latitude
                  ? pickup.latitude
                  : destination.latitude,
              pickup.longitude > destination.longitude
                  ? pickup.longitude
                  : destination.longitude,
            ),
          ),
          56,
        ),
      );
    } catch (_) {}
  }

  Future<void> _withParkedMap(Future<void> Function() action) async {
    if (!_mapParked) {
      setState(() => _mapParked = true);
      _mapController = null;
      await Future<void>.delayed(const Duration(milliseconds: 90));
      if (!mounted) return;
    }
    try {
      await action();
    } finally {
      if (mounted) setState(() => _mapParked = false);
    }
  }

  Future<void> _chooseLater() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 180)),
      helpText: 'Choose ride date',
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now.add(const Duration(hours: 1))),
      helpText: 'Choose pickup time',
    );
    if (time == null || !mounted) return;
    setState(() {
      _scheduledFor = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _showBookingPicker() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _line,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 18),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'When do you want to ride?',
                    style: _text(20, weight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 12),
                _sheetChoice(
                  icon: Icons.bolt_rounded,
                  title: 'Book now',
                  subtitle: 'Request a driver right away',
                  selected: _scheduledFor == null,
                  onTap: () {
                    setState(() => _scheduledFor = null);
                    Navigator.pop(sheetContext);
                  },
                ),
                _sheetChoice(
                  icon: Icons.calendar_month_rounded,
                  title: 'Book for later',
                  subtitle: 'Choose a date and pickup time',
                  selected: _scheduledFor != null,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    Future<void>.delayed(
                      const Duration(milliseconds: 180),
                      _chooseLater,
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showPaymentPicker() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
            decoration: const BoxDecoration(
              color: Color(0xFFF6F5F1),
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: _line,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Payment', style: _text(22, weight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(
                  'PAYMENT METHODS',
                  style: _text(
                    10,
                    weight: FontWeight.w600,
                    color: _muted,
                    letterSpacing: 1.25,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: _line),
                  ),
                  child: Column(
                    children: [
                      for (var i = 0; i < _payments.length; i++) ...[
                        if (i > 0)
                          const Divider(
                            height: 1,
                            indent: 62,
                            endIndent: 16,
                            color: _line,
                          ),
                        _walletPaymentTile(i, sheetContext),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _book() {
    final selected = _selectedRide;
    _withParkedMap(() async {
      if (!mounted) return;
      await Navigator.push(
        context,
        BottomToTopTransition(
          FindingDrivers(
            pickupAddress: widget.pickupAddress,
            destinationAddress: widget.destinationAddress,
            pickupPosition: widget.pickupPosition,
            destinationPosition: widget.destinationPosition,
            rideType: selected.name,
            price: _priceFor(selected),
            paymentMethod: _payments[_selectedPayment].name,
          ),
        ),
      );
    });
  }

  Widget _liveMap() {
    return CustomGoogleMap(
      initialPosition: CameraPosition(
        target: widget.pickupPosition,
        zoom: 13.2,
      ),
      padding: const EdgeInsets.fromLTRB(10, 72, 10, 10),
      markers: {
        Marker(
          markerId: const MarkerId('pickup'),
          position: widget.pickupPosition,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
        ),
        Marker(
          markerId: const MarkerId('destination'),
          position: widget.destinationPosition,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
        ),
      },
      polylines: {
        Polyline(
          polylineId: const PolylineId('routeGlow'),
          points: _routePoints(),
          color: const Color(0x553B6BFF),
          width: 10,
          geodesic: true,
        ),
        Polyline(
          polylineId: const PolylineId('route'),
          points: _routePoints(),
          color: const Color(0xFF3B6BFF),
          width: 5,
          geodesic: true,
        ),
      },
      myLocationEnabled: false,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      compassEnabled: false,
      trafficEnabled: false,
      buildingsEnabled: false,
      indoorViewEnabled: false,
      onMapCreated: (controller) {
        _mapController = controller;
        Future<void>.delayed(const Duration(milliseconds: 280), _fitRoute);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final useLiveMap = _mapReady && !_mapParked;
    return Scaffold(
      backgroundColor: const Color(0xFFF6F5F1),
      body: AnimatedBuilder(
        animation: _sheetSlide,
        builder: (context, _) {
          final minSheet = _minSheet(media);
          final maxSheet = _maxSheet(media);
          final sheetHeight =
              minSheet + (maxSheet - minSheet) * _sheetSlide.value;
          final mapHeight =
              (media.size.height - sheetHeight).clamp(168.0, media.size.height);
          final collapsed = _sheetSlide.value < 0.38;
          final visibleRides = _rankedRides;
          return Column(
            children: [
              SizedBox(
                height: mapHeight,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Positioned.fill(
                      child: useLiveMap ? _liveMap() : const _RouteCanvas(),
                    ),
                    Positioned(
                      top: media.padding.top + 8,
                      left: 16,
                      right: 16,
                      child: PointerInterceptor(child: _searchBar()),
                    ),
                    Positioned(
                      top: media.padding.top + 64,
                      left: 16,
                      right: 16,
                      child: PointerInterceptor(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _mapBadge(
                              _pickupEtaLabel,
                              const Color(0xFF1F8A4C),
                            ),
                            _mapBadge(
                              _arriveLabel,
                              const Color(0xFF3B6BFF),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: sheetHeight,
                width: double.infinity,
                child: Material(
                  color: Colors.white,
                  elevation: 18,
                  shadowColor: const Color(0xFF162C36).withOpacity(0.16),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onVerticalDragUpdate: (details) =>
                            _onSheetDragUpdate(details, media),
                        onVerticalDragEnd: _onSheetDragEnd,
                        child: Column(
                          children: [
                            const SizedBox(height: 10),
                            Container(
                              width: 38,
                              height: 4,
                              decoration: BoxDecoration(
                                color: _line,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 14, 12, 0),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Choose your ride',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: _text(
                                        20,
                                        weight: FontWeight.w700,
                                        letterSpacing: -0.4,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _priceStepper(),
                                ],
                              ),
                            ),
                            if (collapsed)
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(14, 10, 14, 0),
                                child: _rideTile(_selectedRide),
                              ),
                          ],
                        ),
                      ),
                      if (!collapsed)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                          child: _filterRow(),
                        ),
                      if (!collapsed)
                        Expanded(
                          child: NotificationListener<ScrollNotification>(
                            onNotification: (notification) =>
                                _onListScroll(notification, media),
                            child: ListView.builder(
                              controller: _listController,
                              physics: const BouncingScrollPhysics(
                                parent: AlwaysScrollableScrollPhysics(),
                              ),
                              padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
                              itemCount: visibleRides.length,
                              itemBuilder: (context, index) =>
                                  _rideTile(visibleRides[index]),
                            ),
                          ),
                        )
                      else
                        const Spacer(),
                      _footer(media.padding.bottom),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _mapBadge(String label, Color color) {
    return Material(
      color: color,
      elevation: 6,
      shadowColor: color.withOpacity(0.35),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        child: Text(
          label,
          style: _text(12.5, weight: FontWeight.w700, color: Colors.white),
        ),
      ),
    );
  }

  Widget _searchBar() {
    return Material(
      color: Colors.white.withOpacity(0.96),
      borderRadius: BorderRadius.circular(22),
      elevation: 0,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.96),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: _line),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF162C36).withOpacity(0.08),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_rounded, color: _ink),
            ),
            Expanded(
              child: Text(
                _compactAddress(widget.destinationAddress),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _text(15, weight: FontWeight.w500),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  Widget _priceStepper() {
    final ride = _selectedRide;
    final price = _priceFor(ride);
    final minimum = (ride.price * 0.65).roundToDouble();
    final maximum = (ride.price * 1.8).roundToDouble();
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: _field,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _stepperButton(
            Icons.remove_rounded,
            enabled: price > minimum,
            onTap: () => _nudgePrice(-10),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              _kr(price),
              style: _text(13.5, weight: FontWeight.w600),
            ),
          ),
          _stepperButton(
            Icons.add_rounded,
            enabled: price < maximum,
            onTap: () => _nudgePrice(10),
          ),
        ],
      ),
    );
  }

  Widget _stepperButton(
    IconData icon, {
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 32,
      height: 32,
      child: Material(
        color: Colors.white,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: enabled ? onTap : null,
          child: Icon(
            icon,
            size: 18,
            color: enabled ? _ink : _muted.withOpacity(0.45),
          ),
        ),
      ),
    );
  }

  Widget _filterRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _filterChip(
            label: 'Recommended',
            selected: _filter == _RideFilter.recommended,
            onTap: () => setState(() => _filter = _RideFilter.recommended),
          ),
          const SizedBox(width: 8),
          _filterChip(
            label: 'Faster',
            icon: Icons.schedule_rounded,
            selected: _filter == _RideFilter.faster,
            onTap: () => setState(() => _filter = _RideFilter.faster),
          ),
          const SizedBox(width: 8),
          _filterChip(
            label: 'Cheaper',
            icon: Icons.payments_outlined,
            selected: _filter == _RideFilter.cheaper,
            onTap: () => setState(() => _filter = _RideFilter.cheaper),
          ),
        ],
      ),
    );
  }

  Widget _filterChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? _accentSoft : _field,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: selected ? _accent : _line, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 15, color: selected ? _accent : _muted),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: _text(
                13,
                weight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _rideTile(_RideOption ride) {
    final selected = ride.id == _selectedRideId;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _selectRide(ride.id),
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.fromLTRB(10, 12, 14, 12),
            decoration: BoxDecoration(
              color: selected ? const Color(0xFFFBFCFC) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected ? _accent : Colors.transparent,
                width: 1.2,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: const Color(0xFF162C36).withOpacity(0.06),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 108,
                  height: 72,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        child: Image.asset(
                          ride.image,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.directions_car_filled_rounded,
                            color: _muted,
                            size: 36,
                          ),
                        ),
                      ),
                      if (ride.glyph != null)
                        Positioned(
                          left: 0,
                          bottom: 0,
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: const BoxDecoration(
                              color: _accentSoft,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(ride.glyph, size: 14, color: _accent),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              ride.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: _text(16, weight: FontWeight.w600),
                            ),
                          ),
                          Text(
                            _kr(_priceFor(ride)),
                            style: _text(16, weight: FontWeight.w600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Text(
                            ride.arrival,
                            style: _text(12.5, color: _muted),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.person_outline_rounded,
                            size: 14,
                            color: _muted,
                          ),
                          Text(
                            ' ${ride.seats}',
                            style: _text(12.5, color: _muted),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        ride.note,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _text(12.5, color: _muted, weight: FontWeight.w400),
                      ),
                      if (ride.badge != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: selected ? _accent : _accentSoft,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            ride.badge!,
                            style: _text(
                              9.5,
                              weight: FontWeight.w700,
                              color: selected ? Colors.white : _accent,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ],
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

  Widget _footer(double bottomInset) {
    final selected = _selectedRide;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16, 8, 16, 12 + bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _line)),
      ),
      child: Column(
        children: [
          _paymentButton(),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Material(
                  color: _cta,
                  borderRadius: BorderRadius.circular(18),
                  child: InkWell(
                    onTap: _book,
                    borderRadius: BorderRadius.circular(18),
                    child: SizedBox(
                      height: 54,
                      child: Center(
                        child: Text(
                          _scheduledFor == null
                              ? 'Select ${selected.name}'
                              : 'Schedule ${selected.name}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _text(
                            16,
                            weight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Material(
                color: _cta,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: _showBookingPicker,
                  child: const SizedBox(
                    width: 54,
                    height: 54,
                    child: Icon(
                      Icons.calendar_month_rounded,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _paymentButton() {
    final method = _payments[_selectedPayment];
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: _showPaymentPicker,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          constraints: const BoxConstraints(minHeight: 62),
          padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _line),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.035),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              _brandMark(method.brand),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      method.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _text(15, weight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      method.detail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _text(
                        11.5,
                        weight: FontWeight.w500,
                        color: method.brand == 'cash' ? _accent : _muted,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: _muted, size: 22),
            ],
          ),
        ),
      ),
    );
  }

  Widget _walletPaymentTile(int index, BuildContext sheetContext) {
    final method = _payments[index];
    final selected = _selectedPayment == index;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() => _selectedPayment = index);
          Navigator.pop(sheetContext);
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Row(
            children: [
              _brandMark(method.brand),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(method.name, style: _text(14.5, weight: FontWeight.w600)),
                    Text(
                      selected ? 'Default for rides' : method.detail,
                      style: _text(
                        11.5,
                        color: selected ? _accent : _muted,
                        weight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: selected ? _ink : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(color: selected ? _ink : _line, width: 1.4),
                ),
                child: selected
                    ? const Icon(Icons.check_rounded, color: Colors.white, size: 15)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sheetChoice({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? _accentSoft : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? _accent : _line),
        ),
        child: Row(
          children: [
            Icon(icon, color: _ink),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: _text(16, weight: FontWeight.w600)),
                  Text(subtitle, style: _text(13, color: _muted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _brandMark(String brand) {
    if (brand == 'swish') {
      return ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: SizedBox(
          width: 42,
          height: 38,
          child: SvgPicture.asset(
            'assets/images/swish_brand.svg',
            fit: BoxFit.cover,
          ),
        ),
      );
    }
    Widget logo;
    Color background = Colors.white;
    if (brand == 'apple') {
      logo = SvgPicture.asset(
        'assets/images/apple_pay_brand.svg',
        fit: BoxFit.contain,
      );
    } else if (brand == 'google') {
      logo = Transform.scale(
        scale: 1.18,
        child: Image.asset(
          'assets/images/google_pay_brand.png',
          fit: BoxFit.contain,
        ),
      );
    } else if (brand == 'paypal') {
      logo = Image.asset(AppAssets.paypal, fit: BoxFit.contain);
    } else if (brand == 'cards') {
      logo = Row(
        children: [
          Expanded(child: Image.asset(AppAssets.visa, fit: BoxFit.contain)),
          const SizedBox(width: 2),
          Expanded(child: Image.asset(AppAssets.mastercard, fit: BoxFit.contain)),
        ],
      );
    } else if (brand == 'cash') {
      background = const Color(0xFFEEF6F0);
      logo = const Icon(
        Icons.payments_outlined,
        color: Color(0xFF1F7A4D),
        size: 20,
      );
    } else {
      logo = Image.asset(AppAssets.wallet, color: _ink, fit: BoxFit.contain);
    }
    return Container(
      width: 42,
      height: 38,
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: background == Colors.white ? _line : background,
        ),
      ),
      child: logo,
    );
  }
}

class _RouteCanvas extends StatelessWidget {
  const _RouteCanvas();

  @override
  Widget build(BuildContext context) {
    return const CustomPaint(painter: _RoutePainter(), child: SizedBox.expand());
  }
}

class _RoutePainter extends CustomPainter {
  const _RoutePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final sky = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFDCE8DE), Color(0xFFEEF3E8), Color(0xFFF6F5F1)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, sky);

    final water = Paint()..color = const Color(0xFFC9D9D4).withOpacity(0.7);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.08, size.height * 0.18, size.width * 0.38, 28),
        const Radius.circular(20),
      ),
      water,
    );

    final land = Paint()..color = const Color(0xFFD7E3D4);
    canvas.drawCircle(Offset(size.width * 0.78, size.height * 0.42), 46, land);
    canvas.drawCircle(Offset(size.width * 0.22, size.height * 0.62), 34, land);

    final path = Path()
      ..moveTo(size.width * 0.16, size.height * 0.72)
      ..quadraticBezierTo(
        size.width * 0.42,
        size.height * 0.18,
        size.width * 0.84,
        size.height * 0.46,
      );
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0x553B6BFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF3B6BFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );

    void pin(Offset c, Color color) {
      canvas.drawCircle(c, 10, Paint()..color = color);
      canvas.drawCircle(c, 4.4, Paint()..color = Colors.white);
    }

    pin(Offset(size.width * 0.16, size.height * 0.72), const Color(0xFF1F8A4C));
    pin(Offset(size.width * 0.84, size.height * 0.46), const Color(0xFF3B6BFF));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
