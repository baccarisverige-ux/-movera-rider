import 'package:flutter/material.dart';
import 'package:movera_rider/l10n/generated/app_localizations.dart';
import 'package:get/get.dart';
import 'package:movera_rider/app/di.dart';
import 'package:movera_rider/app/navigator_key.dart';
import 'package:movera_rider/app/router/home_history_observer.dart';
import 'package:movera_rider/app/screen_scale.dart';
import 'package:movera_rider/app/theme/app_theme.dart';
import 'package:movera_rider/features/auth/presentation/auth_navigation.dart';
import 'package:movera_rider/features/auth/presentation/sign_in.dart';
import 'package:movera_rider/features/ride_booking/presentation/ride_restore_gate.dart';

/// Lets the DI container send the rider to Sign in on session expiry without
/// importing presentation (ARCH-17). Idempotent.
void registerSessionExpiredNavigation() {
  AppScope.showSignInOnSessionExpired ??= () {
    showMoveraRoot(const SignIn());
  };
}

class MoveraApp extends StatelessWidget {
  const MoveraApp({super.key});

  static final _homeHistoryObserver = HomeHistoryObserver();

  @override
  Widget build(BuildContext context) {
    registerSessionExpiredNavigation();
    return MoveraScreenUtilInit(
      builder: (_, child) {
        return GetMaterialApp(
          onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
          navigatorKey: moveraNavigatorKey,
          navigatorObservers: [_homeHistoryObserver],
          locale: const Locale('en'),
          fallbackLocale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          debugShowCheckedModeBanner: false,
          theme: moveraTheme(),
          home: RideRestoreGate(key: RideRestoreGate.gateKey),
        );
      },
    );
  }
}
