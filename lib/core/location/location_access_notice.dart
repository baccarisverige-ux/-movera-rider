import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:movera_rider/core/location/location_access_issue.dart';

export 'package:movera_rider/core/location/location_access_issue.dart';

/// Opens a system settings screen; resolves with whether it opened.
typedef LocationSettingsOpener = Future<bool> Function();

/// The system screen that fixes [issue]: app settings for a blocked
/// permission, location settings when Location Services are off. Null for a
/// plain refusal (asking again fixes it) and on the web, where no settings
/// screen can be opened.
LocationSettingsOpener? locationSettingsOpenerFor(
  LocationAccessIssue issue, {
  bool isWeb = kIsWeb,
  LocationSettingsOpener? openAppSettings,
  LocationSettingsOpener? openLocationSettings,
}) {
  if (isWeb) return null;
  return switch (issue) {
    LocationAccessIssue.denied => null,
    LocationAccessIssue.deniedForever =>
      openAppSettings ?? Geolocator.openAppSettings,
    LocationAccessIssue.servicesOff =>
      openLocationSettings ?? Geolocator.openLocationSettings,
  };
}

/// A small card that explains why location is unavailable and offers the
/// way back: "Open settings" when only the system can fix it, otherwise
/// "Allow location" / "Try again" through [onRetry]. Setting the pickup on
/// the map always remains possible, and the copy says so.
class LocationAccessNotice extends StatelessWidget {
  const LocationAccessNotice({
    super.key,
    required this.issue,
    this.onRetry,
    this.onDismiss,
    this.isWeb = kIsWeb,
    this.openAppSettings,
    this.openLocationSettings,
  });

  final LocationAccessIssue issue;

  /// Asks for location again (re-runs the permission request).
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;
  final bool isWeb;

  /// For tests; default to geolocator's settings deep links.
  final LocationSettingsOpener? openAppSettings;
  final LocationSettingsOpener? openLocationSettings;

  static const Color _ink = Color(0xFF1D252C);
  static const Color _muted = Color(0xFF5C656C);

  String get _title => switch (issue) {
    LocationAccessIssue.denied => 'Location access needed',
    LocationAccessIssue.deniedForever => 'Location access is off',
    LocationAccessIssue.servicesOff => 'Location is turned off',
  };

  String get _body {
    if (isWeb) {
      return switch (issue) {
        LocationAccessIssue.denied =>
          'Movera uses your location to set your pickup. Allow it when your '
              'browser asks, or set your pickup on the map.',
        LocationAccessIssue.deniedForever =>
          'Allow location for this site in your browser settings, then try '
              'again. You can also set your pickup on the map.',
        LocationAccessIssue.servicesOff =>
          'Turn on location for this device, then try again. You can also '
              'set your pickup on the map.',
      };
    }
    return switch (issue) {
      LocationAccessIssue.denied =>
        'Movera uses your location to set your pickup and show your driver '
            'where to meet you. You can also set your pickup on the map.',
      LocationAccessIssue.deniedForever =>
        'Allow Movera to use your location in Settings, or set your pickup '
            'on the map.',
      LocationAccessIssue.servicesOff =>
        'Turn on Location Services in Settings, or set your pickup on the '
            'map.',
    };
  }

  @override
  Widget build(BuildContext context) {
    final openSettings = locationSettingsOpenerFor(
      issue,
      isWeb: isWeb,
      openAppSettings: openAppSettings,
      openLocationSettings: openLocationSettings,
    );
    final String actionLabel;
    final VoidCallback? action;
    if (openSettings != null) {
      actionLabel = 'Open settings';
      action = () => openSettings();
    } else {
      actionLabel = issue == LocationAccessIssue.denied
          ? 'Allow location'
          : 'Try again';
      action = onRetry;
    }
    return Semantics(
      container: true,
      liveRegion: true,
      child: Material(
        key: const ValueKey('location-access-notice'),
        color: Colors.white,
        elevation: 6,
        shadowColor: Colors.black26,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 4, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(Icons.location_off_outlined, color: _ink, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _title,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _body,
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        height: 1.35,
                        color: _muted,
                      ),
                    ),
                    if (action != null)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          key: const ValueKey('location-access-action'),
                          onPressed: action,
                          style: TextButton.styleFrom(
                            foregroundColor: _ink,
                            padding: const EdgeInsets.symmetric(horizontal: 0),
                            minimumSize: const Size(48, 44),
                            textStyle: GoogleFonts.poppins(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          child: Text(actionLabel),
                        ),
                      ),
                  ],
                ),
              ),
              if (onDismiss != null)
                IconButton(
                  tooltip: 'Dismiss',
                  onPressed: onDismiss,
                  icon: const Icon(Icons.close_rounded, color: _muted),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
