from pathlib import Path
import re
import shutil

home_path = Path('lib/features/rider/home/home.dart')
schedule_path = Path('lib/features/rider/schedule ride/schedule_ride.dart')
select_path = Path('lib/features/rider/select ride/select_ride.dart')
finding_path = Path('lib/features/rider/Finding Drivers/finding_drivers.dart')
waiting_path = Path('lib/features/rider/waiting for driver/waiting_for_driver.dart')
legacy_dir = Path('lib/features/rider/choose route')

home = home_path.read_text()
schedule = schedule_path.read_text()
select = select_path.read_text()
finding = finding_path.read_text()
waiting = waiting_path.read_text()


def replace_exact(text, old, new, label, expected=1):
    count = text.count(old)
    if count != expected:
        raise SystemExit(f'{label}: expected {expected} match(es), found {count}')
    return text.replace(old, new, expected)


def replace_first(text, old, new, label):
    if old not in text:
        raise SystemExit(f'{label}: anchor not found')
    return text.replace(old, new, 1)


# ---------------------------------------------------------------------------
# 1) Remove the original ChooseRoute -> SetOnMap chain.
# ---------------------------------------------------------------------------
home = replace_exact(
    home,
    "import 'package:movera_rider/features/rider/choose%20route/choose_route.dart';\n",
    '',
    'Home legacy ChooseRoute import',
)

home = replace_exact(
    home,
    "  void _openRoute() {\n    Navigator.push(context, BottomToTopTransition(ChooseRoute()));\n  }\n\n",
    '',
    'Home legacy _openRoute method',
)

schedule = replace_exact(
    schedule,
    "import 'package:movera_rider/features/rider/choose%20route/choose_route.dart';\n",
    '',
    'Schedule legacy ChooseRoute import',
)

schedule = replace_exact(
    schedule,
    "import 'package:movera_rider/shared/widgets/navigation_transition.dart';\n",
    '',
    'Schedule legacy navigation transition import',
)

previous_step = """  void goToPreviousStep() {
    FocusScope.of(context).unfocus();
    if (currentStep == 0) {
      Navigator.pop(context);
      return;
    }
    setState(() => currentStep -= 1);
  }

"""
edit_route = previous_step + """  void _editRoute() {
    FocusScope.of(context).unfocus();
    if (currentStep == 0) return;
    setState(() => currentStep = 0);
  }

"""
schedule = replace_exact(
    schedule,
    previous_step,
    edit_route,
    'Schedule edit-route method anchor',
)

route_pattern = re.compile(r'(?:const\s+)?ChooseRoute\(\)')
route_matches = list(route_pattern.finditer(schedule))
if not route_matches:
    raise SystemExit('No ScheduleRide ChooseRoute call found; expected legacy route to be reachable')

for match in reversed(route_matches):
    idx = match.start()
    start = schedule.rfind('onTap:', 0, idx)
    if start < 0:
        raise SystemExit('Could not locate onTap before ChooseRoute call')
    end = schedule.find('},', idx)
    if end < 0:
        raise SystemExit('Could not locate onTap callback end after ChooseRoute call')
    callback = schedule[start:end + 2]
    if 'Navigator.push' not in callback or 'BottomToTopTransition' not in callback:
        raise SystemExit('ChooseRoute was not inside the expected legacy navigation callback')
    schedule = schedule[:start] + 'onTap: _editRoute,' + schedule[end + 2:]

if route_pattern.search(schedule):
    raise SystemExit('Legacy ChooseRoute callback still remains in ScheduleRide')

schedule = replace_exact(
    schedule,
    'icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),',
    'icon: BitmapDescriptor.defaultMarker,',
    'Schedule web-unsafe marker',
)
schedule = replace_exact(
    schedule,
    'LatLng(33.6844, 73.0479)',
    'LatLng(59.3293, 18.0686)',
    'Schedule original Islamabad constants',
    expected=2,
)
schedule = schedule.replace('// Islamabad coordinates', '// neutral map fallback')

