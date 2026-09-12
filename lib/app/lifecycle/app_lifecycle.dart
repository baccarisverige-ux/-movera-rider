import 'package:flutter/widgets.dart';
import 'package:movera_rider/core/logging/app_log.dart';
import 'package:movera_rider/features/ride_booking/application/ride_restore_coordinator.dart';
import 'package:movera_rider/features/ride_booking/data/ride_snapshot_store.dart';

class AppLifecycleObserver with WidgetsBindingObserver {
  void attach() => WidgetsBinding.instance.addObserver(this);

  void detach() => WidgetsBinding.instance.removeObserver(this);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    AppLog.info('app.lifecycle', extra: {'state': state.name});
    if (state == AppLifecycleState.resumed) {
      RideSnapshotStore.read().then((snapshot) {
        AppLog.info(
          'app.resume.refresh',
          extra: {'ride': snapshot?.status.name ?? 'none'},
        );
      });
      RideRestoreCoordinator.instance.resumeIfNeeded();
    }
  }
}
