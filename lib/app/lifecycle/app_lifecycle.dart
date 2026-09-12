import 'package:flutter/widgets.dart';
import 'package:movera_rider/core/logging/app_log.dart';

class AppLifecycleObserver with WidgetsBindingObserver {
  void attach() => WidgetsBinding.instance.addObserver(this);

  void detach() => WidgetsBinding.instance.removeObserver(this);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    AppLog.info('app.lifecycle', extra: {'state': state.name});
  }
}