# ---------------------------------------------------------------------------
# 2) Keep the real trip when modern SelectRide opens FindingDrivers.
# ---------------------------------------------------------------------------
select = replace_exact(
    select,
    'BottomToTopTransition(FindingDrivers()),',
    """BottomToTopTransition(
                    FindingDrivers(
                      pickupAddress: widget.pickupAddress,
                      destinationAddress: widget.destinationAddress,
                      pickupPosition: widget.pickupPosition,
                      destinationPosition: widget.destinationPosition,
                      rideType: selected.name,
                      price: _price,
                      paymentMethod: _payments[_selectedPayment].name,
                    ),
                  ),""",
    'SelectRide real trip handoff',
)

finding = replace_exact(
    finding,
    """class FindingDrivers extends StatefulWidget {
  const FindingDrivers({super.key});

  @override
""",
    """class FindingDrivers extends StatefulWidget {
  const FindingDrivers({
    super.key,
    required this.pickupAddress,
    required this.destinationAddress,
    required this.pickupPosition,
    required this.destinationPosition,
    required this.rideType,
    required this.price,
    required this.paymentMethod,
  });

  final String pickupAddress;
  final String destinationAddress;
  final LatLng pickupPosition;
  final LatLng destinationPosition;
  final String rideType;
  final double price;
  final String paymentMethod;

  @override
""",
    'FindingDrivers constructor',
)

finding = replace_exact(
    finding,
    """  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(33.6844, 73.0479), // Islamabad coordinates
    zoom: 14.0,
  );
""",
    """  late final CameraPosition _initialPosition;
""",
    'FindingDrivers Islamabad camera',
)

finding = replace_exact(
    finding,
    """  void initState() {
    super.initState();
    _loadMarkers();
""",
    """  void initState() {
    super.initState();
    _initialPosition = CameraPosition(target: widget.pickupPosition, zoom: 14.0);
    _loadMarkers();
""",
    'FindingDrivers init real position',
)

finding = replace_exact(
    finding,
    """  void _loadMarkers() {
    _markers.add(
      Marker(
        markerId: MarkerId('driver_location'),
        position: LatLng(33.6844, 73.0479),
        infoWindow: InfoWindow(title: 'Your Location'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ),
    );
  }
""",
    """  void _loadMarkers() {
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
""",
    'FindingDrivers real markers',
)

finding = replace_exact(
    finding,
    'Navigator.push(context, BottomToTopTransition(WaitingForDriver()));',
    """Navigator.push(
          context,
          BottomToTopTransition(
            WaitingForDriver(
              pickupAddress: widget.pickupAddress,
              destinationAddress: widget.destinationAddress,
              pickupPosition: widget.pickupPosition,
              destinationPosition: widget.destinationPosition,
              rideType: widget.rideType,
              price: widget.price,
              paymentMethod: widget.paymentMethod,
            ),
          ),
        );""",
    'FindingDrivers -> WaitingForDriver handoff',
)

finding = replace_first(
    finding,
    'text: "1141 central park, Lemonade Homilton",',
    'text: widget.pickupAddress,',
    'FindingDrivers pickup label',
)
finding = replace_first(
    finding,
    'text: "1141 central park, Lemonade Homilton",',
    'text: widget.destinationAddress,',
    'FindingDrivers destination label',
)
finding = replace_exact(
    finding,
    'text: "\\$14.30",',
    "text: '\\$${widget.price.toStringAsFixed(2)}',",
    'FindingDrivers price',
)
finding = replace_exact(
    finding,
    'text: "Cash",',
    'text: widget.paymentMethod,',
    'FindingDrivers payment',
)
finding = replace_exact(
    finding,
    'text: "Eco-friendly",',
    'text: widget.rideType,',
    'FindingDrivers ride type',
)

