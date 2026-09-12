import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:movera_rider/app/di.dart';
import 'package:movera_rider/core/constants/appassets.dart';
import 'package:movera_rider/core/maps/geo_point.dart';
import 'package:movera_rider/core/maps/map_owners.dart';
import 'package:movera_rider/features/ride_selection/application/ride_selection_controller.dart';
import 'package:movera_rider/features/booking/application/booking_controller.dart';
import 'package:movera_rider/features/finding_driver/presentation/finding_drivers.dart';
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

  List<_RideOption> get _allRides {
    return _selection.rides().map((ride) {
      return _RideOption(
        id: ride.id,
        image: ride.image,
        name: ride.name,
        note: ride.note,
        arrival: ride.arrival,
        etaMin: ride.etaMin,
        price: ride.price,
        seats: ride.seats,
        badge: ride.badge,
        glyph: ride.glyph == 'bolt'
            ? Icons.bolt_rounded
            : ride.glyph == 'pets'
                ? Icons.pets_rounded
                : null,
      );
    }).toList();
  }

  List<_PaymentOption> get _payments {
    return _selection.payments().map((item) {
      return _PaymentOption(
        brand: item.brand,
        name: item.name,
        detail: item.detail,
      );
    }).toList();
  }

  _RideFilter _filter = _RideFilter.recommended;
  final RideSelectionController _selection = RideSelectionController();
  bool _mapReady = false;
  bool _mapParked = false;
  GoogleMapController? _mapController;
  late final AnimationController _sheetSlide;

  @override
  void initState() {
    super.initState();
    _sheetSlide = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
      value: 1,
    );
    // Home already unmounted its map. Wait one frame so the platform view
    // is gone before this screen creates the only live map.
    Future<void>.delayed(
      Duration(milliseconds: kIsWeb ? 280 : 80),
      () {
        if (mounted) setState(() => _mapReady = true);
      },
    );
    _loadQuotes();
  }

  Future<void> _loadQuotes() async {
    final generation = _selection.beginQuotes();
    await _selection.loadQuotes(
      generation: generation,
      pickup: widget.pickupAddress,
      destination: widget.destinationAddress,
    );
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _sheetSlide.dispose();
    _mapController = null;
    AppScope.instance.maps.detach(owner: MapOwners.selectRide);
    super.dispose();
  }

  _RideOption get _selectedRide =>
      _allRides.firstWhere((ride) => ride.id == _selection.selectedRideId);

  double _priceFor(_RideOption ride) =>
      _selection.priceFor(ride.id, ride.price);

  void _selectRide(String id) {
    final catalog =
        _allRides.firstWhere((ride) => ride.id == id).price;
    setState(() {
      _selection.selectRide(id, catalog);
    });
  }

  void _nudgePrice(int delta) {
    final ride = _selectedRide;
    final current = _priceFor(ride);
    final next = _selection.changeOffer(
      id: ride.id,
      catalog: ride.price,
      delta: delta,
    );
    if (next == current) return;
    setState(() {});
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

  double _minSheet(MediaQueryData media) =>
      (348 + media.padding.bottom).clamp(300.0, media.size.height * 0.48);

  double _maxSheet(MediaQueryData media) {
    final minH = _minSheet(media);
    final maxH = media.size.height - media.padding.top - 72;
    return maxH < minH + 64 ? minH + 64 : maxH;
  }

  void _onSheetDragUpdate(DragUpdateDetails details, MediaQueryData media) {
    final range = _maxSheet(media) - _minSheet(media);
    if (range <= 0) return;
    final next =
        (_sheetSlide.value - details.primaryDelta! / range).clamp(0.0, 1.0);
    _sheetSlide.value = next;
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
      duration: const Duration(milliseconds: 520),
      curve: const Cubic(0.22, 1.0, 0.36, 1.0),
    );
  }

  Future<void> _fitRoute() async {
    if (!mounted) return;
    final pickup = widget.pickupPosition;
    final destination = widget.destinationPosition;
    final samePoint =
        (pickup.latitude - destination.latitude).abs() < 0.00008 &&
        (pickup.longitude - destination.longitude).abs() < 0.00008;
    try {
      if (samePoint) {
        await AppScope.instance.maps.animateCamera(
          GeoPoint(pickup.latitude, pickup.longitude),
          zoom: 14.4,
        );
        return;
      }
      await AppScope.instance.maps.fitBounds(
        GeoPoint(pickup.latitude, pickup.longitude),
        GeoPoint(destination.latitude, destination.longitude),
        padding: 56,
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
      _selection.scheduleFor(DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      ));
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
                  selected: _selection.scheduledFor == null,
                  onTap: () {
                    setState(() => _selection.scheduleFor(null));
                    Navigator.pop(sheetContext);
                  },
                ),
                _sheetChoice(
                  icon: Icons.calendar_month_rounded,
                  title: 'Book for later',
                  subtitle: 'Choose a date and pickup time',
                  selected: _selection.scheduledFor != null,
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
      await BookingController().submitFinding(
        pickupAddress: widget.pickupAddress,
        destinationAddress: widget.destinationAddress,
        pickupLat: widget.pickupPosition.latitude,
        pickupLng: widget.pickupPosition.longitude,
        destinationLat: widget.destinationPosition.latitude,
        destinationLng: widget.destinationPosition.longitude,
        rideType: selected.name,
        price: _priceFor(selected),
        paymentMethod: _payments[_selection.selectedPayment].name,
      );
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
            paymentMethod: _payments[_selection.selectedPayment].name,
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final showLiveMap = _mapReady && !_mapParked;
    return Scaffold(
      backgroundColor: const Color(0xFFF6F5F1),
      body: AnimatedBuilder(
        animation: _sheetSlide,
        builder: (context, _) {
          final minSheet = _minSheet(media);
          final maxSheet = _maxSheet(media);
          final sheetHeight =
              minSheet + (maxSheet - minSheet) * _sheetSlide.value;
          final collapsed = _sheetSlide.value < 0.38;
          final visibleRides = collapsed
              ? <_RideOption>[_selectedRide]
              : _visibleRides;
          return Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                bottom: sheetHeight,
                child: showLiveMap
                    ? CustomGoogleMap(
                        initialPosition: CameraPosition(
                          target: widget.pickupPosition,
                          zoom: 13.2,
                        ),
                        markers: {
                          Marker(
                            markerId: const MarkerId('pickup'),
                            position: widget.pickupPosition,
                          ),
                          Marker(
                            markerId: const MarkerId('destination'),
                            position: widget.destinationPosition,
                          ),
                        },
                        polylines: {
                          Polyline(
                            polylineId: const PolylineId('route'),
                            points: [
                              widget.pickupPosition,
                              widget.destinationPosition,
                            ],
                            color: _accent,
                            width: 4,
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
                          AppScope.instance.maps.attach(
                            controller,
                            owner: MapOwners.selectRide,
                          );
                          AppScope.instance.map.drawRoute(
                            'select',
                            GeoPoint(
                              widget.pickupPosition.latitude,
                              widget.pickupPosition.longitude,
                            ),
                            GeoPoint(
                              widget.destinationPosition.latitude,
                              widget.destinationPosition.longitude,
                            ),
                          );
                          AppScope.instance.map.upsertMarker(
                            'pickup',
                            GeoPoint(
                              widget.pickupPosition.latitude,
                              widget.pickupPosition.longitude,
                            ),
                          );
                          AppScope.instance.map.upsertMarker(
                            'destination',
                            GeoPoint(
                              widget.destinationPosition.latitude,
                              widget.destinationPosition.longitude,
                            ),
                          );
                          Future<void>.delayed(
                            const Duration(milliseconds: 280),
                            _fitRoute,
                          );
                        },
                      )
                    : const _RouteCanvas(),
              ),
              Positioned(
                top: media.padding.top + 8,
                left: 16,
                right: 16,
                child: PointerInterceptor(child: _searchBar()),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: sheetHeight,
                child: PointerInterceptor(
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
                                padding: const EdgeInsets.fromLTRB(20, 16, 16, 0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Choose your ride',
                                        style: _text(
                                          22,
                                          weight: FontWeight.w700,
                                          letterSpacing: -0.4,
                                        ),
                                      ),
                                    ),
                                    _priceStepper(),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!collapsed)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
                            child: _filterRow(),
                          )
                        else
                          const SizedBox(height: 8),
                        Expanded(
                          child: ListView.builder(
                            physics: collapsed
                                ? const NeverScrollableScrollPhysics()
                                : const BouncingScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
                            itemCount: visibleRides.length,
                            itemBuilder: (context, index) =>
                                _rideTile(visibleRides[index]),
                          ),
                        ),
                        _footer(media.padding.bottom),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
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
    final selected = ride.id == _selection.selectedRideId;
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
                          _selection.scheduledFor == null
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
    final method = _payments[_selection.selectedPayment];
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
    final selected = _selection.selectedPayment == index;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() => _selection.selectPayment(index));
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
        ..color = const Color(0xFF2D5878).withOpacity(0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF2D5878)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round,
    );

    void pin(Offset c, Color color) {
      canvas.drawCircle(c, 9, Paint()..color = color);
      canvas.drawCircle(c, 4.2, Paint()..color = Colors.white);
    }

    pin(Offset(size.width * 0.16, size.height * 0.72), const Color(0xFF1D252C));
    pin(Offset(size.width * 0.84, size.height * 0.46), const Color(0xFF2D5878));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
