from pathlib import Path
import shutil

home_path = Path('lib/features/rider/home/home.dart')
schedule_path = Path('lib/features/rider/schedule ride/schedule_ride.dart')
legacy_dir = Path('lib/features/rider/choose route')

home = home_path.read_text()
schedule = schedule_path.read_text()


def replace_exact(text, old, new, label, expected=1):
    count = text.count(old)
    if count != expected:
        raise SystemExit(f'{label}: expected {expected} match(es), found {count}')
    return text.replace(old, new, expected)


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

# Remove each old ChooseRoute tap by finding the real constructor call and
# replacing its enclosing onTap callback. This is intentionally independent
# of whitespace/formatting from the original ZIP.
needle = 'const ChooseRoute()'
if schedule.count(needle) != 2:
    raise SystemExit(
        f'Schedule legacy route calls: expected 2, found {schedule.count(needle)}'
    )
for _ in range(2):
    idx = schedule.find(needle)
    if idx < 0:
        raise SystemExit('ChooseRoute call disappeared unexpectedly')
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

if needle in schedule:
    raise SystemExit('Legacy ChooseRoute callback still remains')

schedule = replace_exact(
    schedule,
    'icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),',
    'icon: BitmapDescriptor.defaultMarker,',
    'Schedule web-unsafe marker',
)

# Remove the original ZIP's Islamabad fallback from the still-supported
# scheduled ride flow. Keep the same neutral fallback used by Home.
schedule = replace_exact(
    schedule,
    'LatLng(33.6844, 73.0479)',
    'LatLng(59.3293, 18.0686)',
    'Schedule original Islamabad constants',
    expected=2,
)
schedule = schedule.replace('// Islamabad coordinates', '// neutral map fallback')

home_path.write_text(home)
schedule_path.write_text(schedule)

if not legacy_dir.exists():
    raise SystemExit('Legacy choose route directory is already missing; audit expected it to exist')
shutil.rmtree(legacy_dir)

# Prove the old original route cannot be referenced by compiled Dart anymore.
violations = []
for dart in Path('lib').rglob('*.dart'):
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

print('Legacy ChooseRoute/SetOnMap chain removed and all Dart references cleared.')
