import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:riding_app/constants/appcolors.dart';
import 'package:riding_app/presentation/common/splash/splash.dart';

void main() {
  runApp(const RidingApp());
}

class RidingApp extends StatelessWidget {
  const RidingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      ensureScreenSize: true,
      builder: (_, child) {
        return GetMaterialApp(
          title: 'Riding App',
          debugShowCheckedModeBanner: false,
          theme: ThemeData.light(
            useMaterial3: true,
          ).copyWith(scaffoldBackgroundColor: AppColor.bg),
          home: Splash(),
        );
      },
    );
  }
}
