from pathlib import Path

path = Path('lib/features/rider/home/home.dart')
source = path.read_text()
start_token = "  static const String _premiumMapStyle = '''\n"
end_token = "''';\n\n  @override\n  void initState()"
start = source.index(start_token)
end = source.index(end_token, start)

exact_style = '''  static const String _premiumMapStyle = \'\'\'
[
  {
    "elementType": "geometry",
    "stylers": [{"color": "#eef1e8"}]
  },
  {
    "elementType": "labels.icon",
    "stylers": [{"visibility": "off"}]
  },
  {
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#747974"}]
  },
  {
    "elementType": "labels.text.stroke",
    "stylers": [{"color": "#f7f8f3"}, {"weight": 2}]
  },
  {
    "featureType": "administrative",
    "elementType": "geometry.stroke",
    "stylers": [{"color": "#d9dcd4"}]
  },
  {
    "featureType": "landscape",
    "elementType": "geometry",
    "stylers": [{"color": "#d8edb5"}]
  },
  {
    "featureType": "landscape.man_made",
    "elementType": "geometry",
    "stylers": [{"color": "#f2f2ef"}]
  },
  {
    "featureType": "poi",
    "elementType": "geometry",
    "stylers": [{"color": "#c1e589"}]
  },
  {
    "featureType": "poi.park",
    "elementType": "geometry",
    "stylers": [{"color": "#aedb6f"}]
  },
  {
    "featureType": "road",
    "elementType": "geometry",
    "stylers": [{"color": "#ffffff"}]
  },
  {
    "featureType": "road",
    "elementType": "geometry.stroke",
    "stylers": [{"color": "#d9dcd5"}]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry",
    "stylers": [{"color": "#fffdf5"}]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry.stroke",
    "stylers": [{"color": "#d5d9cf"}]
  },
  {
    "featureType": "transit",
    "elementType": "geometry",
    "stylers": [{"color": "#e6e8e3"}]
  },
  {
    "featureType": "water",
    "elementType": "geometry",
    "stylers": [{"color": "#bfe5ef"}]
  },
  {
    "featureType": "water",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#66848a"}]
  }
]
\'\'\';

  @override
  void initState()'''

source = source[:start] + exact_style + source[end + len(end_token):]
path.write_text(source)

# Verify every authoritative groc-movera style token is present.
required = [
    '#eef1e8', '#747974', '#f7f8f3', '#d9dcd4', '#d8edb5',
    '#f2f2ef', '#c1e589', '#aedb6f', '#ffffff', '#d9dcd5',
    '#fffdf5', '#d5d9cf', '#e6e8e3', '#bfe5ef', '#66848a',
    'labels.icon', 'visibility\": \"off',
]
updated = path.read_text()
missing = [token for token in required if token not in updated]
if missing:
    raise SystemExit(f'Missing authoritative groc style tokens: {missing}')
print('Exact groc-movera Google map style applied to Rider home map.')