# ---------------------------------------------------------------------------
# 3) WaitingForDriver must continue the same trip instead of resetting to the
#    original ZIP's Islamabad/demo values.
# ---------------------------------------------------------------------------
waiting = replace_exact(
    waiting,
    """class WaitingForDriver extends StatefulWidget {
  const WaitingForDriver({super.key});

  @override
""",
    """class WaitingForDriver extends StatefulWidget {
  const WaitingForDriver({
    super.key,
    required this.pickupAddress,
    required this.destinationAddress,
    required this.pickupPosition,
    required this.destinationPosition,
    required this.rideType,
    required this.price,
    required this.paymentMethod,
  });

  final String pickupAddress;
  final String destinationAddress;
  final LatLng pickupPosition;
  final LatLng destinationPosition;
  final String rideType;
  final double price;
  final String paymentMethod;

  @override
""",
    'WaitingForDriver constructor',
)

waiting = replace_exact(
    waiting,
    """  // Default location
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(33.6844, 73.0479), // Islamabad coordinates
    zoom: 14.0,
  );
""",
    """  late final CameraPosition _initialPosition;
""",
    'WaitingForDriver Islamabad camera',
)

waiting = replace_exact(
    waiting,
    """  void initState() {
    super.initState();
    _loadMarkers();
  }
""",
    """  void initState() {
    super.initState();
    _initialPosition = CameraPosition(target: widget.pickupPosition, zoom: 14.0);
    _loadMarkers();
  }
""",
    'WaitingForDriver init real position',
)

waiting = replace_exact(
    waiting,
    """  void _loadMarkers() {
    // Add any initial markers if needed
    // Example: driver location marker
    _markers.add(
      Marker(
        markerId: MarkerId('driver_location'),
        position: LatLng(33.6844, 73.0479),
        infoWindow: InfoWindow(title: 'Your Location'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ),
    );
  }
""",
    """  void _loadMarkers() {
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
""",
    'WaitingForDriver real markers',
)

choose_route_comment_count = waiting.count('ChooseRoute()')
if choose_route_comment_count:
    waiting = waiting.replace('ChooseRoute()', 'legacy route removed')

waiting = replace_exact(
    waiting,
    'text: "Sector i11 Street 15, h340",',
    'text: widget.pickupAddress,',
    'WaitingForDriver pickup label',
)
waiting = replace_exact(
    waiting,
    'text: "Skypulse solution",',
    'text: widget.destinationAddress,',
    'WaitingForDriver destination label',
)
waiting = replace_exact(
    waiting,
    'text: "\\$10.12",',
    "text: '\\$${widget.price.toStringAsFixed(2)}',",
    'WaitingForDriver price',
)
waiting = replace_exact(
    waiting,
    'text: "Cash",',
    'text: widget.paymentMethod,',
    'WaitingForDriver payment',
)
waiting = replace_exact(
    waiting,
    'text: "Toyota HR-V",',
    'text: widget.rideType,',
    'WaitingForDriver selected ride label',
)

home_path.write_text(home)
schedule_path.write_text(schedule)
select_path.write_text(select)
finding_path.write_text(finding)
waiting_path.write_text(waiting)

if not legacy_dir.exists():
    raise SystemExit('Legacy choose route directory is already missing; audit expected it to exist')
shutil.rmtree(legacy_dir)

# Final authority: no original ChooseRoute/Islamabad demo route is allowed to
# survive anywhere in compiled Dart source.
violations = []
for dart in Path('lib').rglob('*.dart'):
    if not dart.is_file():
        continue
    text = dart.read_text(errors='ignore')
    if (
        'ChooseRoute' in text
        or 'choose%20route/' in text
        or 'features/rider/choose route/' in text
        or 'Central Park, DHA' in text
        or '33.6844, 73.0479' in text
    ):
        violations.append(str(dart))
if violations:
    raise SystemExit('Legacy route/data references remain: ' + ', '.join(violations))

print(
    f'Removed {len(route_matches)} ScheduleRide legacy route callback(s), '
    f'cleaned {choose_route_comment_count} stale WaitingForDriver reference(s), '
    'deleted ChooseRoute/SetOnMap, and connected the real trip through driver screens.'
)
