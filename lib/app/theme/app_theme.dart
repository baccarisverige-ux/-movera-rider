import 'package:flutter/material.dart';
import 'package:movera_rider/core/constants/appcolors.dart';

/// Approved Movera theme. Do not restyle screens from here.
ThemeData moveraTheme() {
  return ThemeData.light(useMaterial3: true).copyWith(
    scaffoldBackgroundColor: AppColor.bg,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColor.primary,
      primary: AppColor.primary,
      surface: AppColor.bg,
    ),
  );
}
