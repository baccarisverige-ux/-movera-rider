import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:movera_rider/core/constants/appassets.dart';
import 'package:movera_rider/features/rider/Finding%20Drivers/finding_drivers.dart';
import 'package:movera_rider/shared/widgets/navigation_transition.dart';

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

class _SelectRideState extends State<SelectRide> {
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
    final topHeight = media.padding.top + 132;
    return Scaffold(
      backgroundColor: const Color(0xFFF6F5F1),
      body: Column(
        children: [
          SizedBox(
            height: topHeight,
            width: double.infinity,
            child: Stack(
              children: [
                const Positioned.fill(child: _RouteCanvas()),
                Positioned(
                  top: media.padding.top + 8,
                  left: 16,
                  right: 16,
                  child: _searchBar(),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF162C36).withOpacity(0.10),
                    blurRadius: 28,
                    offset: const Offset(0, -8),
                  ),
                ],
              ),
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
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Choose your ride',
                        style: _text(22, weight: FontWeight.w700, letterSpacing: -0.4),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
                    child: _filterRow(),
                  ),
                  Expanded(
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
                      itemCount: _visibleRides.length,
                      itemBuilder: (context, index) =>
                          _rideTile(_visibleRides[index]),
                    ),
                  ),
                  _footer(media.padding.bottom),
                ],
              ),
            ),
          ),
        ],
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
          onTap: () => setState(() => _selectedRideId = ride.id),
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
                  width: 92,
                  height: 62,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        child: Image.asset(ride.image, fit: BoxFit.contain),
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
                            _kr(ride.price),
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
