import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:movera_rider/core/constants/appassets.dart';
import 'package:movera_rider/features/rider/Finding%20Drivers/finding_drivers.dart';
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

class _RideOption {
  const _RideOption({
    required this.image,
    required this.name,
    required this.note,
    required this.arrival,
    required this.price,
    required this.seats,
  });

  final String image;
  final String name;
  final String note;
  final String arrival;
  final double price;
  final int seats;
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
  static const Color _ink = Color(0xFF151B1F);
  static const Color _muted = Color(0xFF7C858B);
  static const Color _line = Color(0xFFE4E8EA);
  static const Color _surface = Color(0xFFF5F6F6);
  static const Color _accent = Color(0xFF245E78);
  static const Color _accentSoft = Color(0xFFEAF2F5);

  final List<_RideOption> _rides = const [
    _RideOption(
      image: AppAssets.mini,
      name: 'Mini Ride',
      note: 'Everyday ride',
      arrival: '2 min',
      price: 5.00,
      seats: 4,
    ),
    _RideOption(
      image: AppAssets.ecoFriendly,
      name: 'Eco-Friendly',
      note: 'Lower emissions',
      arrival: '3 min',
      price: 7.50,
      seats: 4,
    ),
    _RideOption(
      image: AppAssets.xl,
      name: 'XL',
      note: 'Extra space',
      arrival: '5 min',
      price: 17.00,
      seats: 6,
    ),
    _RideOption(
      image: AppAssets.luxury,
      name: 'Luxury',
      note: 'Premium comfort',
      arrival: '4 min',
      price: 27.00,
      seats: 4,
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

  int _selectedRide = 1;
  int _selectedPayment = 0;
  double _price = 7.50;
  DateTime? _scheduledFor;

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

  void _selectRide(int index) {
    setState(() {
      _selectedRide = index;
      _price = _rides[index].price;
    });
  }

  void _increasePrice() {
    setState(() => _price = double.parse((_price + 0.50).toStringAsFixed(2)));
  }

  void _decreasePrice() {
    final minimum = _rides[_selectedRide].price * 0.65;
    if (_price <= minimum) return;
    setState(() {
      _price = double.parse(
        (_price - 0.50).clamp(minimum, 9999).toStringAsFixed(2),
      );
    });
  }

  String get _scheduleLabel {
    final value = _scheduledFor;
    if (value == null) return 'Book now';
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return 'Later · ${value.day}/${value.month} $hour:$minute';
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
      builder: (sheetContext) => _choiceSheet(
        title: 'When do you want to ride?',
        children: [
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
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Choose how you want to pay',
                  style: TextStyle(
                    color: _muted,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w400,
                  ),
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 22,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Column(
        children: [
          for (var i = 0; i < indexes.length; i++) ...[
            if (i > 0)
              const Divider(
                height: 1,
                indent: 62,
                endIndent: 16,
                color: _line,
              ),
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
        borderRadius: BorderRadius.circular(20),
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
                    const SizedBox(height: 2),
                    Text(
                      selected ? 'Default for rides' : method.detail,
                      style: TextStyle(
                        color: selected ? _accent : _muted,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: selected ? _ink : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? _ink : _line,
                    width: 1.4,
                  ),
                ),
                child: selected
                    ? const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 15,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _choiceSheet({required String title, required List<Widget> children}) {
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
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                title,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                ),
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _sheetChoice({
    IconData? icon,
    String? image,
    bool tintImage = false,
    required String title,
    required String subtitle,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        constraints: const BoxConstraints(minHeight: 68),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? _accentSoft : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? _accent : _line),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 34,
              height: 34,
              child: image != null
                  ? Padding(
                      padding: const EdgeInsets.all(3),
                      child: Image.asset(
                        image,
                        fit: BoxFit.contain,
                        color: tintImage ? _ink : null,
                      ),
                    )
                  : Icon(icon, color: _ink, size: 25),
            ),
            const SizedBox(width: 13),
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
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: _muted,
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected ? Icons.check_circle_rounded : Icons.circle_outlined,
              color: selected ? _accent : const Color(0xFFCAD0D3),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFEEF1E8),
      body: Column(
        children: [
          SizedBox(
            height: media.padding.top + 86,
            child: Stack(
              children: [
                const Positioned.fill(child: _RouteCanvas()),
                Positioned(
                  top: media.padding.top + 14,
                  left: 18,
                  child: PointerInterceptor(
                    child: Material(
                      color: Colors.white,
                      shape: const CircleBorder(),
                      elevation: 5,
                      shadowColor: Colors.black26,
                      child: InkWell(
                        onTap: () => Navigator.pop(context),
                        customBorder: const CircleBorder(),
                        child: const SizedBox(
                          width: 52,
                          height: 52,
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
                  top: media.padding.top + 14,
                  left: 88,
                  right: 18,
                  child: PointerInterceptor(child: _routeChip()),
                ),
              ],
            ),
          ),
          Expanded(
            child: PointerInterceptor(
              child: Material(
                color: Colors.white,
                elevation: 16,
                shadowColor: Colors.black26,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                clipBehavior: Clip.antiAlias,
                child: _panel(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _routeChip() {
    final destination = _compactAddress(widget.destinationAddress);
    final pickup = _compactAddress(widget.pickupAddress);
    return Container(
      constraints: const BoxConstraints(minHeight: 52),
      padding: const EdgeInsets.fromLTRB(12, 8, 14, 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.96),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 18,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.route_rounded, color: _accent, size: 21),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  destination,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  'From $pickup',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _panel() {
    final selected = _rides[_selectedRide];
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Column(
      children: [
        const SizedBox(height: 10),
        Center(
          child: Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFD8DDE0),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
              const SizedBox(height: 12),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 18),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Choose your ride',
                    style: TextStyle(
                      color: _ink,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.6,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 2),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 18),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Pick the comfort and space that suits you.',
                    style: TextStyle(
                      color: _muted,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                  itemCount: _rides.length,
                  itemBuilder: (context, index) => _rideTile(index),
                ),
              ),
              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(18, 8, 18, 10 + bottomInset),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: _line)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 58,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: _surface,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          _priceButton(Icons.remove_rounded, _decreasePrice),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'Your fare',
                                  style: TextStyle(
                                    color: _muted,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  '\$${_price.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: _ink,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _priceButton(Icons.add_rounded, _increasePrice),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    _paymentButton(),
                    const SizedBox(height: 8),
                    _compactAction(
                      icon: Icons.schedule_rounded,
                      label: 'Pickup',
                      value: _scheduleLabel,
                      onTap: _showBookingPicker,
                    ),
                    const SizedBox(height: 10),
                    Material(
                      color: _ink,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            BottomToTopTransition(
                              FindingDrivers(
                                pickupAddress: widget.pickupAddress,
                                destinationAddress: widget.destinationAddress,
                                pickupPosition: widget.pickupPosition,
                                destinationPosition:
                                    widget.destinationPosition,
                                rideType: selected.name,
                                price: _price,
                                paymentMethod:
                                    _payments[_selectedPayment].name,
                              ),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: Center(
                            child: Text(
                              _scheduledFor == null
                                  ? 'Book ${selected.name}'
                                  : 'Schedule ${selected.name}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
    );
  }

  Widget _rideTile(int index) {
    final ride = _rides[index];
    final selected = index == _selectedRide;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected ? _accentSoft : Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _selectRide(index),
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            height: 76,
            padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? _accent : _line,
                width: selected ? 1.6 : 1,
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 86,
                  child: Image.asset(
                    ride.image,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              ride.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _ink,
                                fontSize: 15.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.person_outline_rounded,
                            color: _muted,
                            size: 15,
                          ),
                          const SizedBox(width: 1),
                          Text(
                            '${ride.seats}',
                            style: const TextStyle(
                              color: _muted,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${ride.arrival} · ${ride.note}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _muted,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '\$${ride.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _priceButton(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, color: _ink, size: 22),
        ),
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
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      method.detail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _accent,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: _muted,
                size: 22,
              ),
            ],
          ),
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
          Expanded(
            child: Image.asset(AppAssets.mastercard, fit: BoxFit.contain),
          ),
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
      logo = Image.asset(
        AppAssets.wallet,
        fit: BoxFit.contain,
        color: _ink,
      );
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

  Widget _compactAction({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 58,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _line),
          ),
          child: Row(
            children: [
              Icon(icon, color: _ink, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
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

class _RouteCanvas extends StatelessWidget {
  const _RouteCanvas();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFD8EDB5),
            Color(0xFFEEF1E8),
            Color(0xFFDDE6D0),
          ],
        ),
      ),
      child: CustomPaint(painter: _RoutePainter(), child: SizedBox.expand()),
    );
  }
}

class _RoutePainter extends CustomPainter {
  const _RoutePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final land = Paint()..color = const Color(0xFFC1E589).withOpacity(0.55);
    canvas.drawCircle(Offset(size.width * 0.18, size.height * 0.72), 48, land);
    canvas.drawCircle(Offset(size.width * 0.82, size.height * 0.28), 36, land);
    final road = Paint()
      ..color = Colors.white
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(size.width * 0.22, size.height * 0.78)
      ..quadraticBezierTo(
        size.width * 0.52,
        size.height * 0.10,
        size.width * 0.78,
        size.height * 0.42,
      );
    canvas.drawPath(path, road);
    final pin = Paint()..color = const Color(0xFF245E78);
    canvas.drawCircle(Offset(size.width * 0.22, size.height * 0.78), 7, pin);
    canvas.drawCircle(Offset(size.width * 0.78, size.height * 0.42), 7, pin);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
