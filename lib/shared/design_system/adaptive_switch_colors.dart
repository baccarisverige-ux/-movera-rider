import 'package:flutter/material.dart';

/// Reproduces the exact per-platform color the now-deprecated
/// `Switch.adaptive`/`SwitchListTile.adaptive` `activeColor` used to apply:
/// the thumb on Android/Fuchsia/Linux/Windows, the track on iOS/macOS.
/// Pass the same [color] to both [adaptiveSwitchThumbColor] and
/// [adaptiveSwitchTrackColor] so together they match the old single-color
/// behavior with no visual change.
Color? adaptiveSwitchThumbColor(BuildContext context, Color color) {
  switch (Theme.of(context).platform) {
    case TargetPlatform.iOS:
    case TargetPlatform.macOS:
      return null;
    case TargetPlatform.android:
    case TargetPlatform.fuchsia:
    case TargetPlatform.linux:
    case TargetPlatform.windows:
      return color;
  }
}

Color? adaptiveSwitchTrackColor(BuildContext context, Color color) {
  switch (Theme.of(context).platform) {
    case TargetPlatform.iOS:
    case TargetPlatform.macOS:
      return color;
    case TargetPlatform.android:
    case TargetPlatform.fuchsia:
    case TargetPlatform.linux:
    case TargetPlatform.windows:
      return null;
  }
}
