import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Whether the native Google Maps SDK has an API key (CODE-1).
///
/// iOS gets its key from the `GOOGLE_MAPS_API_KEY` build setting
/// (`ios/Flutter/Secrets.xcconfig` → `GMSApiKey` in Info.plist). The Maps
/// SDK raises when a map is created without one, so AppDelegate reports the
/// key over [channel] and [googleMapsAvailable] shows the no-map fallback
/// instead. Android always has a value (release builds refuse to build
/// without a real key), so only iOS is asked.
abstract final class NativeMapsConfig {
  static const MethodChannel channel = MethodChannel('movera/maps_config');

  static bool _hasKey = true;

  /// False only on iOS when the build has no Maps key (or the native side
  /// could not be asked: fail closed rather than crash on the first map).
  static bool get hasMapsKey => _hasKey;

  /// Reads the native answer once at start-up, before the first map builds.
  static Future<void> load() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) {
      _hasKey = true;
      return;
    }
    try {
      _hasKey = await channel.invokeMethod<bool>('hasGoogleMapsKey') ?? false;
    } catch (_) {
      _hasKey = false;
    }
  }

  @visibleForTesting
  static void debugReset() => _hasKey = true;
}
