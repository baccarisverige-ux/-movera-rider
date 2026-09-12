import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
    required this.group,
  });

  final String brand;
  final String name;
  final String detail;
  final String group;
}

class _SelectRideState extends State<SelectRide> {
  static const Color _ink = Color(0xFF171C1F);
  static const Color _muted = Color(0xFF7A8288);
  static const Color _line = Color(0xFFE6E8E7);
  static const Color _accent = Color(0xFF1F7A4D);
  static const Color _accentSoft = Color(0xFFE7F4EC);

  static const List<_RideOption> _allRides = [
    _RideOption(
      id: 'movera',
      image: 'assets/images/rides/movera.jpg',
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
      image: 'assets/images/rides/comfort.jpg',
      name: 'Comfort',
      note: 'Newer cars with extra legroom',
      arrival: '11 min',
      etaMin: 11,
      price: 339,
      seats: 4,
    ),
    _RideOption(
      id: 'premium',
      image: 'assets/images/rides/premium.jpg',
      name: 'Premium',
      note: 'Premium cars with top-rated drivers',
      arrival: '11 min',
      etaMin: 11,
      price: 369,
      seats: 4,
    ),
    _RideOption(
      id: 'priority',
      image: 'assets/images/rides/priority.jpg',
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
      image: 'assets/images/rides/xl.jpg',
      name: 'Movera XL',
      note: 'Cars for larger groups (6 people)',
      arrival: '12 min',
      etaMin: 12,
      price: 399,
      seats: 6,
    ),
    _RideOption(
      id: 'electric',
      image: 'assets/images/rides/electric.jpg',
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
      image: 'assets/images/rides/pet.jpg',
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
      brand: 'swish',
      name: 'Swish',
      detail: 'Instant mobile payment',
      group: 'app',
    ),
    _PaymentOption(
      brand: 'cards',
      name: 'Card',
      detail: 'Visa, Mastercard',
      group: 'app',
    ),
    _PaymentOption(
      brand: 'apple',
      name: 'Apple Pay',
      detail: 'Fast checkout',
      group: 'app',
    ),
    _PaymentOption(
      brand: 'cash',
      name: 'Cash',
      detail: 'Pay the driver in cash',
      group: 'driver',
    ),
  ];

  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  String _selectedRideId = 'movera';
  int _selectedPayment = 0;
  _RideFilter _filter = _RideFilter.recommended;
  DateTime? _scheduledFor;
  bool _collapsed = false;
  bool _mapReady = false;
  GoogleMapController? _mapController;

