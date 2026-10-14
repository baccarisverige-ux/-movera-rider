import Flutter
import UIKit
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // GMSApiKey comes from the GOOGLE_MAPS_API_KEY build setting
    // (ios/Flutter/Secrets.xcconfig). Without a key the Maps SDK must not be
    // used, so Dart asks over "movera/maps_config" and shows its no-map
    // fallback instead of creating a GoogleMap.
    let mapsAPIKey = (Bundle.main.object(forInfoDictionaryKey: "GMSApiKey") as? String)?
      .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    let hasMapsAPIKey = !mapsAPIKey.isEmpty && !mapsAPIKey.hasPrefix("$(")
    if hasMapsAPIKey {
      GMSServices.provideAPIKey(mapsAPIKey)
    } else {
      NSLog("[movera] GOOGLE_MAPS_API_KEY is not set: maps are disabled in this build.")
    }
    GeneratedPluginRegistrant.register(with: self)
    if let registrar = self.registrar(forPlugin: "MoveraMapsConfig") {
      let channel = FlutterMethodChannel(
        name: "movera/maps_config",
        binaryMessenger: registrar.messenger()
      )
      channel.setMethodCallHandler { call, result in
        if call.method == "hasGoogleMapsKey" {
          result(hasMapsAPIKey)
        } else {
          result(FlutterMethodNotImplemented)
        }
      }
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
