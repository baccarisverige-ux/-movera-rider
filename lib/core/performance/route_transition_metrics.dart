import 'package:movera_rider/core/logging/app_log.dart';

/// Low-cardinality latency instrumentation for the Home -> Select Ride path.
///
/// Keep each phase separate so production telemetry can identify whether a
/// regression belongs to address preparation, map teardown, navigation/route
/// settling, or the destination map becoming usable.
abstract final class RouteTransitionMetrics {
  static void routePreparation(Duration elapsed, {required int stopCount}) {
    _record(
      'performance.route_preparation',
      elapsed,
      extra: {'stopCount': stopCount},
    );
  }

  static void homeMapParking(Duration elapsed) {
    _record('performance.home_map_parking', elapsed);
  }

  static void navigationBarrier(Duration elapsed) {
    _record('performance.ride_selection_navigation_barrier', elapsed);
  }

  static void nextMapReady(Duration elapsed) {
    _record('performance.ride_selection_next_map_ready', elapsed);
  }

  static void _record(
    String event,
    Duration elapsed, {
    Map<String, Object?> extra = const {},
  }) {
    AppLog.info(
      event,
      extra: <String, Object?>{
        'durationMs': elapsed.inMicroseconds / 1000,
        ...extra,
      },
    );
  }
}
