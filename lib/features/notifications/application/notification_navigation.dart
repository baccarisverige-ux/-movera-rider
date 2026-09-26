import 'package:flutter/widgets.dart';
import 'package:movera_rider/app/di.dart';
import 'package:movera_rider/app/navigator_key.dart';
import 'package:movera_rider/features/ride_booking/application/ride_restore_coordinator.dart';
import 'package:movera_rider/features/ride_booking/data/ride_snapshot_store.dart';

typedef NotificationRideOpener = Future<bool> Function(String rideId);

Future<bool> openRideFromNotification(String rideId) async {
  final expected = rideId.trim();
  if (expected.isEmpty) return false;

  await AppScope.instance.rideRealtime.reconnectAndResync(expected);

  final snapshot = await RideSnapshotStore.read();
  if (snapshot == null || snapshot.rideId?.trim() != expected) {
    return false;
  }

  final surface = RideRestoreCoordinator.instance.surfaceFor(snapshot);
  if (surface == RestoredSurface.home) return false;

  final nav = moveraNavigatorKey.currentState;
  if (nav != null && nav.canPop()) {
    nav.popUntil((route) => route.isFirst);
    await WidgetsBinding.instance.endOfFrame;
  }

  await RideRestoreCoordinator.instance.resumeIfNeeded();
  return true;
}

String? notificationRideTarget({
  String? rideId,
  String? deepLink,
}) {
  final direct = rideId?.trim();
  if (direct?.isNotEmpty == true) return direct;

  final link = deepLink?.trim();
  if (link == null || link.isEmpty) return null;
  final uri = Uri.tryParse(link);
  if (uri == null || uri.scheme != 'movera' || uri.host != 'ride') {
    return null;
  }
  if (uri.pathSegments.length != 1) return null;
  final id = uri.pathSegments.single.trim();
  return id.isEmpty ? null : id;
}
