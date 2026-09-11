from pathlib import Path

home_path = Path('lib/features/rider/home/home.dart')
home = home_path.read_text()


def replace_exact(text, old, new, label, expected=1):
    count = text.count(old)
    if count != expected:
        raise SystemExit(f'{label}: expected {expected}, found {count}')
    return text.replace(old, new, expected)

# Use a plain native Material route for SelectRide. This removes the old
# SizeTransition layer from the critical categories navigation path.
old_saved = """    Navigator.push(
      context,
      BottomToTopTransition(
        SelectRide(
          pickupAddress: _pickupAddress ?? 'Current location',
          destinationAddress: resolvedDestination,
          pickupPosition: pickupPosition,
          destinationPosition: destinationPosition,
          stops: List<String>.from(_routeStops),
        ),
      ),
    );
"""
new_saved = """    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SelectRide(
          pickupAddress: _pickupAddress ?? 'Current location',
          destinationAddress: resolvedDestination,
          pickupPosition: confirmedPickupPosition,
          destinationPosition: confirmedDestinationPosition,
          stops: List<String>.from(_routeStops),
        ),
      ),
    );
"""
home = replace_exact(home, old_saved, new_saved, 'saved-place SelectRide route')

old_main = """      Navigator.push(
        context,
        BottomToTopTransition(
          SelectRide(
            pickupAddress: pickup.isNotEmpty
                ? pickup
                : (_pickupAddress ?? 'Current location'),
            destinationAddress: destination,
            pickupPosition: pickupPosition,
            destinationPosition: destinationPosition,
            stops: List<String>.from(stops),
          ),
        ),
      );
"""
new_main = """      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => SelectRide(
            pickupAddress: pickup.isNotEmpty
                ? pickup
                : (_pickupAddress ?? 'Current location'),
            destinationAddress: destination,
            pickupPosition: pickupPosition,
            destinationPosition: destinationPosition,
            stops: List<String>.from(stops),
          ),
        ),
      );
"""
home = replace_exact(home, old_main, new_main, 'main SelectRide route')

# Saved-place shortcuts previously died silently when GPS was unavailable.
old_pickup_guard = """    final pickupPosition = _tripPickupLatLng ?? _currentLatLng;
    if (pickupPosition == null || !mounted) return;
    var resolvedDestination = destination;
"""
new_pickup_guard = """    var pickupPosition = _tripPickupLatLng ?? _currentLatLng;
    if (pickupPosition == null) {
      final pickupResult = await _openPickupMapPicker(
        _pickupAddress ?? 'Current location',
      );
      if (pickupResult == null || !mounted) return;
      pickupPosition = pickupResult.position;
      setState(() {
        _pickupAddress = pickupResult.address;
        _tripPickupLatLng = pickupResult.position;
      });
    }
    if (!mounted) return;
    final confirmedPickupPosition = pickupPosition;
    var resolvedDestination = destination;
"""
home = replace_exact(home, old_pickup_guard, new_pickup_guard, 'saved-place pickup guard')

old_destination_lock = """    }
    if (!mounted) return;
    Navigator.of(context).push(
"""
new_destination_lock = """    }
    final confirmedDestinationPosition = destinationPosition;
    if (confirmedDestinationPosition == null || !mounted) return;
    Navigator.of(context).push(
"""
home = replace_exact(
    home,
    old_destination_lock,
    new_destination_lock,
    'saved-place destination lock',
)

# Main planner should never silently swallow an impossible coordinate state.
old_draft_guard = """      if (pickupPosition == null || destinationPosition == null || !mounted) {
        return;
      }
"""
new_draft_guard = """      if (pickupPosition == null || destinationPosition == null || !mounted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please confirm pickup and destination on the map.'),
            ),
          );
        }
        return;
      }
"""
home = replace_exact(home, old_draft_guard, new_draft_guard, 'planner coordinate guard')

home_path.write_text(home)
print('Categories navigation now uses MaterialPageRoute and cannot silently fail on missing saved pickup GPS.')
