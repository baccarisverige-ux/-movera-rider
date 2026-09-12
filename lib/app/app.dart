import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:movera_rider/app/theme/app_theme.dart';
import 'package:movera_rider/features/home/presentation/home.dart';

class MoveraApp extends StatelessWidget {
  const MoveraApp({super.key});

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
          locale: const Locale('en'),
          fallbackLocale: const Locale('en'),
          debugShowCheckedModeBanner: false,
          theme: moveraTheme(),
          home: const Home(),
        );
      },
    );
  }
}
