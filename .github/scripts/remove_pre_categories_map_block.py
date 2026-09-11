from pathlib import Path

path = Path('lib/features/rider/home/home.dart')
text = path.read_text()

old = """      await _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: destinationPosition, zoom: 15),
        ),
      );
      if (!mounted) return;

      Navigator.of(context).push(
"""
new = """      // Do not await a Home-map camera animation before opening the ride
      // categories. On web the platform-map future can stall/fail and block
      // navigation entirely. SelectRide frames the route on its own map.
      Navigator.of(context).push(
"""

count = text.count(old)
if count != 1:
    raise SystemExit(f'Expected exactly one pre-SelectRide camera block, found {count}')

text = text.replace(old, new, 1)
path.write_text(text)
print('Removed blocking Home map animation before SelectRide navigation.')
