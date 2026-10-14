import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// UI-15: the Poppins files the app needs (weights 300 to 900, no italics).
///
/// google_fonts already prefers a bundled file over a download. Put these
/// files (from fonts.google.com, OFL) in `assets/google_fonts/` and
/// [configureBundledFonts] also switches runtime fetching off, so a first or
/// offline start draws Poppins straight away and never calls
/// fonts.gstatic.com.
const List<String> bundledPoppinsFiles = [
  'Poppins-Light.ttf',
  'Poppins-Regular.ttf',
  'Poppins-Medium.ttf',
  'Poppins-SemiBold.ttf',
  'Poppins-Bold.ttf',
  'Poppins-ExtraBold.ttf',
  'Poppins-Black.ttf',
];

/// Turns runtime font fetching off when every file in [bundledPoppinsFiles]
/// is in the asset bundle. Returns whether it did. With any file missing it
/// leaves fetching on, so a partial bundle never shows a fallback font.
Future<bool> configureBundledFonts({AssetBundle? bundle}) async {
  final Set<String> assets;
  try {
    final manifest = await AssetManifest.loadFromAssetBundle(
      bundle ?? rootBundle,
    );
    assets = manifest.listAssets().map((path) => path.split('/').last).toSet();
  } on Object {
    // No manifest (some test hosts): keep the package default.
    return false;
  }
  final bundled = bundledPoppinsFiles.every(assets.contains);
  if (bundled) GoogleFonts.config.allowRuntimeFetching = false;
  return bundled;
}
