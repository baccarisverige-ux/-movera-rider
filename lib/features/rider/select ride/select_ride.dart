import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:movera_rider/core/constants/appassets.dart';
import 'package:movera_rider/core/constants/appcolors.dart';
import 'package:movera_rider/features/rider/Finding%20Drivers/finding_drivers.dart';
import 'package:movera_rider/shared/widgets/custom_google_map.dart';
import 'package:movera_rider/shared/widgets/navigation_transition.dart';
import 'package:movera_rider/shared/widgets/responsive_size.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

class SelectRide extends StatefulWidget {
  const SelectRide({super.key});

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
  });

  final String image;
  final String name;
  final String note;
  final String arrival;
  final double price;
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
      note: 'Affordable everyday ride',
      arrival: '2 min',
      price: 5.00,
    ),
    _RideOption(
      image: AppAssets.ecoFriendly,
      name: 'Eco-Friendly',
      note: 'Lower-emission ride',
      arrival: '3 min',
      price: 7.50,
    ),
    _RideOption(
      image: AppAssets.xl,
      name: 'XL',
      note: 'More room for people and bags',
      arrival: '5 min',
      price: 17.00,
    ),
    _RideOption(
      image: AppAssets.luxury,
      name: 'Luxury',
      note: 'Premium car and comfort',
      arrival: '4 min',
      price: 27.00,
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
  final Set<Marker> _markers = {
    Marker(
      markerId: const MarkerId('driver_location'),
      position: const LatLng(33.6844, 73.0479),
      infoWindow: const InfoWindow(title: 'Pickup'),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
    ),
  };

  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(33.6844, 73.0479),
    zoom: 14,
  );

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
      _price = double.parse((_price - 0.50).clamp(minimum, 9999).toStringAsFixed(2));
    });
  }

  String get _scheduleLabel {
    final value = _scheduledFor;
    if (value == null) return 'Book now';
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return 'Later · ${value.day}/${value.month} at $hour:$minute';
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

  Widget _choiceSheet({
    required String title,
    required List<Widget> children,
  }) {
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
        minHeight: 68,
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
    final height = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SlidingUpPanel(
        color: Colors.white,
        minHeight: ResSize.h * 430,
        maxHeight: height * 0.84,
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
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                compassEnabled: false,
                trafficEnabled: false,
                buildingsEnabled: true,
                indoorViewEnabled: false,
                mapType: MapType.normal,
                onMapCreated: (controller) => _mapController = controller,
                onTap: (_) {},
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 14,
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
                    child: Icon(Icons.arrow_back_rounded, color: _ink, size: 28),
                  ),
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 18,
              left: 88,
              right: 18,
              child: Container(
                height: 46,
                padding: const EdgeInsets.symmetric(horizontal: 14),
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
                child: const Row(
                  children: [
                    Icon(Icons.route_rounded, color: _accent, size: 21),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Pickup  →  Destination',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _ink,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _panel(ScrollController controller) {
    final selected = _rides[_selectedRide];
    return SingleChildScrollView(
      controller: controller,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          const SizedBox(height: 15),
          const Text(
            'Choose your ride',
            style: TextStyle(
              color: _ink,
              fontSize: 25,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: 3),
          const Text(
            'Pick the comfort and space that suits you.',
            style: TextStyle(
              color: _muted,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(_rides.length, (index) => _rideTile(index)),
          const SizedBox(height: 14),
          const Text(
            'Your fare',
            style: TextStyle(
              color: _ink,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 70,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                _priceButton(Icons.remove_rounded, _decreasePrice),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '\$${_price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: _ink,
                          fontSize: 23,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const Text(
                        'Adjust your offer',
                        style: TextStyle(
                          color: _muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                _priceButton(Icons.add_rounded, _increasePrice),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _actionRow(
            icon: Icons.account_balance_wallet_outlined,
            label: 'Payment',
            value: _payments[_selectedPayment].name,
            onTap: _showPaymentPicker,
          ),
          const SizedBox(height: 9),
          _actionRow(
            icon: Icons.calendar_month_outlined,
            label: 'Pickup time',
            value: _scheduleLabel,
            onTap: _showBookingPicker,
          ),
          const SizedBox(height: 16),
          Material(
            color: _ink,
            borderRadius: BorderRadius.circular(17),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  BottomToTopTransition(FindingDrivers()),
                );
              },
              borderRadius: BorderRadius.circular(17),
              child: SizedBox(
                width: double.infinity,
                height: 60,
                child: Center(
                  child: Text(
                    _scheduledFor == null
                        ? 'Book ${selected.name}'
                        : 'Schedule ${selected.name}',
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
        ],
      ),
    );
  }

  Widget _rideTile(int index) {
    final ride = _rides[index];
    final selected = index == _selectedRide;
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Material(
        color: selected ? _accentSoft : Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: () => _selectRide(index),
          borderRadius: BorderRadius.circular(18),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            height: 88,
            padding: const EdgeInsets.fromLTRB(10, 9, 14, 9),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected ? _accent : _line,
                width: selected ? 1.6 : 1,
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 92,
                  child: Image.asset(
                    ride.image,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  ),
                ),
                const SizedBox(width: 9),
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
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.person_outline_rounded,
                            color: _muted,
                            size: 16,
                          ),
                          const Text(
                            '4',
                            style: TextStyle(
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
                    fontSize: 16,
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
          width: 44,
          height: 44,
          child: Icon(icon, color: _ink, size: 23),
        ),
      ),
    );
  }

  Widget _actionRow({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Container(
          minHeight: 66,
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: _line),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: _ink, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: _muted, size: 25),
            ],
          ),
        ),
      ),
    );
  }
}
