from pathlib import Path

path = Path('lib/features/rider/home/home.dart')
source = path.read_text(encoding='utf-8')
marker = 'class _PickupMapPickerPage extends StatefulWidget {'
start = source.find(marker)
if start < 0:
    raise SystemExit('Pickup picker class marker not found')

new_tail = r'''class _PickupMapPickerPage extends StatefulWidget {
  const _PickupMapPickerPage({
    required this.initialPosition,
    required this.initialAddress,
  });

  final LatLng initialPosition;
  final String initialAddress;

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
              myLocationEnabled: true,
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
                padding: EdgeInsets.fromLTRB(
                  20,
                  10,
                  20,
                  panelBottomPadding,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  border: Border(
                    top: BorderSide(color: _line, width: 1),
                  ),
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
                    const Text(
                      'Set exact pickup',
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
                              _resolving ? 'Locating…' : 'Confirm pickup',
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
        Container(
          width: 3,
          height: 19,
          color: const Color(0xFF172027),
        ),
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
'''

source = source[:start] + new_tail
path.write_text(source, encoding='utf-8')