  _RideOption get _selectedRide =>
      _allRides.firstWhere((ride) => ride.id == _selectedRideId);

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
    if (_collapsed) {
      return [_selectedRide];
    }
    return rides;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _mapReady = true);
    });
  }

  @override
  void dispose() {
    _sheetController.dispose();
    super.dispose();
  }

  Future<void> _fitRoute() async {
    final controller = _mapController;
    if (controller == null || !mounted) return;
    final pickup = widget.pickupPosition;
    final destination = widget.destinationPosition;
    final samePoint =
        (pickup.latitude - destination.latitude).abs() < 0.00001 &&
        (pickup.longitude - destination.longitude).abs() < 0.00001;
    if (samePoint) {
      await controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: pickup, zoom: 14.2),
        ),
      );
      return;
    }
    try {
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
          80,
        ),
      );
    } catch (_) {}
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
              borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD8DDE0),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(height: 18),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'When do you want to ride?',
                    style: TextStyle(
                      color: _ink,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
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
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD8DDE0),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Payment',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Choose how you want to pay',
                  style: TextStyle(color: _muted, fontSize: 13.5),
                ),
                const SizedBox(height: 18),
                const Text(
                  'PAY IN THE APP',
                  style: TextStyle(
                    color: _muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.25,
                  ),
                ),
                const SizedBox(height: 8),
                _paymentGroup(sheetContext, 'app'),
                const SizedBox(height: 16),
                const Text(
                  'PAY THE DRIVER',
                  style: TextStyle(
                    color: _muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.25,
                  ),
                ),
                const SizedBox(height: 8),
                _paymentGroup(sheetContext, 'driver'),
              ],
            ),
          ),
        );
      },
    );
  }

  void _book() {
    final selected = _selectedRide;
    Navigator.push(
      context,
      BottomToTopTransition(
        FindingDrivers(
          pickupAddress: widget.pickupAddress,
          destinationAddress: widget.destinationAddress,
          pickupPosition: widget.pickupPosition,
          destinationPosition: widget.destinationPosition,
          rideType: selected.name,
          price: selected.price,
          paymentMethod: _payments[_selectedPayment].name,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFEEF1E8),
      body: Stack(
        children: [
          Positioned.fill(
            child: _mapReady
                ? CustomGoogleMap(
                    initialPosition: CameraPosition(
                      target: widget.pickupPosition,
                      zoom: 12.6,
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
                        color: const Color(0xFF3B6BFF),
                        width: 5,
                      ),
                    },
                    myLocationEnabled: false,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    mapToolbarEnabled: false,
                    compassEnabled: false,
                    onMapCreated: (controller) {
                      _mapController = controller;
                      Future<void>.delayed(
                        const Duration(milliseconds: 280),
                        _fitRoute,
                      );
                    },
                  )
                : const ColoredBox(color: Color(0xFFEEF1E8)),
          ),
          Positioned(
            top: media.padding.top + 10,
            left: 12,
            right: 12,
            child: PointerInterceptor(child: _searchBar()),
          ),
          NotificationListener<DraggableScrollableNotification>(
            onNotification: (notification) {
              final collapsed = notification.extent < 0.46;
              if (collapsed != _collapsed) {
                setState(() => _collapsed = collapsed);
              }
              return false;
            },
            child: DraggableScrollableSheet(
              controller: _sheetController,
              initialChildSize: 0.74,
              minChildSize: 0.36,
              maxChildSize: 0.94,
              snap: true,
              snapSizes: const [0.36, 0.74, 0.94],
              builder: (context, scrollController) {
                return PointerInterceptor(
                  child: Material(
                    color: Colors.white,
                    elevation: 18,
                    shadowColor: Colors.black26,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(22),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        Container(
                          width: 42,
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFFD8DDE0),
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          child: _collapsed
                              ? const SizedBox(height: 6)
                              : Padding(
                                  key: const ValueKey('filters'),
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    12,
                                    16,
                                    4,
                                  ),
                                  child: _filterRow(),
                                ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            controller: scrollController,
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(14, 6, 14, 8),
                            itemCount: _visibleRides.length,
                            itemBuilder: (context, index) {
                              final ride = _visibleRides[index];
                              return _rideTile(ride);
                            },
                          ),
                        ),
                        _footer(media.padding.bottom),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchBar() {
    return Material(
      color: Colors.white.withOpacity(0.96),
      borderRadius: BorderRadius.circular(28),
      elevation: 4,
      shadowColor: Colors.black26,
      child: SizedBox(
        height: 48,
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_rounded, color: _ink),
            ),
            const Icon(Icons.search_rounded, color: _muted, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _compactAddress(widget.destinationAddress),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.add_rounded, color: _ink),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterRow() {
    return Row(
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
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.white : const Color(0xFFF4F5F4),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? _accent : const Color(0xFFE1E4E3),
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 15, color: selected ? _ink : _muted),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                color: _ink,
                fontSize: 13.5,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
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
      padding: const EdgeInsets.only(bottom: 4),
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedRideId = ride.id);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.fromLTRB(8, 10, 12, 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? _accent : Colors.transparent,
              width: 1.7,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 86,
                height: 58,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: Image.asset(ride.image, fit: BoxFit.contain),
                    ),
                    if (ride.glyph != null)
                      Positioned(
                        left: 0,
                        bottom: 2,
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: const BoxDecoration(
                            color: _accentSoft,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(ride.glyph, size: 15, color: _accent),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
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
                            style: const TextStyle(
                              color: _ink,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          _kr(ride.price),
                          style: const TextStyle(
                            color: _ink,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(
                          ride.arrival,
                          style: const TextStyle(
                            color: _muted,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.person_outline_rounded,
                          size: 14,
                          color: _muted,
                        ),
                        Text(
                          ' ${ride.seats}',
                          style: const TextStyle(
                            color: _muted,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      ride.note,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    if (ride.badge != null && selected) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: _accent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          ride.badge!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ] else if (ride.badge != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: _accentSoft,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          ride.badge!,
                          style: const TextStyle(
                            color: _accent,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
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
    );
  }

  Widget _footer(double bottomInset) {
    final method = _payments[_selectedPayment];
    final selected = _selectedRide;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16, 6, 16, 10 + bottomInset),
      color: Colors.white,
      child: Column(
        children: [
          InkWell(
            onTap: _showPaymentPicker,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  _brandMark(method.brand),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              method.name,
                              style: const TextStyle(
                                color: _ink,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: _ink,
                            ),
                          ],
                        ),
                        const Text(
                          'Personal ride',
                          style: TextStyle(color: _muted, fontSize: 12.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Material(
                  color: _accent,
                  borderRadius: BorderRadius.circular(28),
                  child: InkWell(
                    onTap: _book,
                    borderRadius: BorderRadius.circular(28),
                    child: SizedBox(
                      height: 52,
                      child: Center(
                        child: Text(
                          _scheduledFor == null
                              ? 'Select ${selected.name}'
                              : 'Schedule ${selected.name}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Material(
                color: _accent,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: _showBookingPicker,
                  child: const SizedBox(
                    width: 52,
                    height: 52,
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

  Widget _paymentGroup(BuildContext sheetContext, String group) {
    final indexes = [
      for (var i = 0; i < _payments.length; i++)
        if (_payments[i].group == group) i,
    ];
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _line),
      ),
      child: Column(
        children: [
          for (var i = 0; i < indexes.length; i++) ...[
            if (i > 0)
              const Divider(height: 1, indent: 62, endIndent: 16, color: _line),
            _walletPaymentTile(indexes[i], sheetContext),
          ],
        ],
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
                    Text(
                      method.name,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      selected ? 'Default for rides' : method.detail,
                      style: TextStyle(
                        color: selected ? _accent : _muted,
                        fontSize: 11.5,
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
                  Text(
                    title,
                    style: const TextStyle(
                      color: _ink,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(color: _muted, fontSize: 13),
                  ),
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
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 28,
          height: 22,
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
      logo = const Icon(Icons.payments_outlined, color: _accent, size: 16);
    } else {
      logo = Image.asset(AppAssets.wallet, color: _ink, fit: BoxFit.contain);
    }
    return Container(
      width: 28,
      height: 22,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _line),
      ),
      child: logo,
    );
  }
}
