import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:movera_rider/app/navigator_key.dart';
import 'package:movera_rider/app/router/home_history_observer.dart';
import 'package:movera_rider/app/theme/app_theme.dart';
import 'package:movera_rider/features/ride_booking/presentation/ride_restore_gate.dart';

class MoveraApp extends StatelessWidget {
  const MoveraApp({super.key});

  static final _homeHistoryObserver = HomeHistoryObserver();

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      ensureScreenSize: true,
      builder: (_, child) {
        return GetMaterialApp(
          title: 'Movera',
          navigatorKey: moveraNavigatorKey,
          navigatorObservers: [_homeHistoryObserver],
          locale: const Locale('en'),
          fallbackLocale: const Locale('en'),
          debugShowCheckedModeBanner: false,
          theme: moveraTheme(),
          home: RideRestoreGate(key: RideRestoreGate.gateKey),
        );
      },
    );
  }
}
