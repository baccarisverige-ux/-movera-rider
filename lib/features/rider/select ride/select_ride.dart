import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:movera_rider/core/constants/appassets.dart';
import 'package:movera_rider/features/rider/Finding%20Drivers/finding_drivers.dart';
import 'package:movera_rider/shared/widgets/custom_google_map.dart';
import 'package:movera_rider/shared/widgets/navigation_transition.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

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
    required this.image,
    required this.name,
    this.tintable = false,
  });

  final String image;
  final String name;
  final bool tintable;
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
    _PaymentOption(image: AppAssets.wallet, name: 'Wallet', tintable: true),
    _PaymentOption(image: AppAssets.cash, name: 'Cash', tintable: true),
    _PaymentOption(image: AppAssets.mastercard, name: 'Mastercard'),
    _PaymentOption(image: AppAssets.applepay, name: 'Apple Pay'),
    _PaymentOption(image: AppAssets.paypal, name: 'PayPal'),
  ];

  int _selectedRide = 1;
  int _selectedPayment = 3;
  double _price = 7.50;
  DateTime? _scheduledFor;
  GoogleMapController? _mapController;
  late final Set<Marker> _markers;
  late final CameraPosition _initialPosition;

  @override
  void initState() {
    super.initState();
    _initialPosition = CameraPosition(target: widget.pickupPosition, zoom: 14);
    _markers = {
      Marker(
        markerId: const MarkerId('pickup'),
        position: widget.pickupPosition,
        infoWindow: InfoWindow(title: widget.pickupAddress),
        icon: BitmapDescriptor.defaultMarker,
      ),
      Marker(
        markerId: const MarkerId('destination'),
        position: widget.destinationPosition,
        infoWindow: InfoWindow(title: widget.destinationAddress),
        icon: BitmapDescriptor.defaultMarker,
      ),
    };
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
          CameraPosition(target: pickup, zoom: 15),
        ),
      );
      return;
    }
    final bounds = LatLngBounds(
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
    );
    try {
      await controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 92));
    } catch (_) {
      await controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: pickup, zoom: 14),
        ),
      );
    }
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
      builder: (sheetContext) => _choiceSheet(
        title: 'Payment method',
        children: List.generate(_payments.length, (index) {
          final method = _payments[index];
          return _sheetChoice(
            image: method.image,
            tintImage: method.tintable,
            title: method.name,
            subtitle: index == 0 ? '\$7.00 available' : 'Pay for this ride',
            selected: _selectedPayment == index,
            onTap: () {
              setState(() => _selectedPayment = index);
              Navigator.pop(sheetContext);
            },
          );
        }),
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
    final height = media.size.height;
    final minPanel = (height * 0.56).clamp(420.0, 560.0).toDouble();
    final maxPanel = (height - media.padding.top - 64)
        .clamp(minPanel + 40, height * 0.90)
        .toDouble();
    return Scaffold(
      backgroundColor: Colors.white,
      body: SlidingUpPanel(
        color: Colors.white,
        minHeight: minPanel,
        maxHeight: maxPanel,
        defaultPanelState: PanelState.OPEN,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 28,
            offset: const Offset(0, -8),
          ),
        ],
        panelBuilder: _panel,
        body: Stack(
          children: [
            Positioned.fill(
              child: CustomGoogleMap(
                initialPosition: _initialPosition,
                markers: _markers,
                myLocationEnabled: false,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                compassEnabled: false,
                trafficEnabled: false,
                buildingsEnabled: true,
                indoorViewEnabled: false,
                mapType: MapType.normal,
                onMapCreated: (controller) {
                  _mapController = controller;
                  Future<void>.delayed(
                    const Duration(milliseconds: 320),
                    _fitRoute,
                  );
                },
                onTap: (_) {},
              ),
            ),
            Positioned(
              top: media.padding.top + 14,
              left: 18,
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
            Positioned(
              top: media.padding.top + 14,
              left: 88,
              right: 18,
              child: _routeChip(),
            ),
          ],
        ),
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

  Widget _panel(ScrollController controller) {
    final selected = _rides[_selectedRide];
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Column(
      children: [
        const SizedBox(height: 10),
        Container(
          width: 42,
          height: 4,
          decoration: BoxDecoration(
            color: const Color(0xFFD8DDE0),
            borderRadius: BorderRadius.circular(20),
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
            controller: controller,
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
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
              Row(
                children: [
                  Expanded(
                    child: _compactAction(
                      icon: Icons.account_balance_wallet_outlined,
                      label: 'Payment',
                      value: _payments[_selectedPayment].name,
                      onTap: _showPaymentPicker,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _compactAction(
                      icon: Icons.schedule_rounded,
                      label: 'Pickup',
                      value: _scheduleLabel,
                      onTap: _showBookingPicker,
                    ),
                  ),
                ],
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
                          destinationPosition: widget.destinationPosition,
                          rideType: selected.name,
                          price: _price,
                          paymentMethod: _payments[_selectedPayment].name,
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
